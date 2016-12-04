	NAME		MAIN
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;				        MAIN LOOP FOR MOTORS UNIT: Motors                    ;
;                           	   Homework 10        		                 ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program is the main loop for the motor unit which controls
; 					the main movement motors, the turret rotation motor, and the 
; 					turret elevation motor. 
;
;					The main loop will initialize everything necessary to parse 
; 					serial commands and send these commands to be reflected in the 
; 					movement of the motors. 
;
; Input:            Serial input from remote unit.
; Output:           Motors and laser activation, and serial output.
;
; User Interface: 	When keys are pressed, the proper commands are sent to the motor
; 					unit. These commands will be executed by the motors and laser.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Limitations: 		Assumes the ASCII character set. Hardware limitations create 
;					limits for what the Robotrike can do. The maximum speed is 
; 					limited by the hardware, and some motors are not able to rotate
; 					a full 360 degrees. 
; 
; Known Bugs:       None.
;
; Revision History:
;    11/29/2016         Jennifer Du     initial revision
; 	 11/30/2016 		Jennifer Du 	writing assembly code 


$INCLUDE(common.inc)
$INCLUDE(queue.inc)		; constants used for queue 


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP

;external function declarations
	EXTRN 	InitCS:NEAR						; initcs.asm 
	EXTRN 	ClrIRQVectors:NEAR 				; intrpvec.asm 
	EXTRN 	InstallINT2Handler:NEAR 		; int2.asm 
	EXTRN	InitINT2:NEAR 
	EXTRN 	InitSerial:NEAR 
	EXTRN	InstallTimer0Handler:NEAR
	EXTRN 	InitTimer0:NEAR 
	EXTRN 	InitDisplay:NEAR 
	EXTRN 	InitKeypad:NEAR 
	
	EXTRN 	DequeueEvent:NEAR 
	
			
	
            
START:  

MAIN: 

InitializeSystem:	

	MOV     AX, DGROUP              ;initialize the stack pointer
	MOV     SS, AX
	MOV     SP, OFFSET(DGROUP:TopOfStack)

	MOV     AX, DGROUP              ;initialize the data segment
	MOV     DS, AX

	CALL    InitCS                  ; initialize the 80188 chip selects
                                    ;   assumes LCS and UCS already setup

    CALL    ClrIRQVectors           ; initialize interrupt vector table

    CALL    InstallINT2Handler      ; install the event handler for INT2 
    CALL    InitINT2                ; initialize the INT2 interrupt 
	
    CALL    InitSerial				; initialize serial channel 
	
	CALL    InstallTimer0Handler     ;install the event handler

    CALL    InitTimer0               ;initialize the internal timer
	
    CALL    InitDisplay				;clear display and initialize muxing variables

    CALL    InitKeypad				; initialize keypad scanning variables

    STI                             ; and finally allow interrupts.
	
InitializeEventQueue: 
	MOV 	SI, OFFSET(eventQueue)		; initialize the queue and size
	MOV 	CX, ARRAY_SIZE - 1 
	
	
CheckCriticalError: 
	CMP 	criticalErrorFlag, IS_SET
	MOV 	criticalErrorFlag, NOT_SET 
	JE 		InitializeSystem				; if critical error flag occurred, then we re-initialize everything, and start over 
	;JNE 	CheckParseError					; if not, we go on:

CheckParseErrors:
	CALL 	GetParseErrorStatus
	CMP	 	AX, 0 
	JE 		CheckSerialErrors
	; if not equal to no-err val: 
	CALL 	HandleErrorEvent				; value of error is already in AL 
	;JMP 	CheckSerialErrors

CheckSerialErrors: 
	CALL 	GetSerialErrorStatus 
	CMP 	AX, 0 
	JE 		ProceedToDequeueEvent
	; if not equal to no-err val: 
	CALL 	HandleErrorEvent
	;JMP 	ProceedToDequeueEvent
	
ProceedToDequeueEvent: 
	
	CALL 	DequeueEvent				; do i need to check if empty or is this a blocking funciton? 
	CALL 	HandleEvents
		
		
		
	; to do: 
	figure out what to do about the LSRs in serial.asm, what error code they correspond to 
	make mini parser for remote side (or just display string?)
	FIGURE OUT makeString
	what calls serialPutChar?
	what file do i put my data variables in? like stringInProgress, criticalErrorFlag 
	
	
	fix past stuff: 
	FOR ALL: 
		fix too-generic label names
		fix too-generic constant names 
		quick comment/description fixes 
	
7	serial.asm: 
		fix LineStatus()
			check using 3 masks, one each for overrun error, parity error, and framing error, enqueue separate events 
		fix critical code in SerialPutChar()
		fix SetBaudRate()
			restore the original LCR value, not change it 
		make GetSerialErrors() function to check for serial errors 
	
5	keypad.asm: 
		fix KeypadMux() 
			reading past end of keypad?
	
4	display.asm:
		clear DX before DIV, lol in DisplayMux()
		try out scrolling!
		
3	queue.asm: 
		clear AH in QueueInit()
		fix critical code in Dequeue()
		fix critical code in Enqueue()
		fix code duplication?
		
2	converts.asm: 
		just rewrite it better lol 
		
		
	MOTORS UNIT: 
	
8 	parse.asm: 
		reset shared variables at the end of every output function (because things either end in error or output functions)
		return no-error-val in AX at every output function 
		do a better numberInProgress and sign storage 
		OutputDirection() - don't need to get final angle between 0 and 359, also beginning thing, you can just subtract 360 from 
					numberInProgress, don't need to mod it
		see if it works ok when you set the number of st_error to the same number as st_initial 
		use motor.inc to not duplicate constants 
		
6 	motors.asm: 
		MotorEventHandler: don't do the +1 thing, NEG already does it for you 
		reconstruct motorOutVal every time so no need to store 
		try out set turret elevation! 
		ChangeSpeed() - don't divide by 2 before storing robotSpeed 
		fix frequency for timer 

	ALL:
	
1 	update functional specification LOL -------------- do this at end! 
		
		
CODE    ENDS

; will be put with the other parse functions later
GetParseErrorStatus 	PROC 	NEAR 
						PUBLIC 	GetParseErrorStatus
	MOV 	AX, errorStatus 
	RET 
GetParseErrorStatus		ENDP 





; the data segment 

DATA        SEGMENT     PUBLIC      'DATA'

    eventQueue   qStruc      < >                

    DATA        ENDS



;the stack

STACK   SEGMENT STACK  'STACK'

        DB      80 DUP ('Stack ')       ;240 words

        TopOfStack      LABEL   WORD

STACK   ENDS



        END         START

	
            
START:  

MAIN: (pseudocode)
	
InitSystem: 

	
CheckForErrors: 
	Check Parse Errors: 
		if true, then send parse error through serial to display 
	Check Serial Errors 
		if true, then send serial error through serial to display
	Check Critical Errors 
		if true, then rerun initialization code and start over 
	
HandleMotorEvents: 
	CALL 	DequeueEvent 		; blocking function, stays here until executed
	HandleMotorEvents(AX)

END 


; For this outline, the functions included are: 
; 	SendMotorFeedback - creates string describing motor status to remote unit
; 	HandleMotorEvents - handles serial characters received by motor unit
; 	SendMotorError - sends parse and serial errors to remote unit to display
;	MakeString - concatenates passed in values to a stringInProgress variable
; 	SerialPutString - puts string in serial channel for transmission
; 	These will be in separate file partitions later on.


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
	
	
	
;
; SerialPutString
;
;
; Description:  	This function takes a string at a memory location, and sends 
; 					it through the serial channel. 
;
; Operation:    	We are passed the address of the first character in the string, 
; 					and we loop through the entire string by incrementing the
; 					pointer. At each character we point to, we call SerialPutChar 
; 					on that character. We stop looping when we reach the <NULL> 
; 					character, which is how strings in our system are ended. 
;	
; Arguments:        SI - address of string to be sent through serial channel.
; Return Value:     None. 
;
; Local Variables:  None. 
; Shared Variables: None. 
; Global Variables:	None.
; 
; Input:            None.
; Output:           String is passed through serial channel. 
;
; Error Handling: 
; Registers Used: 
; Algorithms: 		None. 
; Data Structures:  None.

SerialPutString		PROC 	NEAR 
					PUBLIC 	SerialPutString

GetCharacter: 
	MOV 	AL, DS:[SI]
	CALL 	PutSerialChar 
	JC 		HandleTransmitQueueFullError 
	;JNC 	CheckNullTermination
CheckNullTermination: 
	CMP 	AL, ASCII_NULL 
	JE 		EndSerialPutString
	;JNE 	GetNextCharacterToPutSerialChar:
GetNextCharacterToPutSerialChar: 
	INC 	SI 
	JMP 	GetCharacter
	
HandleTransmitQueueFullError: 
	MOV 	AX, 0005H 		; or whatever value corresponds to a transmit queue full error 
	CALL 	HandleErrorEvent
	JMP 	EndSerialPutString 

EndSerialPutString:
	RET 
SerialPutString		ENDP 