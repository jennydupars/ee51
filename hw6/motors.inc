

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  MOTORS.INC                                ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    NUM_MOTORS          EQU         0003H 
	HOLD_SPEED_VAL 		EQU 		0FFFFH      ; 65535D 
	HOLD_ANGLE_VAL		EQU 		08000H      ; -32768D 
	TOTAL_DEGREES		EQU 		00168H      ;360D 		; number of degree angles in a circle 
	
	LASER_ON 			EQU 		10000000B 	; 7th bit of the thing you write to port 3 
	LASER_OFF 			EQU 		00000000B 	; 7th bit not set 
    
    MOTOR_OUT_LOC       EQU         0181H       ; port to output to for controlling motors and laser 
    
    NEG_SIGN_SET        EQU         10000000B   ; 7th bit is set (negative value) 
    
    PWM_MAX_COUNT_VAL   EQU         0007FH      ; 127B 