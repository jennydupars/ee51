

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  Display                                   ;
;                                Inlude File                                 ;
;                                  EE/CS 51                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the assembly language definitions for the display
; functions for homework 4.

NUM_DIGITS       EQU     8d                   ; number of LED digits


DISPLAY_BUFFER_LENGTH     EQU     64d            ; max length of ascii char display buffer 

maxDispLength   EQU     8                   ; max ////////////////////////////////////

ODD_OR_EVEN_BIT_MASK    EQU  0001H          ; compare this to numbers to test if odd or even

; Specific Digit/LED Definitions

LED_BLANK       EQU     00000000B       ;a blank LED            
IO_LED_LOC      EQU     0FFA4H          ; I/O location of the LED display
IO_LED_VAL      EQU     0               ; value to write to LED display for correct CS

; ASCII constants

ASCII_NULL      EQU     0000H           ; value of null character 
ASCII_BLANK     EQU     ' '
ASCII_CAR_RET	EQU 	13 				; carriage return value, in ASCII

; Scrolling 
SCROLL_POS_MAX_COUNT    EQU     0100H   ; max count we stay at each scroll position 