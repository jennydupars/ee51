	NAME		REMOTEUI
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;				 HELPER FUNCTIONS FOR REMOTE UNIT: EVENT HANDLING            ;
;                           	   Homework 9        		                 ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains functions that handle events that are dequeued from the event
; queue. Possible events are error events, serial character reception events, and 
; key press events. This function handles the user interface: when serial characters
; are received, they will be displayed on the display. When key presses are 
; registered, the command associated with it is shown on the screen. When errors 
; arise, after they are dequeued from the event queue, the screen will display the
; error code. This error code can be mapped to the exact errors using the legend 
; found in the attached Robotrike functional specification.
;
; The functions included are: 
; Public functions: 
; 	QueueEventHandler - event handler to take care of events dequeued from eventQueue
; Local functions: 
; 	HandleErrorEvent - handles an error event dequeued from eventQueue
; 	HandleKeyPressEvent - handles a key press event dequeued from eventQueue
; 	HandleSerialCharEvent - handles serial character received event 
; 	ResetErrorFlag - resets error flag after we have handled error 
; 	DoNOP - do no operation (placeholder function in key command table)

;
; Input:            Keypad input, serial input from motor unit.
; Output:           Display input, serial output to motor unit. 
;
; User Interface: 	Keys pressed by the user are registered as key press events, and 
; 					are handled by sending the key value through the serial port to 
; 					the motor board. The display will show current motor status, 
; 					system status, and commands when they are requested by user key 
; 					presses. 
;
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
; 	 12/04/2016 		Jennifer Du 	writing assembly code 


$INCLUDE(common.inc)			; commonly used constants
$INCLUDE(remoteui.inc)			; event values and UI constants 
$INCLUDE(macros.inc)			; commonly used macros 
$INCLUDE(display.inc)			; constants used to control LED display
       

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP

; external function declarations
    EXTRN   Display:NEAR			; used to display error and serial strings 
	EXTRN   SerialPutString:NEAR	; used to send a string through serial channel
	
	
;
; QueueEventHandler 
;
;
; Description:  	This function handles events from the event queue when they 
; 					are passed to it through AX. The events that will be handled 
; 					will be errors, key press events, and serial events. 
;
; Operation:    	We have set it up so error values have 00 in AH, key presses 
; 					have the value 02 in AH, and serial character events have 04 
; 					in AH. AH holds the type of event, and AL holds the value. 
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
	RET 
QueueEventHandler 		ENDP 



	
;
; HandleErrorEvent 
;
;
; Description:  	This function handles error events from the event queue, passed
; 					through AX. The error event identifier value is passed in AH and
; 					the value of the error will be passed through AL. This function 
; 					will display the error message on the display. These numbers 
; 					correspond to errors that have occurred during serial transmission
; 					routines.
; 					Error codes can be identified using the table found in the 
; 					Robotrike's functional specification. 
;
; Operation:    	The error value number passed in AL corresponds to the index in 
; 					the error message table. We look up the appropriate error message
; 					and display it on the LED display. 
;
; Arguments:        AX - error value is stored in AL. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: None.
; Global Variables:	None.
; 
; Input:            None.
; Output:           Display shows error message. 
;
; Algorithms: 		None. 
; Data Structures:  Error message table.
;
; Error Handling: 	None.
; Registers Used: 	AX, BX. 
; Stack Depth: 		2 words.

HandleErrorEvent		PROC 	NEAR 

    MOV     errorFlag, TRUE		; flag error - let system know that error has occurred
	
	%CLR(AH)					; clear AH; we would like to use error value as index
	MOV 	BX, AX 				; move error value into index 
	SHL     BX, 1               ; offsets take up a word of space, so multiply index
                                ; by 2 to get appropriate entry in the table of 
                                ; word-sized entries
    MOV	 	SI, CS:ERROR_STRING_TABLE[BX]	; look up appropriate error string 
	PUSH 	CS 					; Push CS and pop ES since the Display function 
	POP 	ES 					; expects a string passed in ES:SI 
	CALL 	Display				; display the error message string 
	
	RET 
HandleErrorEvent		ENDP 


;
; HandleSerialCharEvent 
;
;
; Description:  	This function is called when a serial event is enqueued to 
; 					the event queue, or received from the motor unit board. 
;					This happens when the motor unit board is sending back 
; 					information to the remote board about the motor status. 
; 					When this function is called, the serial value received will
; 					be shown on the display.   
;
; Operation:    	We take each character as it comes, and call MakeString to 
; 					concatenate each character to the growing string. If the 
; 					current character is equal to <CARRIAGE RETURN>, this 
; 					indicates that this the end of the string being written. 
;					In this case, we would consider the string done being written,
; 					and display the string. 
; 
; Arguments:        AX - serial event value to be handled.
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: stringInProgress (W) - queue that holds string to be displayed
;						and modified by subsequent characters received through serial
; 					stringInProgressLength (R/W) - length of growing string in 
; 						progress, also the index of string that the new character 
; 						is written to.
; Global Variables:	None.
; 
; Input:            None.
; Output:           The stringInProgress queue is displayed on the LED display at a 
; 					designated string ending. 
;
; Algorithms: 		None. 
; Data Structures:  Array, or string buffer storing growing string of received serial
; 					characters.
;
; Error Handling: 	None.
; Registers Used: 	AX, BX, flags.
;
HandleSerialCharEvent		PROC 	NEAR 

	PUSHF								; save flags
	CLI 								; turn off interrupts
    
    CMP     errorFlag, TRUE 			; if error is occurring, it takes priority 
										; over showing serial char 
    JE      EndHandleSerialCharEvent	; simply end event. Note: cannot see 
										; received data unless error flag is cleared
    
    
	MOV 	BX, stringInProgressLength	; move index of new character insertion into 
										; index register 
CheckEndOfString: 						; check to see if current character marks end 
										; of serial string 
	CMP 	AL, ASCII_CAR_RET			; compare current character with string ending 
	JZ 		DisplayStringInProgress		; if <end of string>, start to display string 
	
	CMP 	BX, MAX_DISPLAY_STR_SIZE	; if the index of current character insertion 
										; is about to or does exceed the maximum 
										; display length, do not overwrite string 
										; buffer, 
	JGE 	DisplayStringInProgress		; display the string that has been formed. 

AddCharToStringInProgress: 				; if we did not reach the end of a serial 
										; string, add the character to the current 
										; index of insertion (BX) in the string buffer
	MOV 	stringInProgress[BX], AL	; move passed character's ASCII value into 
										; string buffer at insertion index
	INC 	BX 							; increment index 
	MOV 	stringInProgressLength, BX 	; store current character index for use in 
										; next iteration of serial character received
	JMP 	EndHandleSerialCharEvent 	; after this, end function 
	
DisplayStringInProgress: 				; display string that was being formed when 
										; end of serial string or end of display buffer
										; is reached 
	MOV 	stringInProgress[BX], ASCII_NULL 
										; end the display string with null character
										; to delimit string for the display function
	LEA 	SI, stringInProgress		; load address of string being formed
	PUSH 	DS							; push DS and pop ES because Display function 
	POP 	ES 							; expects string passed in at ES:SI location 
	CALL 	Display 					; call display string 
    
    MOV     stringInProgressLength, 0 	; reset index to start next serial string when
										; new serial string is sent to the remote board
	;JMP 	EndHandleSerialCharEvent

EndHandleSerialCharEvent: 
	POPF								; restore flags and exit 
	RET 
HandleSerialCharEvent		ENDP 



;
;
; HandleKeyPressEvent 
;
;
; Description:  	This function handles key press events from the event queue, 
; 					passed through AX. We can see the value of the key press in 
; 					AL, so we know which key is being pressed. From this, we will
; 					know what command or action this corresponds to. For most of 
; 					the commands, we will call SerialPutString to send the key's
; 					corresponding command string through the serial channel. 
;
; Operation:    	We look up the string corresponding to the key value AL in the 
; 					KeyPressTable. Then we call SerialPutString to send the string
; 					through the serial port. We will also look up the display string
; 					corresponding to the key value, and call Display to show it on 
; 					the LED display. 
;
; Arguments:        AX - key event being handled with value in AL 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: None.
; Global Variables:	None.
; 
; Input:            None.
; Output:           Command strings associated with the key presses are sent through 
; 					the serial channel. Display strings associated with the pressed 
; 					key(s) are displayed on the LED display. 
;
; Algorithms: 		None. 
; Data Structures:  Key Command Table - table mapping key presses to strings to send
; 					through serial port to motor unit
;
; Error Handling: 	Invalid key values, when pressed, display an "Invalid Key" string
; 					on the LED display. 
; Registers Used: 	AX, BX.
; Stack Depth: 		2 words.

HandleKeyPressEvent 		PROC 	NEAR 

	%CLR(BX)				; clear index register 
	%CLR(AH)				; clear event type, only key value is relevant to table 
							; lookup index 
GetKeyPresTableLookupIndex: 
	MOV 	BX, KEY_COMMAND_ENTRY_SIZE
	MUL 	BX 				; multiply index by size of each key command entry 
							; to reach desired byte index in key command table
	MOV 	BX, AX 			; move multiplied result into index register 
	PUSH 	BX 				; save index before the called functions change it 

DisplayDisplayString: 
	
	MOV 	SI, CS:KEY_COMMAND_TABLE[BX].DISPLAYSTRING
							; retrieve display string from each key command entry 
	PUSH 	CS				; push CS and pop ES because Display expects a string
	POP 	ES				; located at ES:SI 
	
	CALL 	Display 		; then call Display to display the selected string to 
							; LED display
	
SendCommandString:
	
	POP 	BX 				; restore index value saved before Display was called
	MOV 	SI, CS:KEY_COMMAND_TABLE[BX].COMMANDSTRING
							; retrieve command string from selected key command entry
	PUSH 	CS				; push CS and pop ES because SerialPutString expects a 
	POP 	ES				; string located at ES:SI
	
	CALL 	SerialPutString	; then call SerialPutString to put each character into 
							; transmit queue to send through serial channel 
	
DoAction: 					; do action linked with that key 
    CALL    CS:KEY_COMMAND_TABLE[BX].ACTION
	
	RET 			
HandleKeyPressEvent			ENDP



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
        
    NOP
    RET
DoNOP       ENDP

;
;
; ResetErrorFlag
;
;
; Description:  	This function resets the error flag so that the system understands
; 					that we are done handling errors.
;
; Operation:    	We reset the errorFlag variable, then return.
;
; Arguments:        None.
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: errorFlag (w) - lets system know if we are currently dealing with 
; 						error or not 
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
ResetErrorFlag  PROC    NEAR

    MOV     errorFlag, FALSE 

    RET 
ResetErrorFlag  ENDP


;
;
; Key Command Table Entry 
; 
; Description: 	Each key value corresponds to a display string and a string to send
; 				through the serial channel to the motor unit. This struct is defined 
; 				to simplify the table used to look up key commands and actions. 
;
KEY_COMMAND_ENTRY 	STRUC 
	DISPLAYSTRING 	DW      ?				; string to be displayed when key is pressed
	COMMANDSTRING 	DW	    ?				; string to be sent as command when key is pressed
    ACTION          DW      ?				; action that is executed when key is pressed 
KEY_COMMAND_ENTRY 	ENDS 

KEY_COMMAND_ENTRY_SIZE 	EQU 	6 		; 2 words are 4 bytes, display and command
										; strings take up 4 bytes 

										
;
;
; Key Command Table 
; 
; Description: 	This table contains the display and command strings associated with
; 				the value of each possible key press on the 16-key keypad. Each entry
; 				is defined by the KEY_COMMAND_ENTRY struct. This table is indexed in 
; 				order from least to greatest, of every key combination value possible 
; 				with row-limited multipress. 
										
KEY_COMMAND_TABLE 	LABEL 	KEY_COMMAND_ENTRY
																		; Key value 
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 00
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 01 
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string),DoNOP>			; 02 
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 03
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP >		; 04 
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP >		; 05 
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 06 
	KEY_COMMAND_ENTRY<OFFSET(Direction_90), OFFSET(Direction_90), DoNOP>			; 07
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 08
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 09
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 0a
	KEY_COMMAND_ENTRY<OFFSET(Increment_speed), 	OFFSET(Increment_speed), DoNOP>		; 0b
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 0c
	KEY_COMMAND_ENTRY<OFFSET(Decrement_speed), 	OFFSET(Decrement_speed), DoNOP>		; 0d
	KEY_COMMAND_ENTRY<OFFSET(Stop_robot_disp), 	OFFSET(Stop_robot_comm), DoNOP>		; 0e
	KEY_COMMAND_ENTRY<OFFSET(No_display_string), OFFSET(No_command_string), DoNOP>	; 0f
	
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 10
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 11 
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 12 
	KEY_COMMAND_ENTRY<OFFSET(Direction_90), OFFSET(Direction_90), DoNOP>			; 13
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 14
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP >		; 15 
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 16
	KEY_COMMAND_ENTRY<OFFSET(Direction_180), OFFSET(Direction_180), DoNOP>			; 17
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 18
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string),DoNOP>		; 19 
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string),DoNOP>		; 1a
	KEY_COMMAND_ENTRY<OFFSET(Direction_0), 	OFFSET(Direction_0), DoNOP>			; 1b
	KEY_COMMAND_ENTRY<OFFSET(Speed_half), OFFSET(Speed_half), DoNOP>				; 1c
	KEY_COMMAND_ENTRY<OFFSET(Speed_max), OFFSET(Speed_max), DoNOP>					; 1d
	KEY_COMMAND_ENTRY<OFFSET(Speed_0), 	OFFSET(Speed_0), DoNOP> 					; 1e
	KEY_COMMAND_ENTRY<OFFSET(No_display_string), OFFSET(No_command_string), DoNOP>	; 1f

	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), 	OFFSET(No_command_string), DoNOP>		; 20
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), 	OFFSET(No_command_string), DoNOP>		; 21 
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 22 
	KEY_COMMAND_ENTRY<OFFSET(Direction_270), OFFSET(Direction_270),DoNOP>			; 23
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), 	OFFSET(No_command_string),DoNOP>		; 24 
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), 	OFFSET(No_command_string), DoNOP>		; 25 
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 26
	KEY_COMMAND_ENTRY<OFFSET(Increment_direction), OFFSET(Increment_direction), DoNOP>	; 27
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 28 
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), 	OFFSET(No_command_string), DoNOP>		; 29 
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 2a
	KEY_COMMAND_ENTRY<OFFSET(Decrement_direction), OFFSET(Decrement_direction), DoNOP>	; 2b 
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string),DoNOP>		; 2c 
	KEY_COMMAND_ENTRY<OFFSET(Laser_off_disp), OFFSET(Laser_off_comm), DoNOP>		; 2d
	KEY_COMMAND_ENTRY<OFFSET(Laser_on_disp), OFFSET(Laser_on_comm), DoNOP>			; 2e
	KEY_COMMAND_ENTRY<OFFSET(No_display_string), OFFSET(No_command_string), DoNOP>	; 2f
	
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 30
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 31 
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 32 
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 33
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), 	OFFSET(No_command_string), DoNOP>		; 34 
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 35 
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 36
	KEY_COMMAND_ENTRY<OFFSET(Error_Clear), OFFSET(No_command_string), ResetErrorFlag>; 37
	KEY_COMMAND_ENTRY<OFFSET(Invalid_key), OFFSET(No_command_string), DoNOP>		; 38 
	KEY_COMMAND_ENTRY<OFFSET(Turret_pos_30), OFFSET(Turret_pos_30), DoNOP>			; 39 
	KEY_COMMAND_ENTRY<OFFSET(Turret_neg_30), OFFSET(Turret_neg_30), DoNOP>			; 3a
	KEY_COMMAND_ENTRY<OFFSET(Direction_270), OFFSET(Direction_270), DoNOP>			; 3b 
	KEY_COMMAND_ENTRY<OFFSET(Turret_0), OFFSET(Turret_0), DoNOP>					; 3c 
	KEY_COMMAND_ENTRY<OFFSET(Turret_pos_60), OFFSET(Turret_pos_60), DoNOP>			; 3d
	KEY_COMMAND_ENTRY<OFFSET(Turret_neg_60), OFFSET(Turret_neg_60), DoNOP>			; 3e
	KEY_COMMAND_ENTRY<OFFSET(No_display_string), OFFSET(No_command_string), DoNOP>	; 3f

	
;
; These labels store the strings referred to in the key command table.
;
Error_Clear     LABEL   BYTE 
    DB  'Error flag cleared',ASCII_NULL 
Invalid_key   LABEL   BYTE
    DB      'E:Invalid key',ASCII_NULL
No_command_string   LABEL   BYTE 
    DB      '         ',ASCII_NULL

Direction_0     LABEL   BYTE
    DB  'D0',ASCII_CAR_RET,ASCII_NULL
Direction_90     LABEL   BYTE
    DB  'D90',ASCII_CAR_RET,ASCII_NULL
Direction_180     LABEL   BYTE
    DB  'D180',ASCII_CAR_RET,ASCII_NULL
Direction_270     LABEL   BYTE
    DB  'D270',ASCII_CAR_RET,ASCII_NULL

Speed_0         LABEL   BYTE
    DB  'S0',ASCII_CAR_RET,ASCII_NULL
Speed_max       LABEL   BYTE
    DB  'S65534',ASCII_CAR_RET,ASCII_NULL
Speed_half      LABEL   BYTE
    DB  'S32767',ASCII_CAR_RET,ASCII_NULL

Increment_direction LABEL   BYTE
    DB  'D+10',ASCII_CAR_RET,ASCII_NULL
Decrement_direction LABEL   BYTE
    DB  'D-10',ASCII_CAR_RET,ASCII_NULL

Decrement_speed LABEL   BYTE
    DB  'V-256',ASCII_CAR_RET,ASCII_NULL	
Increment_speed LABEL   BYTE
    DB  'V+256',ASCII_CAR_RET,ASCII_NULL

Turret_pos_30   LABEL   BYTE 
    DB  'T+30',ASCII_CAR_RET,ASCII_NULL    
Turret_neg_30   LABEL   BYTE 
    DB  'T-30',ASCII_CAR_RET,ASCII_NULL
Turret_0        LABEL   BYTE
    DB  'T0',ASCII_CAR_RET,ASCII_NULL
Turret_pos_60   LABEL   BYTE 
    DB  'T+60',ASCII_CAR_RET,ASCII_NULL    
Turret_neg_60   LABEL   BYTE 
    DB  'T-60',ASCII_CAR_RET,ASCII_NULL

Laser_off_disp  LABEL   BYTE 
    DB  'Laser off',ASCII_CAR_RET,ASCII_NULL
Laser_off_comm  LABEL   BYTE 
    DB  'O',ASCII_CAR_RET,ASCII_NULL
Laser_on_disp   LABEL   BYTE 
    DB  'Laser on',ASCII_CAR_RET,ASCII_NULL
Laser_on_comm   LABEL   BYTE
    DB  'F',ASCII_CAR_RET,ASCII_NULL

No_display_string   LABEL   BYTE 
    DB  '',ASCII_CAR_RET,ASCII_NULL

Stop_robot_comm  LABEL   BYTE
    DB 'S0',ASCII_CAR_RET,'O',ASCII_CAR_RET,'D0',ASCII_CAR_RET,ASCII_NULL
Stop_robot_disp  LABEL   BYTE
    DB  'STOPPED',ASCII_NULL

	

;
;
; Error Message String Table 
; 
; Description: 	This table holds error message strings, stored as offsets of labels.
; 				Each label holds a different error message, and the strings at each 
; 				location are defined in the 9 error labels under the string table.
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

    
    

; 
; 
; Event Type Table 
; 
; Description: 	This table lets us look up what event type has occurred, based on
; 				the event code. A CALL table for handling error events, key press
; 				events, and serial character events. 
EVENT_TYPE_TABLE 		LABEL 	WORD		
	
	DW 		HandleErrorEvent                ; AH = 00
											; called to display error message 
	DW 		HandleKeyPressEvent             ; AH = 02
											; called to send/display commands 
	DW 		HandleSerialCharEvent           ; AH = 04	
											; called to display serial characters
	 
    
CODE    ENDS

; data segment 


DATA        SEGMENT     PUBLIC      'DATA'

stringInProgress        DB  MAX_DISPLAY_STR_SIZE    DUP     (?)
	; stringInProgress stores and concatenates serial string characters as they are 
	; received
stringInProgressLength  DW  ?
	; stringInProgressLength stores length of the in-progress string, which also is 
	; the index of next character insertion
errorFlag               DB  ?
    ; tells us if error currently being dealt with
    DATA        ENDS
    
END 