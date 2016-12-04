

; These functions are the UI event handlers for the motor unit. They handle 
; events dequeued from the event queue, when they are ready to handle. Possible 
; events include errors, serial characters reception, and sending serial characters 
; for display on the remote unit LED display. After an event is dequeued, the 
; HandleMotorEvents function looks up the corresponding action and executes it. 
; For this outline, the functions included are: 
; 	SendMotorFeedback - creates string describing motor status to remote unit
; 	HandleMotorEvents - handles serial characters received by motor unit
; 	SendMotorError - sends parse and serial errors to remote unit to display
;	MakeString - concatenates passed in values to a stringInProgress variable


;
; SendMotorFeedback
;
;
; Description:  	This function is called when a valid command is received and 
; 					parsed by the motor unit. It gets the robot's speed, direction,
; 					and other status variables. It populates the string according 
; 					to these values, and then it sends the string to be displayed 
; 					through the serial channel. 
;
; Operation:    	We look up in a table the headers (like "speed", "direction", 
; 					etc.) and concatenate this to the stringInProgress. Then we 
; 					get the corresponding values, and convert them to decimal 
; 					strings. We concatenate these, similarly, to the end of the 
; 					stringInProgress. Then we end the string with a <NULL>
; 					character. 
; 
; Arguments:        None. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: stringInProgress - queue that holds string to be displayed 
; Global Variables:	None.
; 
; Input:            None.
; Output:           The stringInProgress queue is passed through the serial channel. 
;
; Algorithms: 		None. 
; Data Structures:  HeaderTable - table that stores the strings that serve as labels
; 					for the robot setting statuses. 
;

SendMotorFeedback 	PROC 	NEAR 

WriteSpeedHeader: 
	MOV 	SI, speedHeader 
SendMotorFeedback	ENDP 
; Get Motor Speed 
	BX = index in HeaderTable 
	speedLabelString = HeaderTable[BX]				; spells 'Speed: '
	increment through speedLabelString and call MakeString for each character 
	
	speed = getMotorSpeed()							; get motor speed 
	speedString = Dec2String(speed)					; convert to decimal string 
	increment through speedString and call MakeString for each character 
	
; Get Motor Direction 
	BX++ 
	dirLabelString = HeaderTable[BX]				; spells 'Direction: '
	increment through dirLabelString and call MakeString for each character 
	
	direction = getMotorDirection()							; get motor direction
	directionString = Dec2String(direction)					; convert to decimal string 
	increment through directionString and call MakeString for each character 
	
; Get Laser Status 
	BX++ 											; inc BX 
	laserLabelString = HeaderTable[BX]				; spells 'Laser: '
	increment through laserLabelString and call MakeString for each character 
	
	laser = getLaser()							; get laser status 
	laserString = Dec2String(laser)					; convert to decimal string 
	increment through laserString and call MakeString for each character 
	
	MakeString(<NULL>) 				; to end string 
	
	
;
; HandleMotorEvents
;
;
; Description:  	This function looks at the value in AX to see what the event 
; 					is and calls the appropriate 
;
; Operation:    	If the the event queue has a serial command value, we 
; 					send this value to the parser routines and send the motor status
; 					information through the serial channel to the remote unit to 
; 					be displayed. If the event to be handled is an error, f
; 
; Arguments:        AX - event type and value to be handled. 
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
;

HandleMotorEvents	PROC 		NEAR 
					PUBLIC 		HandleMotorEvents
	%CLR(AH)
	MOV 	BX, AL 
	SHL 	BX, 1 
	CALL 	CS: MOTOR_EVENTS_TABLE[BX]
	
	RET
HandleMotorEvents	ENDP 

MOTOR_EVENTS_TABLE 	LABEL 	BYTE 

	DW 	SendMotorError
	DW 	ParseSerialChar
	
	
	
	If AX == <NULL>: 			; this signifies end of a command
		statusString = SendMotorFeedback()
		SerialPutString(statusString)

	If AH == serial_command_val: 
		ParseSerialChar(AL)
		
	If AH == error_val:
		SendMotorError(AL)
		


;
; SendMotorError 
;
;
; Description:  	This function is called when an error arises. It sends the 
; 					error through serial channel to be displayed on the LED 
; 					display on the remote unit board. 
;
; Operation:    	We check the error flag to see if there has been a parse 
; 					error or serial error. If that's the case, then we send the 
; 					error value through the serial channel. 
; 
; Arguments:        None. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: parseErrorFlag - keeps track if there was a parse error 
; 					serialErrorFlag - keeps track if there was a serial error. 
; Global Variables:	None.
; 
; Input:            None.
; Output:           The error value is passed through the serial channel. 
;
; Algorithms: 		None. 
; Data Structures:  None.

SendMotorError		PROC 	NEAR 
	
CheckForParseError: 
	

SendMotorError		ENDP 

	SerialPutChar(specialized error value, plus the error value that corresponds to 
					parse or serial error)			

	
;
; MakeString 
;
;
; Description:  	This function takes in the ASCII value of a character passed in  
; 					by AL. It concatenates the ASCII character to the end of the string.
; 					
;
; Operation:    	
;
; Arguments:        AL - ASCII value of character you wish to tack onto end of string
; Return Value:     None. 
;
; Local Variables:  None. 
; Shared Variables: stringInProgress - array that holds string currently being written
;								max length is 128 characters. 
; Global Variables:	None.
; 
; Input:            None.
; Output:           None. 
;
; Error Handling: 
; Registers Used: 
; Algorithms: 		None. 
; Data Structures:  None.
;

MakeString		PROC	NEAR

CheckStringInProgressCapacity:
	CMP 	stringInProgressLength, MAX_STRING_IN_PROG_LENGTH
	JL		AddNewCharacter
	JGE 	EndMakeString 
AddNewCharacter: 
	%(AH)							; clear AH because we only care about AL 
	MOV 	BX, stringInProgressLength
	MOV 	CX, OFFSET(stringInProgress)
	ADD 	BX, CX
	MOV 	DS:[BX], AL 
EndMakeString:
	RET 
MakeString		ENDP