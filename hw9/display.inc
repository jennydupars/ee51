

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  Display                                   ;
;                                Inlude File                                 ;
;                                  EE/CS 51                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the assembly language definitions for the display
; functions.

NUM_DIGITS              EQU     8d            ; number of LED digits

DISPLAY_BUFFER_LENGTH   EQU     64d           ; max length of ascii char display buffer


; Specific Digit/LED Definitions

LED_BLANK               EQU     00000000B   ;a blank LED            


; Display Port locations 
HIGH_SEG_CODE_ADDRESS 	EQU 	0008H 		; high byte in 14-seg codes go here 


; ASCII constants

ASCII_NULL      EQU     0000H           	; ASCII value of null character 
ASCII_BLANK     EQU     ' '             	; ASCII value of blank space 
ASCII_CAR_RET	EQU 	13 					; ASCII value of carriage return 

; Scrolling 
SCROLL_POS_MAX_COUNT    EQU     0100H   	; max count we stay at each scroll position 