

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  Display                                   ;
;                                Inlude File                                 ;
;                                  EE/CS 51                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the assembly language definitions for the display
; functions for homework 4.

numDigits       EQU     8                   ; number of LED digits
numSegs         EQU     128                 ; length of segment buffer

; Specific Digit/LED Definitions

LED_BLANK       EQU     00000000B       ;a blank LED            
IO_LED_LOC      EQU     0FFA4H          ; I/O location of the LED display
IO_LED_VAL      EQU     0               ; value to write to LED display for correct CS

; ASCII constants

ASCII_NULL      EQU     0000H           ; value of null character 

