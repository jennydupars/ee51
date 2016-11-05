

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   Keypad                                   ;
;                                Inlude File                                 ;
;                                  EE/CS 51                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the assembly language definitions for the keypad
; functions for homework 5.

; Input locations (read keypad input from here)

IO_KEYPAD_LOC 	EQU 	0FFA8H		; IO location of the keypad 
IO_KEYPAD_VAL 	EQU 	00183H		; value to write to keypad location for correct CS 


; Reading from these locs will give us the keys pressed in each row in the lowest nibble

KEYPAD_LOC		EQU 	080H 		; port number to read from (not including offset)

REPEAT_TIME 	EQU 	1000D 		; 12288 iterations 
PRESS_TIME		EQU 	0050H		; 500 iterations

KEY_MASK		EQU 	000FH 		; will get last 4 bits of keypad value 	
 
NUM_ROWS		EQU 	0004H 		; there are 4 rows 

UNPRESSED_KEY	EQU 	000FH 		; value when no key is pressed 

KEY_PRESS_EVENT EQU 	0001H 		; value stored in AH indicating key event 