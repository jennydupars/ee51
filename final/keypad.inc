

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   Keypad                                   ;
;                                Include File                                ;
;                                  EE/CS 51                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the assembly language definitions for the keypad
; functions.

; Input locations (read keypad input from here)

KEYPAD_LOC		EQU 	080H 		; port number to read from (not including offset)

; Timing definitions: how many iterations of interrupts and checking keypad for 
; presses will occur before different types of key presses are registered

REPEAT_TIME 	EQU 	1000D 		; 1000 interrupts per repeat -> 1 repeat per sec
PRESS_TIME		EQU 	80D			; 80 iterations

; Keypad constants and event values 
KEY_MASK		EQU 	0000000000001111B   
									; will get last 4 bits of keypad value
									; (relevant value for key identification
									; in a row)
											
NUM_ROWS		EQU 	4D   		; there are 4 rows in keypad 
UNPRESSED_KEY	EQU 	000FH 		; value of keypad memory loc when no key pressed

