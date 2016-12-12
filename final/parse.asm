	NAME 	PARSE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;  			     	   Robotrike Serial Parsing Routines                     ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; The functions included in this file will parse the passed character c as part
; of a serial command. These functions are the parsing functions for the 
; Robotrike. Using a finite state machine, these functions will be able to parse
; an input string of commands passed to it, and execute the appropriate procedures
; associated with each command. 
; 
; The functions included are: 
; 
; Public functions: 
; 	ParseSerialChar(c) - parses the passed character c as part of serial command
;   InitializeStateMachine - initializes state machine to start at initial state,
;                           resets the shared variables 
; Local functions: 
; 	GetSerialToken (c) - looks up the value and type of an input token for parser
; 	ResetSharedVariables - clears shared variables when a commmand is complete
; 	ErrorHandler - resets shared variables and sets error flag when error occurs
; 	DoNOP - does nothing; placeholder function for no-operation state transitions
;	SetSign - stores the sign of a number if a sign symbol (+ or -) is input 
; 	NewDigit(n) - adds a new digit to the number so a complete number can be read 
; 				  after command return is issued 		
;
; Output functions:  	
; 	OutputSpeed - outputs the absolute speed to motor routines using SetMotorSpeed
; 	OutputRelSpeed - outputs the relative speed to motor routines using SetMotorSpeed 
; 	OutputDirection - outputs the direction to the motor routines using SetMotorSpeed
; 	OutputTurretRotation - outputs turret rotation using SetTurretAngle 
; 	OutputRelTurretRotation - outputs relative turret rotation using SetRelTurretAngle
; 	OutputTurretElevation - outputs the turret elevation using SetTurretElevation 
; 	OutputLaserOn - calls the SetLaser function to turn laser on
; 	OutputLaserOff - calls the SetLaser function to turn laser off 
; 	
;
; After speed, direction, or turret elevation is changed, the output function will 
; call SendSerialUpdatedDirection, SendSerialUpdatedTurretElevation, or 
; SendSerialUpdatedSpeed to send a display string through the serial channel for the 
; remote unit to display the new changes made to the Robotrike's movement. Laser 
; status will not be displayed on the screen since that is easily seen. 
; 
; The tables included in this file describe the tokens, states, and transitions that
; make up this parsing finite state machine. Included tables: 
; 	TokenTypeTable - defines the category for each possible ASCII value 
; 	TokenValueTable - defines the value of each ASCII value (all possible tokens)
; 	StateTable - defines currentState to nextState transitions and action functions
;
;
; Revision History:
;     11/24/16  	Jennifer Du      initial revision
; 	  11/26/16 		Jennifer Du 	 debugged code 
; 	  11/27/16 		Jennifer Du 	 wrote comments 
; 	  12/08/16 		Jennifer Du 	 added serial string outputs to output functions
;     12/10/16      Jennifer Du      changed <null> token type 


; include files
 
$INCLUDE(macros.inc)		; commonly used macros and procedures 
$INCLUDE(parse.inc)			; constants required for parser 
$INCLUDE(uievents.inc)      ; constants used for event identifying and handling        

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP
        
; external function declarations 

	; all these functions are for outputting complete commands 
    EXTRN   SetMotorSpeed:NEAR			; set motor speed 
    EXTRN   GetMotorSpeed:NEAR			; get current motor speed 
    EXTRN   GetMotorDirection:NEAR		; get current motor direction (degree angles)
    EXTRN   SetLaser:NEAR				; set laser to on or off 
    EXTRN   GetLaser:NEAR				; get laser status (on or off)
    EXTRN   SetTurretAngle:NEAR			; set turret's angle of rotation 
    EXTRN   SetRelTurretAngle:NEAR		; set relative turret angle of rotation
    EXTRN   GetTurretAngle:NEAR			; get current turret angle of rotation
    EXTRN   SetTurretElevation:NEAR		; set turret elevation (degree angles)
    EXTRN   GetTurretElevation:NEAR		; get current turret elevation 

    ; these functions are used in the serial send string functions 
    EXTRN   MakeString:NEAR             ; concatenate characters to stringInProgress
    EXTRN   SendSerialUpdatedDirection:NEAR 
    EXTRN   SendSerialUpdatedSpeed:NEAR 
    EXTRN   SendSerialUpdatedTurretElevation:NEAR 
    
    EXTRN   EnqueueEvent:NEAR 

;
; ParseSerialChar
;
; Description:      The function is passed a character (c) from the serial input,
;					by value in AL. This character will be processed as a serial 
; 					command. The function returns the status of the parsing 
; 					operation in AX. Zero (0) is returned if there are no parsing 
; 					errors due to the passed character and a non-zero value is 
; 					returned if there is a parsing error due to	the passed character.
; 					This function takes in one character, parses it, and executes 
; 					any commands the character completes. 
;
; Operation:        This function uses a state machine to parse the input character. 
; 					The function looks up the character's token type and value from
; 					the TokenTypeTable and the TokenValueTable. From that, the 
; 					location of the transition in the StateTable is calculated. Then,
; 					the transition from the current state to the next is made. The 
; 					function associated with the transition is called. If 
; 					ParseSerialChar ends at an error state, the next ParseSerialChar 
; 					call will start at the initial state. At an error state, AX will 
; 					hold a non-zero value indicating an error, but will hold zero 
; 					otherwise, to signify there were no errors during parsing. 
;
; Arguments:        c (AL) - character to be parsed as part of a serial command.
; Return Value:     AX - error status of parsing - 0 if none, non-zero if errors occurred
;
; Local Variables:  BX - pointer to state transition table
; 					CL - current state we are in 
;                   
; Shared Variables: currentState (R/W) - keeps track of what state the previous 
;								character left us at 
;                   parseErrorStatus (R/W) - keeps track of whether an error occurred 
; 								during parsing. 							
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   If the passed character does not hold a valid value, then a 
; 					nonzero value is returned in AX. If a character causes an illegal
; 					or invalid command to be attempted, an error will arise and AX 
; 					be set to the error-indicating value. 
;
; Algorithms:       Finite State Machine.
; Data Structures:  None.
; 
; Registers Used: 	AX, BX, CX, DX.
; Stack Depth: 		1 word. 
; 													

ParseSerialChar		PROC    NEAR
					PUBLIC  ParseSerialChar
					
InitParsing:				;setup the state machine
	
	MOV		CL, currentState					;start in the stored current state
												; (where we left off)
    MOV     parseErrorStatus, NO_PARSE_ERROR_VAL   	; reset error flag  
	
GetToken:							; get next input for state machine
	
	CALL	GetSerialToken			; get the token type and value
									; token type in AH, character in AL
	MOV		DH, AH		; token type	;and save them in DH and CH
	MOV		CH, AL      ; character     

ComputeTransition:					; figure out what transition to do
	MOV		AL, NUM_TOKEN_TYPES			; find row in the table
	MUL		CL							; AX is start of row for current state
	ADD		AL, DH						; get the actual transition
	ADC		AH, 0						; propagate low byte carry into high byte

	IMUL	BX, AX, SIZE TRANSITION_ENTRY   ; now convert to table offset
	
DoActions:				; do the actions (don't affect regs)
	MOV		AL, CH			; get token value back for actions
	PUSH    BX 				; save index so action doesn't affect it
    CALL	CS:StateTable[BX].ACTION1	; do the action (either error, 
										; or an action that triggers possible error)
	
DoTransition:						;now go to next state
    POP     BX 						; restore index 
	MOV		CL, CS:StateTable[BX].NEXTSTATE		; move next state into register 
    MOV     currentState, CL 					; store next state as new current state
    
CheckForError:						; after action, check for error with error flag
	CMP 	parseErrorStatus, PARSE_ERROR_VAL 	
	JNE 	NoParseError				; if flag not set, no parse error, return 
	JE 	    HandleError					; if flag is set, parse error occurred 
	
NoParseError:						; no parse error:
	MOV 	AX, NO_PARSE_ERROR_VAL		; move no-error value into AX for return 
	JMP 	EndParseSerialChar			; and end function 
	
HandleError:  						; parse error occurred: 
    MOV     AX, PARSE_ERROR_VAL 		; move error value into AX for return 
    MOV     currentState, ST_INITIAL	; return to initial state to take in new input
	;JMP 	EndParseSerialChar

EndParseSerialChar:				;done parsing character, return 
    RET
ParseSerialChar		ENDP
	
	
	
;	
; InitializeStateMachine 
;
; Description: 		This function initializes the state machine by setting the 
; 					beginning state to ST_INITIAL, the state which is essentially
; 					the idle state that can handle the most inputs and direct each
; 					input into their specific state. It also sets the sign variable 
; 					to +1, the number in progress variable to 0, and the error flag 
; 					to FALSE.
; 
; Operation: 		This function sets the numberInProgress to 0, resets the error 
; 					flag (parseErrorStatus), and sets the sign variable to positive 1. 
; 					It also sets the currentState variable to ST_INITIAL, so the 
; 					state machine can take the start of any command as input.
;
; Arguments:		None.
; Return Value:		None.
;
; Local Variables:	None. 
; Shared Variables: currentState (W) - keeps track of what state we are at in the 
; 							state machine after parsing the latest token. 
; Global Variables: None.
; Input:			None. 
; Output:			None.
; 
; Error Handling:	None.
; Algorithms:		None. 
; Data Structures: 	None. 
;
; Registers Used: 	None.
; Stack Depth: 		0 words. 
;

InitializeStateMachine	PROC 	NEAR 
                        PUBLIC  InitializeStateMachine
                        
    MOV     currentState, ST_INITIAL		; start off in initial/idle state 
	
    CALL    ResetSharedVariables			; reset all shared variables for
											; new commands     
	RET
InitializeStateMachine	ENDP 



;
; GetSerialToken
;
; Description:      This procedure returns the token class and token value for
;                   the passed character.  The character is truncated to
;                   7-bits.
;
; Operation:        Looks up the passed character in two tables, one for token
;                   types or classes, the other for token values.
;
; Arguments:        AL - character to look up.
; Return Value:     AL - token value for the character.
;                   AH - token type or class for the character.
;
; Local Variables:  BX (R/W) - table pointer, points at lookup tables.
; 					AX (W) - token type (AH) and value (AL)
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
;
; Algorithms:       Table lookup.
; Data Structures:  Two tables, one containing token values and the other
;                   containing token types.
;
; Registers Used: 	AX, BX. 
; Stack Depth: 		0 words. 
;	

GetSerialToken	PROC    NEAR

InitGetSerialToken:					;setup for lookups
	AND	    AL, TOKEN_MASK				;strip unused bits (high bit)
	MOV	    AH, AL						;and preserve token character in AH

TokenTypeLookup:                    ;get the token type
    MOV     BX, OFFSET(TokenTypeTable)  ;BX points at table
	XLAT	CS:TokenTypeTable			;have token type in AL
	XCHG	AH, AL						;token type in AH, character in AL

TokenValueLookup:					;get the token value
    MOV     BX, OFFSET(TokenValueTable)  ;BX points at table
	XLAT	CS:TokenValueTable			;have token value in AL

EndGetSerialToken:                     	;done looking up type and value
    RET
GetSerialToken	ENDP


;	
; ResetSharedVariables
;
; Description: 		This function is called when a command is finished, and the 
; 					system returns to waiting for a new command. It is also called
; 					when an error occurs. It clears all the variables associated 
; 					with the previous command that was issued so that when a new 
; 					command comes in, we can begin to parse the input without having
; 					to overwrite old information, which can lead to errors. 
; 
; Operation: 		This function sets the numberInProgress variable to 0 and the 
; 					sign variable to 0. It also resets the error flag.
;
; Arguments:		None.
; Return Value:		None.
;
; Local Variables:	None. 
; Shared Variables: sign (W) - tells us if a number associated with a command is to 
; 							be interpreted as negative or positive
; 					numberInProgress (W) - variable holding the number being formed
; 							by successive number tokens
;                   parseErrorStatus (W) - error flag tells us whether there was an error
; Global Variables: None.
;
; Input:			None. 
; Output:			None.
; 
; Error Handling:	None.
; Algorithms:		None. 
; Data Structures: 	None. 
;
; Registers Used: 	None.
; Stack Depth: 		0 words. 
;

ResetSharedVariables	PROC 	NEAR 
	
	MOV 	sign, POS_SIGN_VAL		; default sign is positive 
	MOV 	numberInProgress, 0		; start off with 0 as number so we can add to it
	MOV 	parseErrorStatus, NO_PARSE_ERROR_VAL 			
                                    ; start with no error (nonzero when error occurs)
	RET
ResetSharedVariables	ENDP 
	
	
;
; ErrorHandler 
;
; Description:      This procedure is called when an error occurs. It sets the
; 					error flag. Then, later on, we can refer to the error flag 
; 					to see if any errors arose during the parsing of a specific 
; 					character.
;
; Operation:        This function sets the error flag and resets the shared 
; 					variables. 
;
; Arguments:        None. 
; Return Value:     None.
;
; Local Variables:  None.
; Shared Variables: parseErrorStatus (W) - error flag tells us whether there was an error
;	 						during parsing or during attempted output 
; 				
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
;
; Algorithms:       None. 
; Data Structures:  None.
;
; Registers Used: 	None.
; Stack Depth: 		0 words. 
;

ErrorHandler 	PROC 	NEAR 

    CALL    ResetSharedVariables			; reset shared variables 
	MOV 	parseErrorStatus, PARSE_ERROR_VAL	; but set error flag 
    MOV     AH, ERROR_VAL       ; this is the error event identifier 
    MOV     AL, PARSE_ERROR_VAL 
    CALL    EnqueueEvent 
    
	RET 
ErrorHandler	ENDP 
	
	

;	
; DoNOP  
;
; Description: 		This function is called when no operation should be performed
; 					and no error handling is needed. 
; 
; Operation: 		We simply do no operation, and return. 
;
; Arguments:		None.
; Return Value:		None.
;
; Local Variables:	None. 
; Shared Variables: None.
; Global Variables: None.
;
; Input:			None. 
; Output:			None. 
;
; Error Handling:	None.
; Algorithms:		None. 
; Data Structures: 	None. 
;
; Registers Used: 	None.
; Stack Depth: 		0 words. 
;
	
DoNOP 	PROC 	NEAR 
	
	NOP 		; do nothing 
	RET 		; return 
DoNOP 	ENDP 	



;	
; SetSign   
;
; Description: 		This function is called when a sign symbol is received by the 
; 					parser. It stores the value so that we can remember whether the 
; 					subsequently parsed number is supposed to be positive or 
; 					negative. 
; 
; Operation: 		This function either takes a + or a - symbol. It stores the 
; 					value in the sign variable: if the symbol is a +, then the 
; 					sign variable is set to 1 (unsigned). If the symbol is a -, then
; 					the sign variable is set to -1. This will be used in conjunction
; 					with the stored number to parse the command. 
;
; Arguments:		AL - the sign symbol to be parsed 
; Return Value:		None.
;
; Local Variables:	None. 
; Shared Variables: sign (W) - tells us if a number associated with a command is  
; 							negative or positive. 
; Global Variables: None.
;
; Input:			None. 
; Output:			None. 
;
; Error Handling:	A no-error value is returned in AX to indicate no errors.
; Algorithms:		None. 
; Data Structures: 	None. 
;
; Registers Used: 	AL.
; Stack Depth: 		0 words. 
;

SetSign 	PROC 	NEAR

DetectSign: 
	CMP 	AL, '+'             		; compare input symbol to '+'
	JE 		PositiveSign				; if equal, input is positive sign
	JNE 	NegativeSign 				; if not, input is negative sign 

PositiveSign: 	
	MOV 	sign, POS_SIGN_VAL 			; set sign = positive 1 as multiplier
    MOV     AL, NO_PARSE_ERROR_VAL
    JMP     EndSetSign 					; end function 
NegativeSign: 
	MOV 	sign, NEG_SIGN_VAL 			; or, set sign = negative 1 as multiplier
    MOV     AL, NO_PARSE_ERROR_VAL
    ; JMP     EndSetSign 				
EndSetSign: 							; return to SerialParseChar
	RET 
SetSign 	ENDP



;	
; NewDigit   
;
; Description: 		This function is called when the new token received is a 
; 					numerical value. This function adds the new token value to
; 					the number buffer. 
; 
; Operation: 		Multiply the current value of the number by 10, and then 
; 					add the passed in value associated with the ASCII number 
; 					character (n). We do this for positive as well as negative 
; 					cases, depending on the value stored in the sign variable, 
; 					so we can see if the number overflows. Multiplying the current 
; 					number by 10 will shift all the digits left, so that the one's
; 					digit is left as 0. This will provide the spot that the new 
; 					number will be added to. 
;
; Arguments:		n - the ASCII value of the number passed in.
; Return Value:		None.
;
; Local Variables:	CX - signed value of numberInProgress 
; 					AX - number to be added to the end of numberInProgress 
; Shared Variables: numberInProgress (R/W) - variable holding the number being formed 
; 									by successive number tokens.
; 					sign (W) - tells us if the number associated with a command is to
; 							be interpreted as negative or positive. 
; Global Variables: None.
;
; Input:			None. 
; Output:			None. 
;
; Error Handling:	If there is overflow after multiplying the numberInProgress by
; 					the sign, multiplying by 10, or adding the new digit, then we 
; 					handle the error by calling the ErrorHandler function. 
; Algorithms:		None. 
; Data Structures: 	None. 
; 
; Registers Used: 	AX, CX.
; Stack Depth: 		0 words. 
;

NewDigit 	PROC 	NEAR 


CheckSignForNewNumber: 	
    MOV     AH, 0 
    CMP     sign, POS_SIGN_VAL					; handle negative numbers and 
												; positive numbers separately
    JE      AddNewDigitForPositiveNumber		; if positive, jump to positive handler
    ;JNE     AddNewDigitForNegativeNumber
    
AddNewDigitForNegativeNumber: 
												; if negative, get negative value 
    IMUL    CX, numberInProgress, NEG_SIGN_VAL 		;of numberInProgress
    JO      HandleNewDigitOverflowError 		; check/handle overflow here
    
    IMUL    CX, CX, 10 							; multiply negative val by 10 
												; to shift all decimal digits left
    JO      HandleNewDigitOverflowError 		; check/handle overflow again 
    
    SUB     CX, AX 								; subtract (add negative) new digit
												; to add new digit in 1's place 
    JO      HandleNewDigitOverflowError 		; check/handle overflow again 
    
    IMUL    CX, CX, NEG_SIGN_VAL 				; make positive again (get magnitude)
    MOV     numberInProgress, CX				; update numberInProgress
    MOV     AX, NO_PARSE_ERROR_VAL
    JMP     EndNewDigit 						; end function 
	
AddNewDigitForPositiveNumber: 					; for positive case: 
	
	IMUL 	CX, numberInProgress, 10 			; multiply numberInProgress by 10 
												; shift all decimal digits left 
	JO 		HandleNewDigitOverflowError 		; check/handle overflow 
    
	ADD 	CX, AX 								; add new digit in 1's place
	JO 		HandleNewDigitOverflowError			; check/handle overflow 
												; if no overflow:
    MOV     numberInProgress, CX 				; update current number and return 
    MOV     AX, NO_PARSE_ERROR_VAL
    JMP     EndNewDigit 
	
HandleNewDigitOverflowError: 					; reached if overflow error occurs 
	CALL 	ErrorHandler						; sets error flag 
	
EndNewDigit: 

    
	RET 										; return 
NewDigit	ENDP 




;	
; OutputSpeed
;
; Description: 		This function is called when an S# command is issued. It sends
; 					the values associated with the command to the SetMotorSpeed 
; 					function to update the motors' speed.
; 
; Operation: 		This takes the shared variables storing the current number and 
; 					any indicated signage, and passes these arguments into the 
; 					SetMotorSpeed function defined in the motor routines. This 
; 					function also sends an angle hold value to SetMotorSpeed since 
; 					the S# command does not change the angle, but SetMotorSpeed 
; 					requires two arguments. 
;
; Arguments:		None.
; Return Value:		AX - error status (0 if no error, 1 if error).
;
; Local Variables:	None. 
; Shared Variables: sign - tells us if a number associated with a command is to be 
; 							interpreted as negative or positive. 
; 					numberInProgress - variable holding the number being formed 
; 							by successive number tokens
; Global Variables: None.
; 
; Input:			None. 
; Output:			Sends values to SetMotorSpeed and causes motors to change speed. 
; 
; Error Handling:	If an input speed is negative, then this is considered an 
; 					invalid command. In this case, the error handler is called, and 
; 					a non-zero value is put into AX. 
; Algorithms:		None. 
; Data Structures: 	None. 
;
; Registers Used: 	AX, BX.
; Stack Depth: 		0 words. 
;

OutputSpeed 	PROC 	NEAR 
PUSHA 
PUSHF
CLI
CheckNegativeAbsSpeedInput: 				
	CMP 	sign, POS_SIGN_VAL				; check attempted negative input:
	JNE 	HandleOutputSpeedNegativeVal 		; if negative, handle error here
	JE 		PopulateOutputSpeedArgs				; if positive, call SetMotorSpeed
	
HandleOutputSpeedNegativeVal: 				; negative input error: 
	CALL 	ErrorHandler					; handle error
	JMP 	EndOutputSpeed 					; end function 
				
PopulateOutputSpeedArgs: 			; if valid input: 
	MOV 	AX, numberInProgress			; populate SetMotorSpeed argument fields
	MOV 	BX, HOLD_ANGLE_VAL 		; no angle change; this function only changes speed
	CALL 	SetMotorSpeed			; call function 
    
    CALL    SendSerialUpdatedSpeed 
    
    CALL    ResetSharedVariables
	MOV 	AX, NO_PARSE_ERROR_VAL 	; move no-error value into AX for return 
	
EndOutputSpeed: 
POPF
POPA
	RET 
OutputSpeed 	ENDP 


;	
; OutputRelSpeed
;
; Description: 		This function is called when a V# command is issued. It sends
; 					the values associated with the command to the SetMotorSpeed 
; 					function to update the motors' speed, after adding the relative
; 					speed to the current speed. 
; 
; Operation: 		This function uses the sign variable and the numberInProgress 
; 					variable to determine whether the current motor speed should be 
; 					increased or decreased. Then, it gets the current motor speed
; 					and adds the relative speed to it, and then passes this updated
; 					value to the SetMotorSpeed function. An angle hold value is also
; 					sent to this function because the angle is not changed here. 
;
; Arguments:		None.
; Return Value:		AX - error status (0 if no error, 1 if error).
;
; Local Variables:	AX - total speed (current speed added to relative change)
; 					BX - angle value to be passed into SetMotorSpeed 
; Shared Variables: sign - tells us if a number associated with a command is to be 
; 							interpreted as negative or positive. 
; 					numberInProgress - variable holding the number being formed 
; 							by successive number tokens
; Global Variables: None.
; 
; Input:			None. 
; Output:			Updates current motor speed.
; 
; Error Handling:	This function does not return an error. If the value of the 
; 					total speed overflows or underflows, the speed is simply 
; 					truncated to the maximum or minimum motor speed, and no 
; 					error val is returned in AX. 
; Algorithms:		None. 
; Data Structures: 	None. 
;
; Registers Used: 	AX, BX, CX.
; Stack Depth: 		0 words. 
;

OutputRelSpeed		PROC 	NEAR 

PUSHA
PUSHF
CLI

    MOV     CX, numberInProgress
GetCurrentMotorSpeed: 
	CALL 	GetMotorSpeed 				; current speed of robot returned in AX 
	
GetRelMotorSpeedSign: 					; sign indicates positive/negative speed change
    CMP     sign, POS_SIGN_VAL 			; compare positive or negative signs 
    JE      AddRelSpeed						; to identify adding speed (+)
    JNE     SubRelSpeed						; or subtracting speed (-)

AddRelSpeed: 
    ADD     AX, CX 						; if positive change in speed, simply add 
    ;JMP     CheckPosRelSpeedOutOfBounds
    
CheckPosRelSpeedOutOfBounds: 			; if added speed, 
    JC      MakeMaxSpeed 				; check speed out of bounds value 
    ;JMP     CheckEqualToHoldSpeedVal 	; if speed out of bounds, set speed=max speed
										; if not, then check other special conditions
   
CheckEqualToHoldSpeedVal:				; if added speed, the total speed might be 
										; the  designated no-speed-change argument 
    CMP 	AX, HOLD_SPEED_VAL				; if speed != speed_no_change:  
    JNE     PopulateSetRelMotorSpeedArgs	; speed is in bounds, not special case 
											; so call set motor speed function 
    ;JE     do this: 					; if speed = speed_no_change val: 
MakeMaxSpeed:     						; round down to make speed = max_speed
    MOV     AX, MAX_MOTOR_SPEED 			; set speed = max_speed 
    JMP     PopulateSetRelMotorSpeedArgs	; then call set motor speed function
    
SubRelSpeed:    
    SUB     AX, CX 						; if negative change in speed, 
    ;JMP     CheckTotalSpeedNegative	; subtract from negative val
    
CheckTotalSpeedNegative: 
    JNC     PopulateSetRelMotorSpeedArgs	; if carry flag not set, then value is 
											; in bounds, so set motor speed now

    MOV     AX, MIN_MOTOR_SPEED  			; if carry flag is set, then value is 
    ;JMP    PopulateSetRelMotorSpeedArgs	; out of bounds. make speed = min_speed

PopulateSetRelMotorSpeedArgs: 
	MOV 	BX, HOLD_ANGLE_VAL			; populate the angle value, AX will already 
										; be holding the appropriate total speed
	CALL 	SetMotorSpeed				; set motor speed with no angle change
    CALL    SendSerialUpdatedSpeed 
    CALL    ResetSharedVariables
	MOV 	AX, NO_PARSE_ERROR_VAL 		; set AX to no-error value to return 
    JMP     EndOutputRelSpeed 			; end function after successfully setting speed

EndOutputRelSpeed:
POPF
POPA
	RET 								; end function
OutputRelSpeed      ENDP 


;	
; OutputDirection 
;
; Description: 		This function is called when a D# command is issued. It sends
; 					the values associated with the command to the SetMotorDirection
; 					function to update the robot's direction.
; 
; Operation: 		This function uses the sign variable and the numberInProgress 
; 					variable to determine what angle the Robotrike should move at. 
; 					All angles are relative. This function calls the motor routine
; 					GetMotorDirection, and adds the angle specified. Then it passes 
; 					the updated value to the SetMotorSpeed function with a hold 
; 					speed value as the speed, since the speed is not being updated.
;
; Arguments:		None.
; Return Value:		AX - error status (0 if no error, 1 if error).
;
; Local Variables:	AX - stores current direction of robot. 
; 					DX - value of input angle, mod 360 
; Shared Variables: sign (R) - tells us if the input direction change angle is 
; 								positive or negative. 
; 					numberInProgress (R) - variable holding the desired direction
; 								change, in angles 
; Global Variables: None.
;
; Input:			None. 
; Output:			Updates current motor direction when SetMotorSpeed is called.
; 
; Error Handling:	A no-error value will be returned in AX.
; Algorithms:		None. 
; Data Structures: 	None. 
;
; Registers Used: 	AX, CX, DX.
; Stack Depth: 		0 words. 
;

OutputDirection 	PROC 	NEAR 
PUSHA
PUSHF
CLI
GetDirectionAngleInBounds: 				; get input angle within 0 and 360
	%CLR(DX)							; clear DX before division
	MOV 	AX, numberInProgress		; divide input angle by 360 and 
	MOV 	CX, 360            ; take remainder as new angle
	DIV 	CX 							; remainder: AX (mod 360) is in DX 													
								
GetCurrentDirection: 					; get current direction, 
	CALL 	GetMotorDirection				; stored in AX 
													
GetDirectionAngleSign: 					; get sign of direction angle change 
    CMP     sign, POS_SIGN_VAL 			; if sign is positive:
    MOV     CX, DX 							; move angle change into CX 
    JE      UpdateOutputDirection			; continue updating output direction
										; if sign is negative: then IMUL with -1,
	IMUL 	CX, DX, NEG_SIGN_VAL  			; compute signed relative angle 
	;JMP 	UpdateOutputDirection			; before updating output direction 
	
UpdateOutputDirection:
	ADD 	AX, CX						; add current direction (AX) + rel angle (CX)
    
    CMP     AX, 0						; see if sum angle is positive or negative 
    JGE     PositiveRelDirectionAngle	; if positive angle: (may be greater than 360)
    
    ADD     AX, TOTAL_DEGREES			; if negative angle: 
										; angle will be between -360 and -1, so add 360
										; to angle to get it between 0 and 359
										
PositiveRelDirectionAngle: 				; may be greater than 360, so mod it 360
	%CLR(DX)							; DX cleared before division 
	MOV 	CX, 360       	; divide AX by total number of degrees (360)
	DIV 	CX 								; to get angle between 0 and 360 
	MOV 	AX, DX 						; move remainder to AX 
	
PopulateChangeDirectionArgs:
	MOV 	BX, AX						; move angle to change by into BX 
	MOV 	AX, HOLD_SPEED_VAL			; move no-speed-change value into AX 
	CALL 	SetMotorSpeed				; args are populated, call SetMotorSpeed
    CALL    SendSerialUpdatedDirection
    CALL    ResetSharedVariables
	MOV 	AX, NO_PARSE_ERROR_VAL 		; move no-error value to AX to return 

POPF
POPA     
	RET 
OutputDirection 	ENDP 


;	
; OutputTurretRotation   
;
; Description: 		This function is called when a T command is issued. It calls
; 					the SetTurretAngle function defined in the motor routines to 
; 					rotate the laser turret to the absolute angle as specified in 
; 					the command. 
; 
; Operation: 		This takes the shared variables storing the current number and 
; 					passes this argument into the SetTurretRotation function defined
; 					in the motor routines. This function is called when we receive a
; 					command of the form T#, without a sign. This function sets the 
; 					absolute angle of the laser turret. 
;
; Arguments:		None.
; Return Value:		AX - error status (0 if no error, 1 if error).
;
; Local Variables:	None.
; Shared Variables: numberInProgress (R) - desired turret rotation angle.
; Global Variables: None.
;
; Input:			None. 
; Output:			Rotates laser turret when SetTurretAngle is called.  
;
; Error Handling:	A no-error value is put into AX to be returned. 
; Algorithms:		None. 
; Data Structures: 	None. 
;
; Registers Used: 	AX.
; Stack Depth: 		0 words. 
;

OutputTurretRotation		PROC 	NEAR 

	MOV 	AX, numberInProgress		; populate argument for SetTurretAngle
										; (must be unsigned)
	CALL 	SetTurretAngle              ; send argument to SetTurretAngle function  
    CALL    ResetSharedVariables
	MOV 	AX, NO_PARSE_ERROR_VAL 		; return no-error value in AX 

	RET
OutputTurretRotation		ENDP 


	
;	
; OutputTurretRelRotation   
;
; Description: 		This function is called when a T# command is issued. It calls
; 					the SetTurretAngle function defined in the motor routines to 
; 					rotate the laser turret to the relative angle as specified in 
; 					the command. 
; 
; Operation: 		This takes the shared variables storing the current number and 
; 					any indicated signage, and passes these arguments into the 
; 					SetRelTurretRotation function defined in the motor routines. This 
; 					function sets the relative angle (positive or negative) of the 
; 					laser turret, with a lower bound of 0 degrees and an upper 
; 					bound of 360 degrees. 
;
; Arguments:		None.
; Return Value:		AX - error status (0 if no error, 1 if error).
;
; Local Variables:	None.
; Shared Variables: numberInProgress (R) - desired relative turret rotation value
; 					sign (R) - determines adding or subtracting turret angle from
; 							current turret rotation angle 
; Global Variables: None.
;
; Input:			None. 
; Output:			Rotates laser turret when SetRelTurretAngle is called.  
; 
; Error Handling:	A no-error value will be moved into AX to return. 
; Algorithms:		None. 
; Data Structures: 	None. 
;
; Registers Used: 	AX.
; Stack Depth: 		0 words. 
;



OutputTurretRelRotation		PROC 	NEAR 
PUSHA
PUSHF
CLI
GetTurretRelAngle: 
	MOV 	AX, numberInProgress		; get value of desired rotation
							
GetSignOfTurretRelAngle: 				; get sign of desired rotation 
    CMP     sign, POS_SIGN_VAL 			; if sign is positive, we make no change
    JE      CallSetRelTurretAngle			; to angle before calling set function
										; if sign is negative, IMUL angle by -1 
	IMUL 	AX, AX, NEG_SIGN_VAL 			; to get negated angle in AX 
	;JMP 	CallSetRelTurretAngle			; before calling set function 
   
CallSetRelTurretAngle:
	CALL 	SetRelTurretAngle 			; call SetRelTurretAngle with +AX or -AX arg
    CALL    ResetSharedVariables
	MOV 	AX, NO_PARSE_ERROR_VAL 		; move no-error value into AX for return 
	
POPF
POPA
	RET
OutputTurretRelRotation		ENDP 



;	
; OutputTurretElevation 
;
; Description: 		This function is called when an E# command is issued. It calls
; 					the SetTurretElevation function defined in the motor routines to
; 					set the angle of elevation of the turret.  
; 
; Operation: 		This takes the shared variables storing the current number and 
; 					any indicated signage, and passes these arguments into the 
; 					SetTurretElevation function defined in the motor routines. This 
; 					function sets the absolute angle of elevation (positive or 
; 					negative) of the laser turret, with a lower bound of -60 degrees
; 					and an upper bound of 60 degrees with respect to the horizontal. 
; 					If the argument exceeds these bounds, an error value will be 
; 					returned. 
; 
; Arguments:		None.
; Return Value:		AX - error status (0 if no error, 1 if error).
;
; Local Variables:	None.
; Shared Variables: numberInProgress (R) - desired absolute angle of turret elevation
; 					sign (R) - indicates negative or positive angle with respect to
; 							horizontal 
; Global Variables: None.
; 
; Input:			None. 
; Output:			Raises or lowers laser to change angle of elevation when 
; 					SetTurretElevation is called. 
; 
; Error Handling:	If the desired angle of elevation is out of bounds, then we will 
; 					return with an error value in AX and call the ErrorHandler. 
; Algorithms:		None. 
; Data Structures: 	None. 
;
; Registers Used: 	AX.
; Stack Depth: 		0 words. 
;

OutputTurretElevation		PROC 	NEAR

PUSHA
PUSHF
CLI
CheckTurretElevationInBound:
    MOV     AX, numberInProgress			; numberInProgress is unsigned, and holds
											; just the magnitude of desired elevation
	CMP 	AX, MAX_TUR_ELV_VAL				; compare magnitude to maximum val 
	JG		InvalidTurretElevation			; if greater than max value, this is an 
											; invalid command 
	;JLE 	ProcessTurretElevationAngle		; if not, continue to set elevation angle

ProcessTurretElevationAngle: 				; desired elevation is in bounds 
    CMP     sign, POS_SIGN_VAL 				; if elevation is positive, 
    JE      CallSetTurretElevation				; simply set turret elevation 
											; if elevation is negative, 
	IMUL 	AX, numberInProgress, NEG_SIGN_VAL	; multiply elevation by negative sign
												; before setting turret elevation 
CallSetTurretElevation: 
	CALL 	SetTurretElevation				; argument value is already in AX 
    CALL    SendSerialUpdatedTurretElevation
    CALL    ResetSharedVariables
	
	MOV 	AX, NO_PARSE_ERROR_VAL 			; after calling setting function, move 
											; no-error value into AX to return 
	JMP 	EndOutputTurretElevation 		; then end the function 
	
InvalidTurretElevation:						; if elevation angle > maximum angle:
	CALL 	ErrorHandler 					; handle error without setting elevation
	;JMP 	EndOutputTurretElevation		; and end 
	
EndOutputTurretElevation: 
POPF
POPA
	RET 
OutputTurretElevation		ENDP 

	
	
;	
; OutputLaserOn  
;
; Description: 		This function is called when an F command is issued, without 
; 					any other tokens after it. It calls	the SetLaser function 
; 					defined in the motor routines to turn on (fire) the laser. 
; 
; Operation: 		This function calls the SetLaser function with an ON command.
;
; Arguments:		None.
; Return Value:		AX - error status (0 if no error, 1 if error).
;
; Local Variables:	AX (W) - laser status argument passed into SetLaser.
; Shared Variables: None.
; Global Variables: None.
; 
; Input:			None. 
; Output:			Turns laser on. 
; 
; Error Handling:	A no-error value will be returned in AX.
; Algorithms:		None. 
; Data Structures: 	None. 
;
; Registers Used: 	AX.
; Stack Depth: 		0 words. 
;

OutputLaserOn 		PROC 	NEAR

	MOV 	AX, LASER_ON 			; populate (nonzero) argument for SetLaser
	CALL 	SetLaser				; turn on laser 
    CALL    ResetSharedVariables
	MOV 	AX, NO_PARSE_ERROR_VAL 	; return no-error value in AX 
	
	RET
OutputLaserOn		ENDP
	
	
	
;	
; OutputLaserOff 
;
; Description: 		This function is called when an O command is issued, without 
; 					any other tokens after it. It calls	the SetLaser function 
; 					defined in the motor routines to turn off the laser. 
; 
; Operation: 		This function calls the SetLaser function with an OFF command.
;
; Arguments:		None.
; Return Value:		AX - error status (0 if no error, 1 if error).
;
; Local Variables:	AX (W) - laser status argument passed into SetLaser.
; Shared Variables: None.
; Global Variables: None.

; Input:			None. 
; Output:			Turns laser off. 
;
; Error Handling:	A no-error value will be returned in AX.
; Algorithms:		None. 
; Data Structures: 	None. 
;
; Registers Used: 	AX.
; Stack Depth: 		0 words. 
;

OutputLaserOff 		PROC 	NEAR 
	
	MOV 	AX, LASER_OFF			; populate argument for SetLaser 
	CALL 	SetLaser				; change laser status 
    CALL    ResetSharedVariables
	MOV 	AX, NO_PARSE_ERROR_VAL 	; return no-error value in AX 
	
	RET	
OutputLaserOff		ENDP 
	


	

	; Token Table
;
; Description:      This creates the tables of token types and token values.
;                   Each entry corresponds to the token type and the token
;                   value for a character.  Macros are used to actually build
;                   two separate tables - TokenTypeTable for token types and
;                   TokenValueTable for token values.
;			
; Possible token types: TOKEN_NUM - numerical values 
; 						TOKEN_SIGN - '+' or '-' 
; 						TOKEN_EOS - carriage return 
; 						TOKEN_S - 'S' or 's', for set speed commands 
; 						TOKEN_V - 'V' or 'v', for set relative speed commands
; 						TOKEN_D - 'D' or 'd', for set direction angle commandss
; 						TOKEN_T - 'T' or 't', for set turret rotation commands 
; 						TOKEN_E	- 'E' or 'e', for set turret elevation commands 
; 						TOKEN_F - 'F' or 'f', for fire laser commands 
; 						TOKEN_O - 'O' or 'o', for turn off laser commands 
; 						TOKEN_OTHER	- any other token will be seen as invalid input
; 						TOKEN_IGNORE - tabs or spaces or null char are ignored 
; 										

%*DEFINE(TABLE)  (
        %TABENT(TOKEN_IGNORE, 0)	;<null> 
        %TABENT(TOKEN_OTHER, 1)		;SOH
        %TABENT(TOKEN_OTHER, 2)		;STX
        %TABENT(TOKEN_OTHER, 3)		;ETX
        %TABENT(TOKEN_OTHER, 4)		;EOT
        %TABENT(TOKEN_OTHER, 5)		;ENQ
        %TABENT(TOKEN_OTHER, 6)		;ACK
        %TABENT(TOKEN_OTHER, 7)		;BEL
        %TABENT(TOKEN_OTHER, 8)		;backspace
        %TABENT(TOKEN_IGNORE, 9)		;TAB
        %TABENT(TOKEN_OTHER, 10)	;new line
        %TABENT(TOKEN_OTHER, 11)	;vertical tab
        %TABENT(TOKEN_OTHER, 12)	;form feed
        %TABENT(TOKEN_EOS, 13)		;carriage return  (End of command)
        %TABENT(TOKEN_OTHER, 14)	;SO
        %TABENT(TOKEN_OTHER, 15)	;SI
        %TABENT(TOKEN_OTHER, 16)	;DLE
        %TABENT(TOKEN_OTHER, 17)	;DC1
        %TABENT(TOKEN_OTHER, 18)	;DC2
        %TABENT(TOKEN_OTHER, 19)	;DC3
        %TABENT(TOKEN_OTHER, 20)	;DC4
        %TABENT(TOKEN_OTHER, 21)	;NAK
        %TABENT(TOKEN_OTHER, 22)	;SYN
        %TABENT(TOKEN_OTHER, 23)	;ETB
        %TABENT(TOKEN_OTHER, 24)	;CAN
        %TABENT(TOKEN_OTHER, 25)	;EM
        %TABENT(TOKEN_OTHER, 26)	;SUB
        %TABENT(TOKEN_OTHER, 27)	;escape
        %TABENT(TOKEN_OTHER, 28)	;FS
        %TABENT(TOKEN_OTHER, 29)	;GS
        %TABENT(TOKEN_OTHER, 30)	;AS
        %TABENT(TOKEN_OTHER, 31)	;US
        %TABENT(TOKEN_IGNORE, ' ')	;space
        %TABENT(TOKEN_OTHER, '!')	;!
        %TABENT(TOKEN_OTHER, '"')	;"
        %TABENT(TOKEN_OTHER, '#')	;#
        %TABENT(TOKEN_OTHER, '$')	;$
        %TABENT(TOKEN_OTHER, 37)	;percent
        %TABENT(TOKEN_OTHER, '&')	;&
        %TABENT(TOKEN_OTHER, 39)	;'
        %TABENT(TOKEN_OTHER, 40)	;open paren
        %TABENT(TOKEN_OTHER, 41)	;close paren
        %TABENT(TOKEN_OTHER, '*')	;*
        %TABENT(TOKEN_SIGN, '+')	;+  (positive sign)             
        %TABENT(TOKEN_OTHER, 44)	;,
        %TABENT(TOKEN_SIGN, '-')	;-  (negative sign)             
        %TABENT(TOKEN_OTHER, '.')	;.  
        %TABENT(TOKEN_OTHER, '/')	;/
        %TABENT(TOKEN_NUM, 0)		;0  (digit)
        %TABENT(TOKEN_NUM, 1)		;1  (digit)
        %TABENT(TOKEN_NUM, 2)		;2  (digit)
        %TABENT(TOKEN_NUM, 3)		;3  (digit)
        %TABENT(TOKEN_NUM, 4)		;4  (digit)
        %TABENT(TOKEN_NUM, 5)		;5  (digit)
        %TABENT(TOKEN_NUM, 6)		;6  (digit)
        %TABENT(TOKEN_NUM, 7)		;7  (digit)
        %TABENT(TOKEN_NUM, 8)		;8  (digit)
        %TABENT(TOKEN_NUM, 9)		;9  (digit)
        %TABENT(TOKEN_OTHER, ':')	;:
        %TABENT(TOKEN_OTHER, ';')	;;
        %TABENT(TOKEN_OTHER, '<')	;<
        %TABENT(TOKEN_OTHER, '=')	;=
        %TABENT(TOKEN_OTHER, '>')	;>
        %TABENT(TOKEN_OTHER, '?')	;?
        %TABENT(TOKEN_OTHER, '@')	;@
        %TABENT(TOKEN_OTHER, 'A')	;A
        %TABENT(TOKEN_OTHER, 'B')	;B
        %TABENT(TOKEN_OTHER, 'C')	;C
        %TABENT(TOKEN_D, 'D')		;D	(direction)
        %TABENT(TOKEN_E, 'E')		;E  (elevation)
        %TABENT(TOKEN_F, 'F')		;F	(fire laser)
        %TABENT(TOKEN_OTHER, 'G')	;G
        %TABENT(TOKEN_OTHER, 'H')	;H
        %TABENT(TOKEN_OTHER, 'I')	;I
        %TABENT(TOKEN_OTHER, 'J')	;J
        %TABENT(TOKEN_OTHER, 'K')	;K
        %TABENT(TOKEN_OTHER, 'L')	;L
        %TABENT(TOKEN_OTHER, 'M')	;M
        %TABENT(TOKEN_OTHER, 'N')	;N
        %TABENT(TOKEN_O, 'O')		;O	(off laser)
        %TABENT(TOKEN_OTHER, 'P')	;P
        %TABENT(TOKEN_OTHER, 'Q')	;Q
        %TABENT(TOKEN_OTHER, 'R')	;R
        %TABENT(TOKEN_S, 'S')		;S	(speed(absolute))
        %TABENT(TOKEN_T, 'T')		;T	(turret angle)
        %TABENT(TOKEN_OTHER, 'U')	;U
        %TABENT(TOKEN_V, 'V')		;V	(relative direction)
        %TABENT(TOKEN_OTHER, 'W')	;W
        %TABENT(TOKEN_OTHER, 'X')	;X
        %TABENT(TOKEN_OTHER, 'Y')	;Y
        %TABENT(TOKEN_OTHER, 'Z')	;Z
        %TABENT(TOKEN_OTHER, '[')	;[
        %TABENT(TOKEN_OTHER, '\')	;\
        %TABENT(TOKEN_OTHER, ']')	;]
        %TABENT(TOKEN_OTHER, '^')	;^
        %TABENT(TOKEN_OTHER, '_')	;_
        %TABENT(TOKEN_OTHER, '`')	;`
        %TABENT(TOKEN_OTHER, 'a')	;a
        %TABENT(TOKEN_OTHER, 'b')	;b
        %TABENT(TOKEN_OTHER, 'c')	;c
        %TABENT(TOKEN_D, 'd')		;d	(direction)
        %TABENT(TOKEN_E, 'e')		;e  (elevation)
        %TABENT(TOKEN_F, 'f')		;f	(fire laser)
        %TABENT(TOKEN_OTHER, 'g')	;g
        %TABENT(TOKEN_OTHER, 'h')	;h
        %TABENT(TOKEN_OTHER, 'i')	;i
        %TABENT(TOKEN_OTHER, 'j')	;j
        %TABENT(TOKEN_OTHER, 'k')	;k
        %TABENT(TOKEN_OTHER, 'l')	;l
        %TABENT(TOKEN_OTHER, 'm')	;m
        %TABENT(TOKEN_OTHER, 'n')	;n
        %TABENT(TOKEN_O, 'o')		;o	(off laser)
        %TABENT(TOKEN_OTHER, 'p')	;p
        %TABENT(TOKEN_OTHER, 'q')	;q
        %TABENT(TOKEN_OTHER, 'r')	;r
        %TABENT(TOKEN_S, 's')		;s	(speed(absolute))
        %TABENT(TOKEN_T, 't')		;t	(turret angle)
        %TABENT(TOKEN_OTHER, 'u')	;u
        %TABENT(TOKEN_V, 'v')		;v	(relative direction)
        %TABENT(TOKEN_OTHER, 'w')	;w
        %TABENT(TOKEN_OTHER, 'x')	;x
        %TABENT(TOKEN_OTHER, 'y')	;y
        %TABENT(TOKEN_OTHER, 'z')	;z
        %TABENT(TOKEN_OTHER, '{')	;{
        %TABENT(TOKEN_OTHER, '|')	;|
        %TABENT(TOKEN_OTHER, '}')	;}
        %TABENT(TOKEN_OTHER, '~')	;~
        %TABENT(TOKEN_OTHER, 127)	;rubout
)

; token type table - uses first byte of macro table entry
%*DEFINE(TABENT(tokentype, tokenvalue))  (
        DB      %tokentype
)

TokenTypeTable	LABEL   BYTE
        %TABLE


; token value table - uses second byte of macro table entry
%*DEFINE(TABENT(tokentype, tokenvalue))  (
        DB      %tokenvalue
)

TokenValueTable	LABEL       BYTE
        %TABLE

		


; StateTable
;
; Description:      This is the state transition table for the state machine.
;                   Each entry consists of the next state and actions for that
;                   transition.  The rows are associated with the current
;                   state and the columns with the input type.
;
; There are 20 possible states: 
;
; ST_INITIAL - initial or idle state, waiting for any start input tokens 
;
; ST_SPEED - begin set speed state, when 'S' is read 
; ST_SPEED_SIGN - in process of setting speed, when '+' or '-' read after 'S'
; ST_SPEED_NUM - setting speed, when numerical value is read after 'S', 'S+','S-'
;
; ST_REL_SPEED - begin set relative speed state, when 'V' is read 
; ST_REL_SPEED_SIGN - in process of setting rel speed, when '+' or '-' after 'V' 
; ST_REL_SPEED_NUM - setting rel speed, when numerical value after 'V', 'V+', 'V-'
;
; ST_DIR - begin set angle of direction state, when 'D' is read 
; ST_DIR_SIGN	- set pos/neg relative change, when '+' or '-' read after 'D' 
; ST_DIR_NUM - setting rel angle, when numerical value after 'D', 'D+', 'D-'
;
; ST_LAS_ANG - begin setting angle of turret rotation, when 'R' is read 
; ST_LAS_ANG_NUM - unsigned numerical value: absolute angle of turret rotation 
;									 
; ST_LAS_ANG_REL - setting relative angle of turret rotation, '+' or '-' after 'R'
; ST_LAS_ANG_REL_NUM - rel angle of turret rotation, numerical value following sign
;
; ST_LAS_ELV - begin setting elevation of turret, when 'E' is read 
; ST_LAS_ELV_SIGN - define positive or negative elevation, when '+' or '-' follows 'E'
; ST_LAS_ELV_NUM - set numerical value of turret elevation, after 'E', 'E+', 'E-' read
;
; ST_LAS_ON - set laser to on, state. when 'F' is read.
;
; ST_LAS_OFF - turn laser off state, when 'O' is read. 
;
; ST_ERROR - error state, when invalid tokens are read 
;

TRANSITION_ENTRY        STRUC           ;structure used to define table
    NEXTSTATE   DB      ?               ;the next state for the transition
    ACTION1     DW      ?               ;first action for the transition
TRANSITION_ENTRY      ENDS


;define a macro to make table a little more readable
;macro just does an offset of the action routine entries to build the STRUC

%*DEFINE(TRANSITION(nxtst, act1))  (
    TRANSITION_ENTRY< %nxtst, OFFSET(%act1) >
)
	

StateTable	LABEL	TRANSITION_ENTRY

	; Current state = ST_INITIAL				Input Token Type 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_NUM
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_SIGN
	%TRANSITION(ST_INITIAL, DoNOP) 					; TOKEN_EOS
	%TRANSITION(ST_SPEED, DoNOP) 					; TOKEN_S 
	%TRANSITION(ST_REL_SPEED, DoNOP) 				; TOKEN_V
	%TRANSITION(ST_DIR, DoNOP) 						; TOKEN_D 
	%TRANSITION(ST_LAS_ANG, DoNOP) 					; TOKEN_T
	%TRANSITION(ST_LAS_ELV, DoNOP) 					; TOKEN_E
	%TRANSITION(ST_LAS_ON, DoNOP) 					; TOKEN_F 
	%TRANSITION(ST_LAS_OFF, DoNOP) 					; TOKEN_O
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_OTHER
	%TRANSITION(ST_INITIAL, DoNOP)					; TOKEN_IGNORE
    
	; Current state = ST_SPEED 
	%TRANSITION(ST_SPEED_NUM, NewDigit) 			; TOKEN_NUM
	%TRANSITION(ST_SPEED_SIGN, SetSign) 			; TOKEN_SIGN            
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_EOS
	%TRANSITION(ST_SPEED, ErrorHandler) 			; TOKEN_S 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_V
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_D 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_T
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_E
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_F 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_O
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_OTHER
	%TRANSITION(ST_SPEED, DoNOP)					; TOKEN_IGNORE
	
	; Current state = ST_SPEED_SIGN 
	%TRANSITION(ST_SPEED_NUM, NewDigit) 			; TOKEN_NUM
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_SIGN
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_EOS
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_S 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_V
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_D 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_T
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_E
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_F 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_O
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_OTHER
	%TRANSITION(ST_SPEED_SIGN, DoNOP)				; TOKEN_IGNORE
	
	; Current state = ST_SPEED_NUM
	%TRANSITION(ST_SPEED_NUM, NewDigit) 			; TOKEN_NUM
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_SIGN
	%TRANSITION(ST_INITIAL, OutputSpeed)            ; TOKEN_EOS
	%TRANSITION(ST_SPEED, ErrorHandler) 			; TOKEN_S 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_V
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_D 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_T
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_E
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_F 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_O
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_OTHER
	%TRANSITION(ST_SPEED_NUM, DoNOP)				; TOKEN_IGNORE
	
	; Current state = ST_REL_SPEED
	%TRANSITION(ST_REL_SPEED_NUM, NewDigit) 		; TOKEN_NUM
	%TRANSITION(ST_REL_SPEED_SIGN, SetSign) 		; TOKEN_SIGN
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_EOS
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_S 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_V
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_D 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_T
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_E
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_F 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_O
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_OTHER	
	%TRANSITION(ST_REL_SPEED, DoNOP)				; TOKEN_IGNORE
	
	; Current state = ST_REL_SPEED_SIGN
	%TRANSITION(ST_REL_SPEED_NUM, NewDigit) 		; TOKEN_NUM
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_SIGN
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_EOS
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_S 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_V
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_D 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_T
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_E
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_F 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_O
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_OTHER
	%TRANSITION(ST_REL_SPEED_SIGN, DoNOP)			; TOKEN_IGNORE
	
	; Current state = ST_REL_SPEED_NUM 
	%TRANSITION(ST_REL_SPEED_NUM, NewDigit) 		; TOKEN_NUM
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_SIGN
	%TRANSITION(ST_INITIAL, OutputRelSpeed)			; TOKEN_EOS
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_S 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_V
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_D 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_T
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_E
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_F 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_O
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_OTHER
	%TRANSITION(ST_REL_SPEED_NUM, DoNOP)			; TOKEN_IGNORE
	
	; Current state = ST_DIR 
	%TRANSITION(ST_DIR_NUM, NewDigit) 				; TOKEN_NUM
	%TRANSITION(ST_DIR_SIGN, SetSign) 				; TOKEN_SIGN              
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_EOS
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_S 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_V
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_D 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_T
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_E
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_F 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_O
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_OTHER
	%TRANSITION(ST_DIR, DoNOP)						; TOKEN_IGNORE
	
	; Current state = ST_DIR_SIGN 
	%TRANSITION(ST_DIR_NUM, NewDigit) 				; TOKEN_NUM
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_SIGN
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_EOS
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_S 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_V
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_D 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_T
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_E
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_F 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_O
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_OTHER
	%TRANSITION(ST_DIR_SIGN, DoNOP)					; TOKEN_IGNORE
	
	; Current state = ST_DIR_NUM 
	%TRANSITION(ST_DIR_NUM, NewDigit) 				; TOKEN_NUM
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_SIGN
	%TRANSITION(ST_INITIAL, OutputDirection)		; TOKEN_EOS
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_S 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_V
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_D 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_T
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_E
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_F 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_O
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_OTHER
	%TRANSITION(ST_DIR_NUM, DoNOP)					; TOKEN_IGNORE
	
	; Current state = ST_LAS_ANG 
	%TRANSITION(ST_LAS_ANG_NUM, NewDigit) 			; TOKEN_NUM
	%TRANSITION(ST_lAS_ANG_REL, SetSign) 			; TOKEN_SIGN
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_EOS
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_S 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_V
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_D 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_T
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_E
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_F 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_O
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_OTHER
	%TRANSITION(ST_LAS_ANG, DoNOP)					; TOKEN_IGNORE
	
	; Current state = ST_LAS_ANG_NUM 
	%TRANSITION(ST_LAS_ANG_NUM, NewDigit) 			; TOKEN_NUM
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_SIGN
	%TRANSITION(ST_INITIAL, OutputTurretRotation)	; TOKEN_EOS
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_S 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_V
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_D 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_T
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_E
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_F 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_O
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_OTHER
	%TRANSITION(ST_LAS_ANG_NUM, DoNOP)				; TOKEN_IGNORE
	
	; Current state = ST_LAS_ANG_REL
	%TRANSITION(ST_LAS_ANG_REL_NUM, NewDigit) 		; TOKEN_NUM
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_SIGN
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_EOS
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_S 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_V
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_D 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_T
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_E
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_F 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_O
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_OTHER
	%TRANSITION(ST_LAS_ANG_REL, DoNOP)				; TOKEN_IGNORE
	
	; Current state = ST_LAS_ANG_REL_NUM
	%TRANSITION(ST_LAS_ANG_REL_NUM, NewDigit) 		; TOKEN_NUM
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_SIGN
	%TRANSITION(ST_INITIAL, OutputTurretRelRotation); TOKEN_EOS
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_S 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_V
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_D 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_T
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_E
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_F 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_O
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_OTHER
	%TRANSITION(ST_LAS_ANG_REL_NUM, DoNOP)			; TOKEN_IGNORE
	
	; Current state = ST_LAS_ELV 
	%TRANSITION(ST_LAS_ELV_NUM, NewDigit) 			; TOKEN_NUM
	%TRANSITION(ST_LAS_ELV_SIGN, SetSign) 			; TOKEN_SIGN
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_EOS
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_S 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_V
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_D 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_T
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_E
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_F 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_O
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_OTHER
	%TRANSITION(ST_LAS_ELV, DoNOP)					; TOKEN_IGNORE
	
	; Current state = ST_LAS_ELV_SIGN 
	%TRANSITION(ST_LAS_ELV_NUM, NewDigit) 			; TOKEN_NUM
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_SIGN
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_EOS
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_S 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_V
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_D 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_T
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_E
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_F 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_O
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_OTHER
	%TRANSITION(ST_LAS_ELV_SIGN, DoNOP)				; TOKEN_IGNORE
	
	; Current state = ST_LAS_ELV_NUM  
	%TRANSITION(ST_LAS_ELV_NUM, NewDigit) 			; TOKEN_NUM
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_SIGN
	%TRANSITION(ST_INITIAL, OutputTurretElevation)	; TOKEN_EOS
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_S 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_V
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_D 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_T
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_E
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_F 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_O
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_OTHER
	%TRANSITION(ST_LAS_ELV_NUM, DoNOP)				; TOKEN_IGNORE
	
	; Current state = ST_LAS_ON  
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_NUM
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_SIGN
	%TRANSITION(ST_INITIAL, OutputLaserOn) 			; TOKEN_EOS
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_S 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_V
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_D 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_T
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_E
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_F 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_O
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_OTHER
	%TRANSITION(ST_LAS_ON, DoNOP)					; TOKEN_IGNORE
	
	; Current state = ST_LAS_OFF  
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_NUM
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_SIGN
	%TRANSITION(ST_INITIAL, OutputLaserOff) 	    ; TOKEN_EOS
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_S 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_V
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_D 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_T
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_E
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_F 
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_O
	%TRANSITION(ST_ERROR, ErrorHandler) 			; TOKEN_OTHER
	%TRANSITION(ST_LAS_OFF, DoNOP)					; TOKEN_IGNORE
    
    ; Current state = ST_ERROR
	%TRANSITION(ST_ERROR, DoNOP) 					; TOKEN_NUM
	%TRANSITION(ST_ERROR, DoNOP) 					; TOKEN_SIGN
	%TRANSITION(ST_INITIAL, ResetSharedVariables) 	; TOKEN_EOS
	%TRANSITION(ST_ERROR, DoNOP) 					; TOKEN_S 
	%TRANSITION(ST_ERROR, DoNOP) 					; TOKEN_V
	%TRANSITION(ST_ERROR, DoNOP) 					; TOKEN_D 
	%TRANSITION(ST_ERROR, DoNOP) 					; TOKEN_T
	%TRANSITION(ST_ERROR, DoNOP) 					; TOKEN_E
	%TRANSITION(ST_ERROR, DoNOP) 					; TOKEN_F 
	%TRANSITION(ST_ERROR, DoNOP) 					; TOKEN_O
	%TRANSITION(ST_ERROR, DoNOP) 					; TOKEN_OTHER
    %TRANSITION(ST_ERROR, DoNOP)					; TOKEN_IGNORE
	
CODE 	ENDS
		
		
;
; the data segment (SHARED VARIABLES)

DATA 	SEGMENT     PUBLIC 	'DATA'

numberInProgress 		DW 		?
	; holds the current number passed as part of a command

sign 			DB 		? 
	; sign of number: -1 if negative, 1 if positive 
	
parseErrorStatus 	DB 		?
	; error flag when error occurs 

currentState 	DB 		?
	; holds value of current state so when the next character 
	;				is input, we know what state to start at 

DATA 	ENDS

END