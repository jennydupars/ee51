

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  MOTORS.INC                                ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    NUM_MOTORS          EQU         0003H 
	HOLD_SPEED_VAL 		EQU 		65535D 
	HOLD_ANGLE_VAL		EQU 		-32768D 
	TOTAL_DEGREES		EQU 		360D 		; number of degree angles in a circle 
	
	LASER_ON 			EQU 		01000000B 	; 7th bit of the thing you write to port 3 
	LASER_OFF 			EQU 		00000000B 	; 7th bit not set 
    
    MOTOR_OUT_LOC       EQU         0183H       ; port to output to for controlling motors and laser 