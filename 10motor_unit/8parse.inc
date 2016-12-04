;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    PARSE                                   ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;
; State definitions for the parsing state machine 
; 

ST_INITIAL 				EQU 		0		; initial/idle state 

	; Set speed (S)    					; transitions occur when:
ST_SPEED				EQU 		1 		; 'S' is read 
ST_SPEED_SIGN			EQU 		2 		; sets sign: '+' or '-' after 'S'
ST_SPEED_NUM			EQU 		3		; numerical value after 'S', 'S+','S-'

	; Set relative speed (V)
ST_REL_SPEED			EQU 		4 		; 'V' is read 
ST_REL_SPEED_SIGN		EQU			5 		; sets sign: '+' or '-' after 'V' 
ST_REL_SPEED_NUM		EQU			6		; numerical value after 'V', 'V+', 'V-'

	; Set direction (D)
ST_DIR					EQU			7		; 'D' is read 
ST_DIR_SIGN				EQU			8 		; sets sign: '+' or '-' after 'D' 
ST_DIR_NUM				EQU			9 		; numerical value after 'D', 'D+', 'D-'

	; Set turret angle (T)				; these two states are for absolute turret rotation
ST_LAS_ANG				EQU 		10 		; 'R' is read 
ST_LAS_ANG_NUM			EQU 		11 		; numerical value following 'R'
										; these set relative turret rotation 
ST_LAS_ANG_REL			EQU			12		; sets sign: '+' or '-' after 'R' 
ST_LAS_ANG_REL_NUM		EQU			13		; numerical value following a sign symbol 
	
	; Set turret elevation (E)
ST_LAS_ELV				EQU			14		; when 'E' is read 
ST_LAS_ELV_SIGN			EQU			15		; when '+' or '-' follows 'E'
ST_LAS_ELV_NUM			EQU			16		; numerical value after 'E', 'E+', or 'E-' 

	; Fire laser (turn laser on) (F)
ST_LAS_ON				EQU			17		; when 'F' is read 
	
	; Turn off laser 	(O)
ST_LAS_OFF 				EQU			18		; when 'O' is read

ST_ERROR                EQU         19 		; error state - invalid tokens at a state

NUM_STATES 				EQU 		20		; total number of states 


;
; Tokens			; the types of inputs we will sort all ASCII characters into 
;

TOKEN_NUM				EQU 		0		; any numerical value 0-9 
TOKEN_SIGN				EQU 		1		; '+' or '-' 
TOKEN_EOS				EQU 		2		; carriage return - marks end of a command 
TOKEN_S					EQU 		3		; 'S' or 's' - set speed command 
TOKEN_V 				EQU 		4		; 'V' or 'v' - set relative speed command 
TOKEN_D 				EQU 		5		; 'D' or 'd' - set direction command 
TOKEN_T					EQU 		6		; 'T' or 't' - set turret rotation command 
TOKEN_E 				EQU 		7		; 'E' or 'e' - set turret elevation command 
TOKEN_F 				EQU 		8		; 'F' or 'f' - fire laser command 
TOKEN_O 				EQU 		9		; 'O' or 'o' - turn laser off command 
TOKEN_OTHER 			EQU 		10		; anything other non-special ASCII character 
TOKEN_SPACE				EQU 		11 		; space characters - space, tab

NUM_TOKEN_TYPES 		EQU 		12		; total number of token categories 


; Error handling constants 
PARSE_ERROR_VAL         EQU         1 		; non-zero return value to indicate error
NO_PARSE_ERROR_VAL		EQU 		0 		; zero return value indicates successful parsing


; Constants used for sign setting and getting 
NEG_SIGN_VAL			EQU 		-1 		; multiplier for negative values 
POS_SIGN_VAL 			EQU 		1 		; multiplier for positive values 

POSITIVE_ASCII_SIGN     EQU         '+'		; identifier for positive ASCII characters


; Laser output functions
LASER_ON 				EQU 		1		; laser on value 
LASER_OFF 				EQU 		0		; laser off value 


; Turret output functions 
MAX_TUR_ELV_VAL			EQU 		60 		; Maximum value of turret elevation (deg)


; Motor speed and direction values 
HOLD_SPEED_VAL			EQU 		65535 	; designated speed used to indicate no change 
HOLD_ANGLE_VAL          EQU         32768	; designated angle used to indicate no change 
MAX_MOTOR_SPEED         EQU         65534 	; maximum motor speed 
MIN_MOTOR_SPEED      	EQU         0 		; minimum motor speed 


TOKEN_MASK				EQU			01111111B	;mask high bit of token for lookup 


TOTAL_DEGREES           EQU         360			; total degree angles in a circle 

