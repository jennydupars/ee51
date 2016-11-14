

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  MOTORS.INC                                ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    NUM_MOTORS          EQU     0003H 		; number of motors used for movement 
	HOLD_SPEED_VAL 		EQU 	0FFFFH      ; number that indicates speed should not be changed
	HOLD_ANGLE_VAL		EQU 	08000H      ; number that indicates angle should not be changed 
	TOTAL_DEGREES		EQU 	00168H      ; number of degree angles in a circle (360D)
	
	LASER_ON 			EQU 	10000000B 	; 7th bit of the motor control byte set for laser on
	LASER_OFF 			EQU 	00000000B 	; 7th bit not set 
    
    MOTOR_OUT_LOC       EQU     0181H       ; port to output to for controlling motors and laser 
    
    NEG_SIGN_SET        EQU     10000000B   ; mask to see if 7th bit is set (negative value) 
    
    PWM_MAX_COUNT_VAL   EQU     0007FH      ; maximum count of pwm cycle(127D)