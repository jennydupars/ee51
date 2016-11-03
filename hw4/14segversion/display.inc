

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  Display                                   ;
;                                Inlude File                                 ;
;                                  EE/CS 51                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the assembly language definitions for the display
; functions for homework 4.

numDigits       EQU     8d                  ; number of LED digits
numSegs         EQU     8d                  ; length of segment buffer
numSegsBytes    EQU     16d                 ; length of segment buffer

maxDispLength   EQU     8                   ; maximum display length 


; Specific Digit/LED Definitions

LED_BLANK       EQU     00000000B       ;a blank LED            
IO_LED_LOC      EQU     0FFA4H          ; I/O location of the LED display
IO_LED_VAL      EQU     0               ; value to write to LED display for correct CS

HIGH_BYTE_ADDRESS	EQU	0008H			; I/O location for high byte for 14-seg display 

; ASCII constants

ASCII_NULL      EQU     0000H           ; value of null character 
ASCII_BLANK     EQU     ' '
DISPLAY_NULL	EQU		0000H			; displaying null character 