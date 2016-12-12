	NAME 	ROBOUI

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;				 HELPER FUNCTIONS FOR MOTORS UNIT: EVENT HANDLING            ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; These functions are the UI event handlers for the motor unit. They handle 
; events dequeued from the event queue, when they are ready to handle. Possible 
; events include errors, serial characters reception, and sending serial characters 
; for display on the remote unit LED display. After an event is dequeued, the 
; HandleMotorEvents function looks up the corresponding action and executes it. 
; For this outline, the functions included are: 
; Public functions: 
; 	QueueEventHandler - event handler to take care of events dequeued from eventQueue
; Local functions: 
; 	HandleSerialCharEvent - handles serial characters received by motor unit and 
; 					passes them to the parser to execute commands. 
; 	HandleErrorEvent - sends parse and serial errors to remote unit to display
;	MakeString - concatenates passed in values to a stringInProgress variable
; 	DoNOP - do no operation (placeholder function in key command table) 
;
; Serial String Update functions: 
;   SendSerialUpdatedDirection
;   SendSerialUpdatedTurretElevation
;   SendSerialUpdatedSpeed

;
; Input:            Serial input from remote unit.
; Output:           Motor movement and laser light output. 
;
; User Interface: 	Keys pressed by the user are registered as key press events, and 
; 					are handled by sending the key value through the serial port to 
; 					the motor board. If sent strings are valid commands, then the 
; 					motors and laser that make up the output hardware will operate 
; 					according to these commands. 
; 		
; Algorithms:       None.
; Data Structures:  Tables used to link key event values to command strings and display
; 					strings.
;
; Limitations: 		Assumes the ASCII character set. 
; Known Bugs:       None.
;
; Revision History:
;    11/29/2016         Jennifer Du     initial revision
; 	 12/07/2016 		Jennifer Du 	writing assembly code 


$INCLUDE(common.inc)			; commonly used constants
$INCLUDE(uievents.inc)			; event values and UI constants 
$INCLUDE(macros.inc)			; commonly used macros 
$INCLUDE(display.inc)			; constants used to control LED display
$INCLUDE(serial.inc)			; gives access to serial-controlling constants 


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP

; external function declarations
    EXTRN 	ParseSerialChar:NEAR 	; used to parse serial character commands 
	EXTRN   SerialPutString:NEAR	; used to send a string through serial channel
	
    EXTRN   EnqueueEvent:NEAR       ; enqueue events to event queue 
    
    ; creating and sending status string to remote board: 
	EXTRN   GetMotorSpeed:NEAR
    EXTRN   GetMotorDirection:NEAR
    EXTRN   GetTurretElevation:NEAR 
    EXTRN   Hex2String:NEAR 
    EXTRN   Dec2String:NEAR
;
; QueueEventHandler 
;
;
; Description:  	This function handles events from the event queue when they 
; 					are passed to it through AX. The events that will be handled 
; 					will be errors and serial events. 
;
; Operation:    	We have set it up so error values have 00 in AH, and serial 
; 					character events are identified by the value 04 in AH. AH 
; 					holds the type of event, and AL holds the value. 
; 
; 					Based on the value in AH, we can tell what type of event has 
; 					been dequeued, and call the appropriate handler using table 
; 					lookup.
;
; Arguments:        AX - event value and type to be handled. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: None.
; Global Variables:	None.
; 
; Input:            None.
; Output:           None.
;
; Algorithms: 		None. 
; Data Structures:  Event Type Table.
; 
; Error Handling: 	None.
; Registers Used: 	AX, BX.
; Stack Depth: 		0 words. 

QueueEventHandler	 	PROC 	NEAR 
                        PUBLIC  QueueEventHandler
    PUSHA
    PUSHF
    CLI						
InitQueueEventHandler: 
	CMP 	AX, NO_EVENT_VAL			; see if the value that DequeueEvent 
										; returned is the no event constant 
	JE 		EndQueueEventHandler		; if the value dequeued corresponds 
										; to a no-event event, then we end handler
										; without executing anything
	;JNE 	HandleSpecificEvent			; if value dequeued is a legitimate event, 
										; move on to identify the event

HandleSpecificEvent: 
	%CLR(BX)							; clear register holding lookup index
	MOV 	BL, AH						; move event type value into index (we 
										; have pre-set the event type values so 
										; they correspond to index in this table)
	CALL 	CS:EVENT_TYPE_TABLE[BX]		; call appropriate function 
	;JMP 	EndQueueEventHandler		; then end function
		
EndQueueEventHandler: 	
    POPF
    POPA
	RET 
QueueEventHandler 		ENDP 




;
; HandleErrorEvent 
;
;
; Description:  	This function handles error events from the event queue, passed
; 					through AX. The error event identifier value is passed in AH and
; 					the value of the error will be passed through AL. This function 
; 					will send the error message to the display. These numbers 
; 					correspond to errors that have occurred during serial transmission
; 					routines.
;
; 					Error codes can be identified using the table found in the 
; 					Robotrike's functional specification. 
;
; Operation:    	The error value number passed in AL corresponds to the index in 
; 					the error message table. We look up the appropriate error message
; 					and send it to the remote unit for display on the LED display through 
; 					the serial channel. 
;
; Arguments:        AX - error value is stored in AL. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: errorFlag (r) - holds status of errors.
;                   errorString (w) - string to which error message is written to
;                   errorStringLength(r/w) - length of growing error string 
; Global Variables:	None.
; 
; Input:            None.
; Output:           Error message sent through serial channel.
;
; Algorithms: 		None. 
; Data Structures:  Error message table.
;
; Error Handling: 	None.
; Registers Used: 	AX, BX. 
; Stack Depth: 		2 words.
;
HandleErrorEvent		PROC 	NEAR 

    PUSHA                           ; push registers and flags and clear IF 
    PUSHF
    CLI 
	
    CMP     errorFlag, TRUE         ; check if error already in progress
    JE      EndHandleErrorEvent     ; if so, don't handle another one on top of 
                                    ; that, and then just jump to the end 
    ;JNE    LookupErrorString       ; if error not in progress, look up error 
                                    ; string and do the steps 
    
LookupErrorString:    
    
	%CLR(AH)					; clear AH; we would like to use error value as index
	MOV 	BX, AX 				; move error value into index 
	SHL     BX, 1               ; offsets take up a word of space, so multiply index
                                ; by 2 to get appropriate entry in the table of 
                                ; word-sized entries    
	 MOV 	CX, 0                           ; intialize counter for error string creation
     MOV     errorStringLength, 0           ; initialize 
StartMakingErrorString: 
	
	MOV 	SI, CS:ERROR_STRING_TABLE[BX]	; load SI with the header label 
	ADD 	SI, CX 							; then add index to get to current char  
	MOV 	AL, BYTE PTR CS:[SI]			; move character at that address into AL 
	CALL 	MakeErrorString 				; to call MakeString with 
	INC 	CX 								; then we increment the register holding 
                                            ; current position in the label string 
	
	CMP 	AL, ASCII_NULL 					; see if reached end of label string 
	JNE 	StartMakingErrorString			; if not, keep going 
    
	; if equal, start to parse number       ; if at end of string 		
AddFinalNullChar: 
    CALL    MakeErrorString                 ; add ASCII_NULL to end 
	
OutputErrorString: 											
	LEA 	SI, errorString 			    ; then load SI with string to be output 
    PUSH    DS 
    POP     ES 
	CALL 	SerialPutString 				; then put string through serial channel 

EndHandleErrorEvent: 	
    POPF
    POPA                ; pop flags and registers and end. 
    RET 
HandleErrorEvent		ENDP 


;
; GetErrorFlag 
;
;
; Description:  	This function returns the value of the error flag, set or 
;                   reset. The error flag is set if a serial or parsing error 
;                   occurred.
;
; Operation:    	Move errorFlag value into AX and retun.
;
; Arguments:        AX - error flag value 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: errorFlag (r) - holds status of errors.
; Global Variables:	None.
; 
; Input:            None.
; Output:           None.
;
; Algorithms: 		None. 
; Data Structures:  None.
;
GetErrorFlag        PROC    NEAR 
                    PUBLIC  GetErrorFlag
    MOV     AX, errorFlag
    RET 
GetErrorFlag        ENDP


;
; ResetErrorFlag 
;
;
; Description:  	This function resets the value of the error flag. The error 
;                   flag is set if a serial or parsing error occurred and can be 
;                   manually reset, like now. 
;
; Operation:    	Move FALSE value into errorFlag.
;
; Arguments:        None.
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: errorFlag (w) - holds status of errors.
; Global Variables:	None.
; 
; Input:            None.
; Output:           None.
;
; Algorithms: 		None. 
; Data Structures:  None.
;
ResetErrorFlag        PROC    NEAR 
                    PUBLIC  ResetErrorFlag
    MOV     errorFlag, FALSE
    RET 
ResetErrorFlag        ENDP




; 
; 
; Event Type Table 
; 
; Description: 	This table lets us look up what event type has occurred, based on
; 				the event code. A CALL table for handling error events, key press
; 				events, and serial character events. 
EVENT_TYPE_TABLE 		LABEL 	WORD		
	
	DW 		HandleErrorEvent                ; AH = 00
											; called to send error message 
	DW 		DoNOP                           ; AH = 02
											; in remote board, this entry in the 
                                            ; event table is for handling key presses
                                            ; but now we don't have that, so any 
                                            ; accidental values are mistakes. we 
                                            ; will do nothing.
	DW 		HandleSerialCharEvent           ; AH = 04	
											; called to parse serial characters
	 

	


;
;
; Error Message String Table 
; 
; Description: 	This table holds error message strings, stored as offsets of labels.
; 				Each label holds a different error message, and the strings at each 
; 				location are defined in the error labels under the string table.
; 				

ERROR_STRING_TABLE 		LABEL 		WORD 
    DW OFFSET(ERROR0)
	DW OFFSET(ERROR1)			
	DW OFFSET(ERROR2)
	DW OFFSET(ERROR3)
	DW OFFSET(ERROR4)
	DW OFFSET(ERROR5)
	DW OFFSET(ERROR6)
	DW OFFSET(ERROR7)
	DW OFFSET(ERROR8)
	DW OFFSET(ERROR9)
    DW OFFSET(ERROR10)
	DW OFFSET(ERROR11)
	DW OFFSET(ERROR12)
	DW OFFSET(ERROR13)
    DW OFFSET(ERROR14)
	DW OFFSET(ERROR15)
	DW OFFSET(ERROR16)


;
;
; The following labels store the values of the strings referenced in the error 
; string table defined above. 
;
ERROR0 	LABEL 	BYTE 
	DB 	'Error: T',ASCII_NULL
ERROR1 	LABEL 	BYTE 
	DB 	'Error: O',ASCII_NULL
ERROR2 	LABEL 	BYTE 
	DB 	'Error: P',ASCII_NULL
ERROR3 	LABEL 	BYTE 
	DB 	'Error: PO',ASCII_NULL
ERROR4 	LABEL 	BYTE 
	DB 	'Error: F',ASCII_NULL
ERROR5 	LABEL 	BYTE 
	DB 	'Error: FO',ASCII_NULL
ERROR6 	LABEL 	BYTE 
	DB 	'Error: FP',ASCII_NULL
ERROR7 	LABEL 	BYTE 
	DB 	'Error: FPO',ASCII_NULL
ERROR8 	LABEL 	BYTE 
	DB 	'Error: B',ASCII_NULL	
ERROR9 	LABEL 	BYTE 
	DB 	'Error: BO',ASCII_NULL
ERROR10 	LABEL 	BYTE 
	DB 	'Error: BP',ASCII_NULL
ERROR11 	LABEL 	BYTE 
	DB 	'Error: BPO',ASCII_NULL
ERROR12 	LABEL 	BYTE 
	DB 	'Error: BF',ASCII_NULL
ERROR13 	LABEL 	BYTE 
	DB 	'Error: BFO',ASCII_NULL
ERROR14 	LABEL 	BYTE 
	DB 	'Error: BFP',ASCII_NULL
ERROR15 	LABEL 	BYTE 
	DB 	'Error: BBFPO',ASCII_NULL
ERROR16 	LABEL 	BYTE 
	DB 	'Error: parse',ASCII_NULL

;
; MakeErrorString 
;
;
; Description:  	This function takes in the ASCII value of a character passed in  
; 					by AL. It concatenates the ASCII character to the end of the string.
; 					
;
; Operation:    	This is a helper function for making error strings. It 
;                   concatenates letters from a string to the end of the string 
;                   stored in errorString.
;
; Arguments:        AL - ASCII value of character you wish to tack onto end of string
; Return Value:     None. 
;
; Local Variables:  None. 
; Shared Variables: errorString (w) - string to which error message is written to
;                   errorStringLength(r/w) - length of growing error string 
; Global Variables:	None.
; 
; Input:            None.
; Output:           None. 
;
; Error Handling:   None.
; Registers Used:   AL.
; Algorithms: 		None. 
; Data Structures:  None.
;

MakeErrorString		PROC	NEAR
				PUBLIC 	MakeErrorString 
				
	LEA 	SI, errorString             ; load address of string to write to 
	ADD 	SI, errorStringLength       ; add length to reach the end of string 
	MOV 	BYTE PTR [SI], AL           ; put arg character onto end of string 
	INC 	errorStringLength           ; update length of error string 

EndMakeErrorString:
	RET 
MakeErrorString		ENDP


;
; HandleSerialCharEvent 
;
;
; Description:  	This function is called when a serial event is enqueued to 
; 					the event queue, or received from the remote unit board. 
;					This happens when the remote board is trying to send a command
; 					to the motor board to execute. 
; 
; 					When this function is called, the enqueued value will be 
; 					sent as an argument into the ParseSerialChar function that 
; 					is the entry point for serial characters into the finite state 
; 					parsing machine. 
;
; Operation:    	First, we send the character value into the ParseSerialChar to 
; 					parse it. Every subsequent character is handled in the same way. 
; 					We do not need to handle carriage returns and other special
; 					characters separately from the regular characters, since the 
; 					parsing finite state machine will take care of that. 
; 
; 					After ParseSerialChar returns a value, we will check this value 
; 					to determine whether a parsing error occurred or not. If the 
; 					return value is nonzero, an error occurred, and we will enqueue 
; 					an error event to the event queue. If the return value is 0, then 
; 					no error occurred. 
; 
; Arguments:        AX - serial event value to be handled.
; Return Value:     None. 
;
; Local Variables:  None. 
; Shared Variables: None.
; Global Variables:	None.
; 
; Input:            Serial character is input. 
; Output:           
;
; Algorithms: 		None. 
; Data Structures:  None. 
;
; Error Handling: 	None.
; Registers Used: 	None.
;
HandleSerialCharEvent		PROC 	NEAR 

	PUSHA 
	
SendCharacterToParser: 

	CALL 	ParseSerialChar             ; arg is in AL, so call ParseSerialChar 
                                        ; to begin parsing	
CheckForParseError: 
	CMP 	AX, 0                       
	JE 		NoParseErrorOccurred        ; if no parse error, we end.
	JNE 	EnqueueParseError           ; if error occurred, enqueue error 
	
EnqueueParseError: 
	MOV 	AH, ERROR_VAL 
	MOV 	AL, PARSE_ERROR_VAL 	
	CALL 	EnqueueEvent                 ; enqueue parse error to event queue
	JMP 	EndHandleSerialCharEvent 
	
NoParseErrorOccurred: 
	JMP 	EndHandleSerialCharEvent     ; if no error, just end function
	
EndHandleSerialCharEvent: 
	POPA 						          ; end function
	RET 
HandleSerialCharEvent 		ENDP 






;
; MakeString 
;
;
; Description:  	This function takes in the ASCII value of a character passed in  
; 					by AL. It concatenates the ASCII character to the end of the string.
; 					
;
; Operation:    	This is a helper function for the status making functions. It 
;                   concatenates letters from a string to the end of the string 
;                   stored in stringInProgress.
;
; Arguments:        AL - ASCII value of character you wish to tack onto end of string
; Return Value:     None. 
;
; Local Variables:  None. 
; Shared Variables: stringInProgress - array that holds string currently being written
;								max length is 128 characters. 
;                   stringInProgressLength - length of growing status string.
; Global Variables:	None.
; 
; Input:            None.
; Output:           None. 
;
; Error Handling:   None.
; Registers Used:   AL.
; Algorithms: 		None. 
; Data Structures:  None.
;

MakeString		PROC	NEAR
				PUBLIC 	MakeString 
				
	LEA 	SI, stringInProgress            ; load address to write to 
	ADD 	SI, stringInProgressLength      ; get to end of string
	MOV 	BYTE PTR [SI], AL               ; put character into the spot at the end
	INC 	stringInProgressLength          ; update length

EndMakeString:
	RET 
MakeString		ENDP


;	
; SendSerialUpdatedSpeed 
;
; Description: 		This function is called when the speed is output to the motors. 
;                   It creates an update string with the new speed. This string is 
;                   sent through the serial channel to be displayed by the LED display. 
; 
; Operation: 		To output a string with the updated speed, we concatenate
;                   a label with our speed as a string (converted using 
;                   Hex2String). Then we send this string to SerialPutString so 
;                   it can be transmitted through the serial channel.
;
; Arguments:		None.
; Return Value:		None.
;
; Local Variables:	None.
; Shared Variables: stringInProgress (w) - status string we are currently writing.
;                   stringInProgressLength(w/r) - length of status string so far 
; Global Variables: None.

; Input:			None. 
; Output:			String sent through serial.
;
; Error Handling:	None.
; Algorithms:		None. 
; Data Structures: 	None. 
;

	
SendSerialUpdatedSpeed 	PROC 	NEAR 							
                        PUBLIC  SendSerialUpdatedSpeed 
	MOV 	BX, 0 
    MOV     stringInProgressLength, 0 
StartSendSerialUpdatedSpeed: 
	
	LEA 	SI, Updated_Speed_Header		; load SI with the header label 
	ADD 	SI, BX 							; then add the index to get to current 
                                            ; char being added 
	MOV 	AL, BYTE PTR CS:[SI]		    ; then move the character at that address 
                                            ; into AL 
	CALL 	MakeString 						; to call MakeString with 
	INC 	BX 								; then we increment the register holding 
                                            ; current position in the label string 
	
	CMP 	AL, ASCII_NULL 					; see if we've reached the end of label string 
	JNE 	StartSendSerialUpdatedSpeed			; if not, keep going 
	; if equal, start to parse number 		; but if we have reached end of label string, then 
		
	CALL 	GetMotorSpeed 					; we get the motor speed here into AX 
	LEA 	SI, stringInProgress			; load up string address to concatenate to 
	ADD 	SI, stringInProgressLength 		; get to the location of the end character 
	
    DEC     SI 
    
	CALL  	Hex2String 						; add on the hexadecimal representation of speed, 
											; will be null-terminated 
OutputSpeedSerialString: 											
	LEA 	SI, stringInProgress 			; then load SI with string to be output 
    PUSH    DS 
    POP     ES 
	CALL 	SerialPutString 				; then put string through serial channel 

	RET 
SendSerialUpdatedSpeed	ENDP 

;	
; SendSerialUpdatedDirection 
;
; Description: 		This function is called when the speed is output to the motors. 
;                   It creates an update string with the new direction. This string is 
;                   sent through the serial channel to be displayed by the LED display. 
; 
; Operation: 		To output a string with the updated direction, we concatenate
;                   a label with our direction as a string (converted using 
;                   dec2String). Then we send this string to SerialPutString so 
;                   it can be transmitted through the serial channel.
;
; Arguments:		None.
; Return Value:		None.
;
; Local Variables:	None.
; Shared Variables: stringInProgress (w) - status string we are currently writing.
;                   stringInProgressLength(w/r) - length of status string so far 
; Global Variables: None.

; Input:			None. 
; Output:			String sent through serial.
;
; Error Handling:	None.
; Algorithms:		None. 
; Data Structures: 	None. 
;
	
SendSerialUpdatedDirection 	PROC 	NEAR 							
                            PUBLIC  SendSerialUpdatedDirection
	MOV 	BX, 0 
    MOV     stringInProgressLength, 0 
SendSerialUpdatedDir: 
	
	LEA 	SI, Updated_Direction_Header		; load SI with the header label 
	ADD 	SI, BX 							; then add the index to get to current char being added 
	MOV 	AL, BYTE PTR CS:[SI]				; then move the character at that address into AL 
	CALL 	MakeString 						; to call MakeString with 
	INC 	BX 								; then we increment the register holding current position in the label string 
	
	CMP 	AL, ASCII_NULL 					; see if we've reached the end of label string 
	JNE 	SendSerialUpdatedDir			; if not, keep going 
	; if equal, start to parse number 		; but if we have reached end of label string, then 
		
	CALL 	GetMotorDirection 					; we get the motor speed here into AX 
	LEA 	SI, stringInProgress			; load up string address to concatenate to 
	ADD 	SI, stringInProgressLength 		; get to the location of the end character 
    
    DEC     SI                              ; remove null character 
	
	CALL  	Dec2String 						; add on the hexadecimal representation of speed 
											; will be null-terminated 
OutputDirSerialString: 											
	LEA 	SI, stringInProgress 			; then load SI with string to be output 
	PUSH    DS 
    POP     ES 
    CALL 	SerialPutString 				; then put string through serial channel 

	RET 
SendSerialUpdatedDirection	ENDP 






Updated_Speed_Header     	LABEL   BYTE 
    DB  'New Speed - ',ASCII_NULL 
Updated_Direction_Header    LABEL   BYTE 
    DB  'New Direction - ',ASCII_NULL 
Updated_Laser_Elv_Header		LABEL 	BYTE 
	DB 	'New Laser Angle - ',ASCII_NULL 



;
;
; DoNOP  
;
;
; Description:  	This function does nothing, and returns. 
;
; Operation:    	We do no operation, then return.
;
; Arguments:        None.
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: None.
; Global Variables:	None.
; 
; Input:            None.
; Output:           None.
;
; Algorithms: 		None. 
; Data Structures:  None.
; Error Handling: 	None.
; Registers Used: 	None.
;

DoNOP   PROC    NEAR 
        
    NOP                 ; do nothing
    RET
DoNOP       ENDP


    
    

    
CODE    ENDS

; data segment 


DATA        SEGMENT     PUBLIC      'DATA'
errorFlag               DW  ?
    ; tells if there's a serial or parse error.
errorString             DB  MAX_DISPLAY_STR_SIZE    DUP     (?)
    ; data variable we store error string at while making it 
errorStringLength       DW  ?
    ; length of error string so far 
stringInProgress        DB  MAX_DISPLAY_STR_SIZE    DUP     (?)
	; stringInProgress stores and concatenates serial string characters as they are 
	; received
stringInProgressLength  DW  ?
	; stringInProgressLength stores length of the in-progress string, which also is 
	; the index of next character insertion

    DATA        ENDS
    
END