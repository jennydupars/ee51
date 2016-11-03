

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  Display                                   ;
;                                Inlude File                                 ;
;                                  EE/CS 51                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the assembly language definitions for the display
; functions for homework 4.

numDigits       EQU     8d                   ; number of LED digits
numSegs         EQU     8d                 ; length of segment buffer
numSegsBytes    EQU     16d                 ; length of segment buffer

maxDispLength   EQU     8                   ; max ////////////////////////////////////

ODD_OR_EVEN_BIT_MASK    EQU  0001H          ; compare this to numbers to test if odd or even

; Specific Digit/LED Definitions

LED_BLANK       EQU     00000000B       ;a blank LED            
IO_LED_LOC      EQU     0FFA4H          ; I/O location of the LED display
IO_LED_VAL      EQU     0               ; value to write to LED display for correct CS

; ASCII constants

ASCII_NULL      EQU     0000H           ; value of null character 
ASCII_BLANK     EQU     ' '
