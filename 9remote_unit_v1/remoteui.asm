; For this outline, the functions included are: 

; 	HandleEvents - event handler to take care of any event dequeued from eventQueue
; 	HandleErrorEvent - handles an error event dequeued from eventQueue
; 	HandleKeyPressEvent - handles a key press event dequeued from eventQueue
; 	HandleSerialCharEvent - handles serial character received event 


;	MakeString - concatenates passed in values to a stringInProgress variable
; 	SerialPutString - puts string in serial channel for transmission
;

		
		
	
;
; HandleEventQueueEvent
;
;
; Description:  	This function handles events from the event queue when they 
; 					are passed to it through AX. The events that will be handled 
; 					will be errors, key press events, and serial events. 
;
; Operation:    	We have set it up so error values have 00 in AH, key presses 
; 					have the value 01 in AH, and serial character events have 02 
; 					in AH. AH holds the type of event, and AL holds the value. 
; 					Based on the value in AH, we can tell what type of event has 
; 					been dequeued, and call the appropriate handler. /////////////////////////////////
	
; Arguments:        None.
; Return Value:     AX - event value and type to be handled. 
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

HandleEventQueueEvent 		PROC 	NEAR 
	
	MOV 	CH, AH			; don't modify AX so we can pass it to called functions  
	%CLR(BX)					 
	SHL 	CH, 1 			; multiply by wordsize to get index in event call table 
	MOV 	BL, CH 
	CALL 	CS:EVENT_TYPE_TABLE[BX]
	
	RET 
HandleEventQueueEvent 		ENDP 



; this table lets us look up what event type has occurred based on the event code 	//// more description
EVENT_TYPE_TABLE 		LABEL 	BYTE 
	
	DW 		HandleErrorEvent
	DW 		HandleKeyPressEvent 
	DW 		HandleSerialCharEvent 
	

;
; HandleErrorEvent 
;
;
; Description:  	This function handles error events from the event queue, passed
; 					through AX. The error event identifier value is passed in AH and
; 					the value of the error will be passed through AL. This function 
; 					will display the error message on the display. 
;
; Operation:    	We use a numbering system that maps each error to a number. Then, 
; 					we display a string containing "Error: " and concatenate it with
; 					the number of the error. The value of the error is passed in 
; 					through AL. 
	
; Arguments:        AX - error value is stored in AL. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: stringInProgress - string holding string being concatenated with 
; 								serial characters coming in one by one. 
; Global Variables:	None.
; 
; Input:            None.
; Output:           Display shows error message. 
;
; Algorithms: 		None. 
; Data Structures:  None.
;

HandleErrorEvent		PROC 	NEAR 
	MOV 	SI, errorString
	ADD 	SI, END_OF_ERROR_STRING_LABEL			; should be 7? "ERROR: "
	%CLR(AH)
	PUSH 	SI 
	CALL 	Dec2String
		; then the ASCII value of AL should be stored at errorStringLoc + lengthOfErrorString 
	POP 	SI 
	INC 	SI 
	MOV 	SI, ASCII_NULL 		; end string? 
	MOV 	SI, errorString 
	CALL 	Display 
	RET 
HandleErrorEvent		ENDP 
	
	; want to concatenate "error: " with value stored in AL 
	Enqueue "Error: " one by one using SI to increment 
	AL = Dec2String(AL)								; turn into decimal string 
	MakeString(AL)									; add the character to stringInProgress 
	CALL Display(stringInProgress)					; display routine to display error 
	
	
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
; 					through the serial port. 
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
; 					the serial channel. 
;
; Algorithms: 		None. 
; Data Structures:  KeyPressTable - table mapping key presses to strings to send 
; 					through serial port to motor unit.
;
HandleKeyPressEvent 		PROC 	NEAR 
	%CLR(BX)
	%CLR(AH)
	MOV 	BX, AX			; move the value of the key into BX (with clear AX, so we get just the index)
	PUSH 	BX 				; save index 

DisplayDisplayString: 
	; display the display string 
	MOV 	SI, OFFSET(CS:KEY_COMMAND_TABLE[BX].DISPLAYSTRING)
	CALL 	Display 

SendCommandString:
	; send command string through serial 
	POP 	BX 												; restore index value 
	MOV 	SI, OFFSET(CS:KEY_COMMAND_TABLE[BX].COMMANDSTRING)
	;MOV 	AL, ASCII_NULL 					; do i need to worry about putting a null character after my command strings?
	;CALL 	MakeString
	CALL 	SerialPutString
					; what about errors????????????????????????????????????/

DoActionOfTheKey: 	
	CALL 	CS:KEY_COMMAND_TABLE[BX].ACTION 
	
	RET 									; maybe i should make the whole thing stop if there's an error somewhere 
HandleKeyPressEvent			ENDP


	
; 							key 1 	key 2	key 3 	key 4
;					row 0	 0e 	 0d 	 0b 	 07 
;					row 1    1e 	 1d 	 1b 	 17
;					row 2    2e 	 2d 	 2b 	 27
; 					row 3  	 3e 	 3d 	 3b 	 37
;

; 		
;		+---------------+---------------+---------------+---------------+
;		|				|				|				|				|
;		|  Reset robot	|	V-256		|	V+256		|	Display		|
;		|	(stop or	| reduce speed	| increase speed|	  Mode		|
;		|	reset all	| by about 0.4%	| by about 0.4%	|	 Toggle		|
;		|	movement)	|				|				|				|
;		+---------------+---------------+---------------+---------------+
;		|		S0		|	S65534		|	  D0		|	D180		|
;		|	set speed	|	set speed	| set direction	| set direction	|
;		|	to minimum	|	to maximum	|  to straight	| to backwards	|
;		|	 (stop)		|				|	  ahead		|				|
;		|				|				|				|				|
;		+---------------+---------------+---------------+---------------+
;		|	Laser on	|	Laser off	|	D-15		|	D+15		|
;		|		F		|		O		| move at 15 deg| move at 15 deg|
;		|				|				| more to the 	| more to the 	|
;		|				|				|	left		|	right		|
;		|				|				|				|				|
;		+---------------+---------------+---------------+---------------+
;		|	  T-60		|	  T60		|		 		|	 			|
;		| 	Change		|	Change		| 				| 				|
;		|	 turret 	|	 turret		|  				|  				|
;		| elevation to 	| elevation to	|	 	 		|				|
;		|  -60 degrees	|  60 degrees	|				|				|
;		+---------------+---------------+---------------+---------------+
;
; 		Also, for the second row, multiple key presses are allowed. Pressing 
; 		keys one and two at the same time sets the robot's movement to half 
; 		speed. Pressing keys three and four at the same time causes the robot
; 		to move at 90 degrees. 
; 		
;		In the third row, multiple key presses are also allowed. Pressing key 
; 		three and four at the same time will cause the robot to move at an angle
; 		of 270 degrees. 
;
; 		For the fourth row, multiple key presses are also allowed. Pressing 
;		the first key by itself will send a turret elevation -60 degrees 
; 		command, and the 2nd key by itself will send a turret elevation 
; 		60 degrees command. Pressing both will result in a turret elevation
; 		of 0 degrees with respect to the horizontal. Combining keys 1 and 3 
; 		will result in a turret elevation of -30 degrees, and combining keys
; 		2 and 3 will result in a turret elevation of positive 30 degrees. 
;
;		Autorepeat of key presses is also possible. In the first row of keys,
; 		holding keys 2 and 3 down for longer times will result in more change 
; 		in speed as if the button was pressed repeatedly. In the third row of 
; 		keys, autorepeat is possible for keys 3 and 4. Holding these keys for
; 		prolonged periods of time will result in multiple requests for direction
; 		change. 
	
KEY_COMMAND_ENTRY 	STRUC 
	DISPLAYSTRING 	/////////////// size ?
	COMMANDSTRING 					size ?
	ACTION 		DW 		?
KEY_COMMAND_ENTRY 	ENDS 

%*DEFINE(KEYCOMMAND(displayString, commandString, action))(
	KEY_COMMAND_ENTRY< OFFSET(%displayString), OFFSET(%commandString), OFFSET(%action) >
)


KEY_COMMAND_TABLE 	LABEL 	KEY_COMMAND_ENTRY
														; Key value 
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 00
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 01 
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 02 
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 03
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 04 
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 05 
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 06 
	%KEYCOMMAND("", "", DisplaySystemSettings)				; 07
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 08
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 09
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 0a
	%KEYCOMMAND("V+256", "V+256", DoNOP)					; 0b
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 0c
	%KEYCOMMAND("V-256", "V-256", DoNOP)					; 0d
	%KEYCOMMAND("STOPPED ", "", CompletelyStopRobot)		; 0e
	%KEYCOMMAND("        ", "", DoNOP)						; 0f
	
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 10
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 11 
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 12 
	%KEYCOMMAND("D90     ", "D90", DoNOP)					; 13
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 14 
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 15 
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 16
	%KEYCOMMAND("D180", "D180", DoNOP)						; 17
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 18
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 19
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 1a
	%KEYCOMMAND("D0      ", "D0", DoNOP)					; 1b
	%KEYCOMMAND("S32767  ", "", DoNOP)						; 1c
	%KEYCOMMAND("S65534  ", "S65534", DoNOP)				; 1d
	%KEYCOMMAND("S0      ", "S0", DoNOP)					; 1e
	%KEYCOMMAND("        ", "", DoNOP)						; 1f
	
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 20
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 21 
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 22 
	%KEYCOMMAND("D270    ", "D270", DoNOP)					; 23
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 24 
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 25 
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 26
	%KEYCOMMAND("D+10    ", "D+10", DoNOP)					; 27
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 28 
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 29 
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 2a
	%KEYCOMMAND("D-10    ", "D-10", DoNOP)					; 2b 
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 2c 
	%KEYCOMMAND("Laser off", "O", DoNOP)					; 2d
	%KEYCOMMAND("Laser on", "F", DoNOP)						; 2e
	%KEYCOMMAND("        ", "", DoNOP)						; 2f
	
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 30
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 31 
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 32 
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 33
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 34 
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 35 
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 36
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 37
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 38 
	%KEYCOMMAND("T30     ", "T30", DoNOP)					; 39 
	%KEYCOMMAND("T-30    ", "T-30", DoNOP)					; 3a
	%KEYCOMMAND("E: Invalid key", "", DoNOP)				; 3b 
	%KEYCOMMAND("T0      ", "T0", DoNOP)					; 3c 
	%KEYCOMMAND("T+60    ", "T60", DoNOP)					; 3d
	%KEYCOMMAND("T-60    ", "T-60", DoNOP)					; 3e
	%KEYCOMMAND("        ", "", DoNOP)						; 3f
	


	
	
;
; HandleSerialCharEvent 
;
;
; Description:  	This function is called when a serial event is enqueued to 
; 					the event queue, or received from the motor unit board. 
;					This happens when the motor unit board is sending back 
; 					information to the remote board about the motor status.  
;
; Operation:    	We take each character as it comes, and call MakeString to 
; 					concatenate each character to the growing string. If the 
; 					current character is equal to <NULL>, this indicates that 
; 					this the end of the string being written. In this case, we 
; 					would display the string. 
; 
; Arguments:        AX - serial event value to be handled.
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: stringInProgress - queue that holds string to be displayed 
;						and modified by subsequent characters received through serial
; Global Variables:	None.
; 
; Input:            None.
; Output:           The stringInProgress queue is displayed on the LED display. 
;
; Algorithms: 		None. 
; Data Structures:  None.
;
HandleSerialCharEvent		PROC 	NEAR 

DetermineEndOfString: 
	CMP 	AL, ASCII_NULL 
	JE 		DisplayStringInProgress
	;JNE 	AddCharToStringInProgress
AddCharToStringInProgress: 
	CALL 	MakeString
	JMP 	EndHandleSerialCharEvent 
DisplayStringInProgress: 
	MOV 	SI, OFFSET(stringInProgress)
	CALL 	Display 
	;JMP 	EndHandleSerialCharEvent
EndHandleSerialCharEvent: 
	RET 
HandleSerialCharEvent		ENDP 
	