

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  MOTORS.INC                                ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    NUM_MOTORS          EQU     3 			; number of motors used for movement 
	HOLD_SPEED_VAL 		EQU 	65535       ; number that indicates speed should not be changed
	HOLD_ANGLE_VAL		EQU 	32768       ; number that indicates angle should not be changed 
	TOTAL_DEGREES		EQU 	360 	    ; number of degree angles in a circle
	
	LASER_ON 			EQU 	10000000B 	; 7th bit of the motor control byte set for laser on
	LASER_OFF 			EQU 	00000000B 	; 7th bit not set 
    
    MOTOR_OUT_LOC       EQU     0181H       ; port to output to for controlling motors and laser 
    
    NEG_SIGN_SET        EQU     10000000B   ; mask to see if 7th bit is set (negative value) 
    
    PWM_MAX_COUNT_VAL   EQU     127         ; maximum count of pwm cycle
    
    
    ; the laser elevation location, port c, 7th (highest) bit 
	LASER_ELV_LOC 		EQU 	0182H 		; port C location 
	LASER_ELV_ON 		EQU 	10000000B 	; 7th bit controls elevation 
	LASER_ELV_OFF 		EQU 	00000000B 	; off means laser elevation goes down 