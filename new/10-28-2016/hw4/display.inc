

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  Display                                   ;
;                                Inlude File                                 ;
;                                  EE/CS 51                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the assembly language definitions for the display
; functions for homework 4.

numDigits       EQU     8               ; number of LED digits
numSegs         EQU     8               ; length of segment buffer

; Specific Digit/LED Definitions

LED_BLANK       EQU     00000000B       ;a blank LED

