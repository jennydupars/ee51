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
; 	MotorEventHandler - 
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

; External functions and tables 
	EXTRN Sin_Table: WORD 			; is this declaration right 
	EXTRN Cos_Table: WORD 			; is this declaration right 

; set up code and data groups
CGROUP	GROUP	CODE
DGROUP	GROUP	DATA

; segment register assumptions
	

CODE SEGMENT PUBLIC 'CODE'

		ASSUME	CS:CGROUP, DS:DGROUP

;
;
; MotorEventHandler 
;
;
; Description:  	This function outputs the correct values to the parallel port 
; 					that controls the motors' and laser's status and direction. 
;
; Operation:    	

; Arguments:        
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: 
; Global Variables:	None.
; 
; Input:            None.
; Output:           Laser will be turned on or off, and motors will be turned on 
; 					or off according to calculations to create the desired 
; 					direction and speed of motion.  
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  None.

MotorEventHandler 	PROC 	NEAR
					PUBLIC 	MotorEventHandler

	MOV 	BX, 0
UpdateMotorStatus:
	XOR 	AX, AX 				; clear register 
	MOV 	AL, pulseWidth[BX]
	CMP 	AL, 0 						; is the speed positive or negative 
	JL		GetAbsValOfNegSpeed 
	;JG		CompareToPulseWidthCount
	
CompareToPulseWidthCount: 
	CMP 	AL, pulseWidthCnt 			; see if abs value of speed is greater or less 
	JGE 	TurnOffMotor
	JL		TurnOnMotor
	
GetAbsValOfNegSpeed: 
	NEG 	AL							; turn speed positive 
	JMP 	CompareToPulseWidthCount 
	
TurnOnMotor:
	CMP 	pulseWidth[BX], 0 				; see if the speed is less than 0 
	JL		SpeedIsNegative 				; if speed < 0, use the right thing  		
	JGE 	SpeedIsPositive	

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
	MOV 	CX, 128 
	DIV 	CX 
	MOV 	pulseWidthCnt, DL 

	
UpdateLaser: 
	CMP 	laserStatus, 0 
	JZ 		TurnOffLaser 
	JNZ 	TurnOnLaser 
	
TurnOffLaser: 
	MOV 	AL, LASER_OFF
	OR 		AL, motorOutVal 
	MOV 	motorOutVal, AL 
	JMP 	OutputToPort
		
TurnOnLaser: 
	MOV 	AL, LASER_ON
	OR 		AL, motorOutVal 
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
; 					will be changed from a number between 0 and 65534 to between 
; 					-127 to 127, where the negative numbers mean reverse direction. 
; 
; 					The angle will be set to the angle argument passed in. An 
; 					angle of 0 means the direction straight ahead relative to the 
; 					Robotrike's "face", and an angle of -32768 indicates that the 
; 					current direction of motion will not be changed. 

; Arguments:        speed (AX) - absolute speed at which the robot will run.
; 					angle (BX) - signed angle at which the robot is to move 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: robotSpeed - speed of movement of robot 
; 					robotAngle - angle of movement of robot 
; 					pulseWidth - array storing counts of each motor's behavior 
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

SetMotorSpeed 	PROC	NEAR
				PUBLIC 	SetMotorSpeed

CheckSpeedHold:
	CMP 	AX, HOLD_SPEED_VAL			; HOLD_SPEED_VAL EQU 65535d
	JNE 	ChangeSpeed
	CMP 	BX, HOLD_ANGLE_VAL
	JNE		ChangeAngle
	JMP 	EndSetMotorSpeed

ChangeSpeed:
	;MOV 	CX, 128
	;IDIV 	CX
	;SUB 	DX, 256 
	;MOV 	robotSpeed, DX 	
	;MOV 	robotSpeed, AX
	
	SHR 	AX, 1 						; turn it into Q0.15
	MOV 	robotSpeed, AX 

CheckAngleHold: 
	CMP 	BX, HOLD_ANGLE_VAL
	JE 		SetNewDirection
	JNE		ChangeAngle

ChangeAngle: 
	MOV 	CX, TOTAL_DEGREES 
	MOV 	AX, BX 					; move robot anlge into AX to divide 
	CWD 
	IDIV 	CX  
	
	CMP 	DX, 0 
	JGE 	ModAnglePositive
	JL 		ModAngleNegative
	
ModAnglePositive:
	MOV 	robotAngle, DX 
	JMP 	SetNewDirection
	
ModAngleNegative:
	ADD 	DX, TOTAL_DEGREES
	MOV		robotAngle, DX
	;JMP 	SetNewDirection
	
SetNewDirection: 

	MOV 	BX, robotAngle 
	SHL 	BX, 1 			; multiply angle by 2 to get the index in cos table 
	
	MOV 	AX, CS:Cos_Table[BX]			; are word tables indexed 0, 1, 2... or 0, 2, 4, ...///////////// 
	MOV 	CX, robotSpeed
	IMUL 	CX
	MOV 	Vx, DX 				; or do I move in DX for Q0.15 stuff////////////////////////////////////// 
	
	MOV 	AX, CS:Sin_Table[BX]
	MOV 	CX, robotSpeed
	IMUL 	CX 
	MOV 	Vy, DX 
	
	MOV 	BX, 0 
FillPulseWidthArray: 
	
	CMP 	BX, 3
	JE 		EndSetMotorSpeed
	;JNE 	keep calculating 
	
	SHL 	BX, 2 			; multiply BX by 4 to get the 0-1, 2-3, 4-5 elements per iteration 
	MOV 	AX, Vx 
	MOV 	CX, WORD PTR CS:Force_Table[BX]
	IMUL 	CX
	ADD 	BX, 2 					; move to next spot in array //////////////////////// word table indexing????
	PUSH 	DX 					; save this DX 
	
	MOV 	AX, Vy 
	MOV  	CX, WORD PTR CS:Force_Table[BX]
	IMUL 	CX 
	;ADD 	BX, 2
	
	MOV 	AX, DX  			; move the Vy*force into AX 
	POP 	DX 					; move the Vx*force back into DX 
	ADD 	AX, DX 				; add them together 
	
	SAL 	AX, 2 				; what is this 
	MOV 	DX, AX 
	
	SUB 	BX, 2 		; subtract BX by 2 to get index of pulse width thing 
	SHR 	BX, 2		; divide BX by 4 
	;DEC 	BX 		; 2 divide by 2 minus 1 = 0, 4 divide by 2 = 2, minus 1 = 1 
	MOV 	pulseWidth[BX], DH 			; only take DH (truncate)
	INC 	BX 
	JMP 	FillPulseWidthArray

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
	
	MOV 	AX, robotSpeed
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
	
	DW 		07FFFH				; Fx for motor 1
	DW 		00000H 					; Fy for motor 1
	
	DW 		0C000H	; Fx for motor 2      1.1000000000000
	DW 		09127H  		; Fy for motor 2      1.111
	
	DW 		0C000H  	; Fx for motor 3 
	DW 		06ED9H  			; Fy for motor 3
	

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