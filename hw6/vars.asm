
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




Force_Table 	LABEL 		BYTE
				PUBLIC 		Force_Table
; index 0 	
	DW 		07FFFH				; Fx for motor 1
; 2
	DW 		00000H 					; Fy for motor 1

; 4	
	DW 		0C000H	; Fx for motor 2      1.1000000000000
; 6
	DW 		09127H  		; Fy for motor 2      1.111

; 8	
	DW 		0C000H  	; Fx for motor 3 
; 10	
	DW 		06ED9H  			; Fy for motor 3