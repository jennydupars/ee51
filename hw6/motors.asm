	NAME 	MOTORS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;  							     Motor Routines                              ;
;                           	   Homework 6        		                 ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; The functions here will control the DC motors and laser for the Robotrike. The 
; functions included are: 
; 	MotorEventHandler - updates the movements of Robotrike's motors and laser status 
; 	SetMotorSpeed - sets the speed of the RoboTrike, sets the direction of movement
; 	GetMotorSpeed - get the current speed setting for the RoboTrike
; 	GetMotorDirection - get the current direction of movement setting for the RoboTrike
; 	SetLaser - turn on or turn off the laser
; 	GetLaser - get the current laser status (on or off)
;	InitRobot - initializes variables responsible for robot direction, speed, and laser status 
;


; Revision History:
;     11/06/16  	Jennifer Du      initial revision
; 	  11/08/16 		Jennifer Du 	 writing assembly 
;


;
;Include files 
$INCLUDE(motors.inc)
$INCLUDE(common.inc)

; External functions and tables 
	EXTRN Sin_Table: WORD 			; table of sin values  
	EXTRN Cos_Table: WORD 			; table of cosine values 


CGROUP	GROUP	CODE
DGROUP	GROUP	DATA

CODE SEGMENT PUBLIC 'CODE'

		ASSUME	CS:CGROUP, DS:DGROUP

;
;
; MotorEventHandler 
;
;
; Description:  	This function outputs the correct values to the parallel port 
; 					that controls the motors' and laser's status and direction. 
;                   This function is called at every interrupt, and checks to see 
;                   if each motor should or shouldn't be on based on the pulse 
;                   width counter variable. 
;
; Operation:    	The function checks to see if any of the motors need to be 
;                   turned on or turned off, and does so accordingly. It also checks 
;                   to see if the laser needs to be on or off, and sets the value 
;                   written to the ports such that the motors and laser are turned 
;                   on or off at each instance. 

; Arguments:        None. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: pulseWidth - array of pulse width counts corresponding to each motor 
;                   pulseWidthCnt - counter to implement pulse width modulation movement 
;                   motorOutVal - value to be written to port B to change I/O devices 
;                   laserStatus - status of laser (on or off) 
; Global Variables:	None.
; 
; Input:            None.
; Output:           Laser will be turned on or off, and motors will be turned on 
; 					or off according to calculations to create the desired 
; 					direction and speed of motion.  
;
; Error Handling: 	None. 
;
; Registers Used:   flags, AX, BX, CX, DX 
; Stack Depth:      0 words
;
; Algorithms: 		None. 
; Data Structures:  None.

MotorEventHandler 	PROC 	NEAR
					PUBLIC 	MotorEventHandler

 
                    
	MOV 	BX, 0
UpdateMotorStatus:
	XOR 	AX, AX 				; clear register 
	MOV 	AL, pulseWidth[BX]
	
	TEST    AL, NEG_SIGN_SET    ; test to see if sign bit is set (negative number)
    JNZ     GetAbsValOfNegSpeed ; if test results in 1, then sign bit is set 
	;JG		CompareToPulseWidthCount
	
CompareToPulseWidthCount: 
	CMP 	pulseWidthCnt, AL 	
	JGE 	TurnOffMotor
	JL		TurnOnMotor
	
GetAbsValOfNegSpeed: 
	NEG 	AL							; turn speed positive 
    INC     AL                          ; two's complement
	JMP 	CompareToPulseWidthCount 
	
TurnOnMotor:
	MOV     AL, pulseWidth[BX] 				; see if the speed is less than 0 
    TEST    AL, NEG_SIGN_SET    ; test to see if sign bit is set (negative number)
    JNZ     SpeedIsNegative ; if test results in 1, then sign bit is set 
	JZ		SpeedIsPositive 				; if speed < 0, use the right thing  		
		

TurnOffMotor: 
	MOV 	DX, BX							; save index 
	SHL 	BX, 1							; multiply by 2 to get 0, 2, 4 index in table 
	MOV 	AL, motorOutVal 
	MOV 	CL, CS:Motor_Direction_Table[BX]	; motor direction table (backwards direction) has 11 in a row for index 2n to 2n+1 for motor n
	OR 		AL, CL 								; sets relevant bits to 11 in AX
	XOR 	AL, CL 							; matching bits make the relevant bits in AX go to 00 
	MOV 	motorOutVal, AL					
	MOV 	BX, DX 							; restore index 
	JMP 	UpdateNextMotor

SpeedIsPositive:
	MOV 	AL, motorOutVal
	MOV 	DX, BX
	SHL 	BX, 1 							; multiply by 2 since each motor has 2 entries (want the first one) 0, 2, 4
	MOV 	CL, CS:Motor_Direction_Table[BX]
	OR 		AL, CL 
	MOV 	motorOutVal, AL
	MOV 	BX, DX 							; move index back into BX  
	JMP 	UpdateNextMotor
	
SpeedIsNegative:
	MOV 	DX, BX 							; save correct index 
	MOV 	AL, motorOutVal
	SHL 	BX, 1 							; multiply by 2 since each motor has 2 entries (want 1, 3, 5)
	INC 	BX 								; want 2n + 1 to get the right index 
	MOV 	CL, CS:Motor_Direction_Table[BX]
	OR 		AL, CL 
	MOV 	motorOutVal, AL 
	MOV 	BX, DX 							; restore correct index
	JMP 	UpdateNextMotor

UpdateNextMotor: 
	INC 	BX 
	CMP 	BX, NUM_MOTORS					; if we have gone through all 3 motors 
	JE 		IncrementPWCounter
	JMP 	UpdateMotorStatus
	
IncrementPWCounter:
	INC 	pulseWidthCnt
	XOR 	AX, AX 
	MOV 	AL, pulseWidthCnt
	MOV 	DX, 0 
	MOV 	CX, PWM_MAX_COUNT_VAL
	DIV 	CX 
	MOV 	pulseWidthCnt, DL
	
UpdateLaser: 
	CMP 	laserStatus, LASER_OFF 
	JZ 		TurnOffLaser 
	;JNZ 	TurnOnLaser 
	
TurnOnLaser: 
	MOV 	AL, motorOutVal 
	OR 		AL, LASER_ON
	MOV 	motorOutVal, AL
	JMP 	OutputToPort
    
TurnOffLaser: 
	MOV 	AL, motorOutVal
    OR      AL, LASER_ON
	XOR		AL, LASER_ON 
	MOV 	motorOutVal, AL 
	;JMP 	OutputToPort
	
OutputToPort: 
	MOV 	DX, MOTOR_OUT_LOC 
	MOV 	AL, motorOutVal 
	OUT 	DX, AL 

    
EndMotorEventHandler: 
	RET 
	
MotorEventHandler 	ENDP 
	
	
;
;
; SetMotorSpeed
;
;
; Description:  	This function sets the speed of the robot to the passed-in 
;					speed argument, and sets the angle of movement of the robot 
; 					to the passed-in angle argument. 
;
; Operation:    	The speed will be set to the speed argument passed in (less 
; 					than 65534), and will cause the robot to move at that speed. 
; 					If the speed argument is equal to 65535, then the current 
; 					speed of the robot's movement will not be changed. The speed 
; 					will be changed to form Q0.15, where the value is a fraction 
;                   of the max speed. 
; 
; 					The angle will be set to the angle argument passed in. The angle 
;                   will be turned into a value between 0 and 359. A passed-in angle 
;                   of -32768 indicates that the current direction of motion will 
;                   not be changed. 
;
; Arguments:        speed (AX) - absolute speed at which the robot will run.
; 					angle (BX) - signed angle at which the robot is to move 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: robotSpeed - speed of movement of robot 
; 					robotAngle - angle of movement of robot 
; 					pulseWidth - array storing each motor's PWM value 
; Global Variables:	None.
; 
; Input:            None.
; Output:           None. 
;
; Error Handling: 	None. 
; Registers Used:   flags, AX, BX, CX, DX, SI
; Stack Depth:      1 word
;
; Algorithms: 		None. 
; Data Structures:  None.
;	 

SetMotorSpeed 	PROC	NEAR
				PUBLIC 	SetMotorSpeed

    AND     motorOutVal, 00H
    
                
                
CheckSpeedHold:
	CMP 	AX, HOLD_SPEED_VAL			; if speed is set to no-change value 
	JNE 	ChangeSpeed                     ; not no-change: jmp and change speed 
	CMP 	BX, HOLD_ANGLE_VAL          ; test to see if angle should be changed 
	JNE		ChangeAngle                     ; if it should be changed 
	JMP 	EndSetMotorSpeed            ; if values pass these tests then end function, no change 

ChangeSpeed:
	
	SHR 	AX, 1 						; turn value into Q0.15 form 
	MOV 	robotSpeed, AX              ; then store as official robot speed 

CheckAngleHold: 
	CMP 	BX, HOLD_ANGLE_VAL          ; if angle should be held 
	JE 		SetNewDirection             ; just go set the new direction with old angle val 
	JNE		ChangeAngle                 ; if not holding angle, change it 

ChangeAngle: 
	MOV 	CX, TOTAL_DEGREES           ; signed divide angle value by 360  
	MOV 	AX, BX 					        ; to take the signed remainder as the 
	CWD                                     ; angle between 0 and 360 
	IDIV 	CX  
	
	CMP 	DX, 0                       ; see if remainder (angle) is positive or not 
	JGE 	ModAnglePositive
	JL 		ModAngleNegative
	
ModAnglePositive:                       ; if angle is positive 
	MOV 	robotAngle, DX                  ; just store value 
	JMP 	SetNewDirection
	
ModAngleNegative:
	ADD 	DX, TOTAL_DEGREES           ; if angle is negative
	MOV		robotAngle, DX                  ; store value after making it a value 
	;JMP 	SetNewDirection                 ; between 0 and 359 (by adding 360) 
	
SetNewDirection:                        ; after setting new angle and speed (if applicable) 
                                            ; calculate motors' PWM values 
	MOV 	BX, robotAngle 
	SHL 	BX, 1 			            ; double angle val to get the index in cos table (since word sized elements) 

                                    ; calculate speed in x direction 
	MOV 	AX, CS:Cos_Table[BX]		; grab the cosine value 
	MOV 	CX, robotSpeed              
	IMUL 	CX                          ; signed multiply speed by the cos(angle) = velocity in x direction 
	MOV 	Vx, DX 				        ; truncate to DX 
	
                                    ; calculate speed in y direction 
	MOV 	AX, CS:Sin_Table[BX]        ; grab sine value 
	MOV 	CX, robotSpeed              ; signed multiply speed by the sine of the 
	IMUL 	CX                          ; angle 
	MOV 	Vy, DX                      ; truncate to DX 
	
	MOV 	BX, 0                       ; initiate counter to loop through PWM array and update values 
FillPulseWidthArray: 
	
	CMP 	BX, NUM_MOTORS              ; check end condition: if we've updated all motors' PWM val already 
	JE 		EndSetMotorSpeed                ; if so, just end function 
	;JNE 	keep calculating                
	
	SHL 	BX, 2 			            ; multiply BX by 4 to get the 0-1, 2-3, 4-5 elements per iteration 
	MOV 	AX, Vx                      
	MOV 	CX, WORD PTR CS:Force_Table[BX]
	IMUL 	CX
	ADD 	BX, WORDSIZE 				; move to next spot in force table (since table values are words)
	PUSH 	DX 					        
	
	MOV 	AX, Vy 
	MOV  	CX, WORD PTR CS:Force_Table[BX]
	IMUL 	CX 
	;ADD 	BX, 2
	
	MOV 	AX, DX  			        ; move the Vy*force into AX 
	POP 	DX 					        ; move the Vx*force back into DX 
	ADD 	AX, DX 				        ; add them together 
	
	SAL 	AX, 2 				        ; shift sum left by 2 
	MOV 	DX, AX 
	
	SUB 	BX, 2 		; subtract BX by 2 to get index of pulse width thing 
	SHR 	BX, 2		; divide BX by 4 
	MOV 	pulseWidth[BX], DH 			; only take DH (truncate) and place in pulse width array 
	INC 	BX                  ; increment BX counter after undoing all changes to BX 
	JMP 	FillPulseWidthArray ; move onto populating next spot in pulse width array 

EndSetMotorSpeed: 
	RET 

SetMotorSpeed 	ENDP


;
;
;
; GetMotorSpeed 
;
; Description:  	This function returns the current speed setting for the 
; 					RoboTrike in AX. This function will always return a speed 
; 					between 0 and 65534. 
;
; Operation:    	Moves the variable robotSpeed into AX and then returns. 
; Arguments:        None. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: robotSpeed - current speed of the robot 
; Global Variables:	None.
; 
; Input:            None.
; Output:           None. 
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  None.
;

GetMotorSpeed 	PROC	NEAR
				PUBLIC	GetMotorSpeed
	
	MOV 	AX, robotSpeed          ; move robotSpeed to AX for reading 
	RET

GetMotorSpeed 	ENDP

;
;
; GetMotorDirection
;
; Description:  	This function returns the current direction of movement 
; 					of the Robotrike as an angle in degrees in AX. Angles are 
; 					measured clockwise, and an angle of 0 means the Robotrike 
; 					is moving straight forward with respect to the direction 
; 					it's facing. Angles will range from 0 to 359 degrees. 
;
; Operation:    	Moves the variable robotAngle into AX and then returns.
; Arguments:        None. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: robotAngle - current direction the robot is facing 
; Global Variables:	None.
; 
; Input:            None.
; Output:           None.
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  None.
;


GetMotorDirection 	PROC	NEAR
					PUBLIC	GetMotorDirection
	
	MOV 	AX, robotAngle
	RET

GetMotorDirection 	ENDP

;
;
; SetLaser   
;
; Description:  	The function is passed a single argument (onoff) in AX that 
; 					indicates whether to turn the RoboTrike laser on or off. A 
; 					zero value turns the laser off and a non-zero value turns it on.
;
; Operation:    	This function sets the shared variable laserStatus to the value 
; 					of the onoff argument passed into this function.
; Arguments:        onoff (AX) - turns laser off if equal to 0, and on otherwise. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: 
; Global Variables:	None.
; 
; Input:            None.
; Output:           None. 
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  None.
;
;


SetLaser 	PROC	NEAR
			PUBLIC	SetLaser
	
	
	MOV 	laserStatus, AX
	
	RET

SetLaser 	ENDP


;
;
; GetLaser  
;
; Description:  	This function returns the status of the Robotrike laser 
; 					in AX. A value of 0 means the laser is off, and a non-zero 
; 					value means the laser is on. 
;
; Operation:    	Moves the shared variable laserStatus into AX and then returns. 

; Arguments:        None. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: laserStatus - holds status of laser (on or off)
; Global Variables:	None.
; 
; Input:            None.
; Output:           None. 
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  None.
;
	
GetLaser 	PROC	NEAR
			PUBLIC	GetLaser

	MOV 	AX, laserStatus
	RET

GetLaser 	ENDP

;
;
;
; InitRobot   
;
; Description:  	This function initializes the motor variables that will be 
; 					set and changed throughout the Robotrike's running. 
;
; Operation:    	Sets robotSpeed to 0 (not moving), robotAngle to 0 (straight 
; 					ahead), laserAngle to 0 (straight ahead), laserStatus to 0 
; 					(off), and the pulse width array and counter variables to 
; 					0. 
; Arguments:        None. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: robotSpeed - current speed of the robot 
;					robotAngle - current angle of robot's movement 
;					laserAngle - current angle of robot's laser 
;					laserStatus - current on/off status of laser 
;					pulseWidth - array storing pulse width values for each motor 
;					pulseWidthCnt - counts number of iterations of motorEventHandler;
;							keeps track of motor status in terms of pulse width times
;	
; Global Variables:	None.
; 
; Input:            None.
; Output:           None. 
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  None.
;


InitRobot 	PROC	NEAR
			PUBLIC	InitRobot

Initvariables:
	MOV 	robotSpeed, 0
	MOV 	robotAngle, 0
	MOV 	laserAngle, 0
	MOV 	laserStatus, 0
	MOV		pulseWidthCnt, 0
	MOV 	Vx, 0
	MOV 	Vy, 0 
	MOV 	motorOutVal, 0

	MOV 	BX, 0
InitPulseWidthArray:
	MOV 	pulseWidth[BX], 0
	INC 	BX
	CMP 	BX, NUM_MOTORS
	JE 		EndInitRobot
	JNE		InitPulseWidthArray

EndInitRobot: 
	RET 

InitRobot 	ENDP 


; Stub functions 

SetRelTurretAngle	PROC 	NEAR
					PUBLIC 	SetRelTurretAngle
	RET
SetRelTurretAngle 	ENDP 


SetTurretAngle		PROC 	NEAR
					PUBLIC 	SetTurretAngle
	RET 
SetTurretAngle		ENDP 


SetTurretElevation 	PROC 	NEAR
					PUBLIC 	SetTurretElevation
	RET 
SetTurretElevation 	ENDP 


; Tables 


Force_Table 	LABEL 		BYTE
				PUBLIC 		Force_Table
	
	DW 		07FFFH		; Fx for motor 1
	DW 		00000H 		; Fy for motor 1
	
	DW 		0C000H	    ; Fx for motor 2      1.1000000000000
	DW 		09127H  	; Fy for motor 2      1.111
	
	DW 		0C000H  	; Fx for motor 3 
	DW 		06ED9H  	; Fy for motor 3
	

	; forward direction: use the even numbered ones (2n) for 0, 1, 2 = 0, 2, 4
	; backward direction: use the even numbered ones (2n+1) for 0, 1, 2 = 1, 3, 5
Motor_Direction_Table 	LABEL 	BYTE
						PUBLIC 	Motor_Direction_Table
						; motor 1: 
	DB 		00000001B 	; move forward
	DB 		00000011B 	; move backward 
						; motor 2: 
	DB 		00000100B 	; move forward 
	DB 		00001100B 	; move backward 
						; motor 3: 
	DB 		00010000B 	; move forward 
	DB 		00110000B 	; move backward 
	


CODE 	ENDS



;
; the data segment (SHARED VARIABLES)

DATA 	SEGMENT     PUBLIC 	'DATA'


Vx 			DW 	?
Vy 			DW 	?
	; x and y speeds in the cartesian plane

motorOutVal DB 	?
	; stores current value to be output to the motor output port 
	
robotSpeed	DW 	?
	; current speed of the robot 
	; possible values: 0 to 65534 are speeds, 65535 is "do not change"
    		
robotAngle	DW 	?	
	; current angle of robot's movement with respect to the direction it faces 	
	; possible values: -32767 to 32767 are angles, -32768 is "do not change"
	
laserAngle	DW 	?
	; current angle of robot's laser with respect to the direction the robot faces 
	; possible values: -32767 to 32767 are angles, -32768 is "do not change"
	
laserStatus	DW 	?
	; current status of laser
	; on (1) or off (0)
	
pulseWidth	DB 	NUM_MOTORS 	DUP 	(?) 	
	; 3 driving motors: motor 1, motor 2, motor 3 each need a number 
	; to count to to determine what percentage of the time they need to be 
	; turned on to achieve a speed (percent out of 127)
	
pulseWidthCnt	DB 	?
	; counter that keeps track of place in the pwm cycle each motor is at  	

DATA 	ENDS

END