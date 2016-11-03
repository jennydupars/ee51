

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
numSegs         EQU     8               ? what!!!!!!!!!!!!!!!!!!!!!!~!!!!!!`!!!!

NUM_SEGS        EQU     8               ; number of segments


; Specific Digit/LED Definitions

LED_BLANK       EQU     00000000B       ;a blank LED

COLON_SEG       EQU     0               ;colons are the first segment
COLON_DIGITS    EQU     00000110B       ;colons are in digits 1 and 2

AMPM_MASK       EQU     11000000B       ;mask to check for an AM or PM indicator
AM_MASK         EQU     11000000B       ;mask for the AM indicator.
PM_MASK         EQU     11100000B       ;mask for the PM indicator.

ALARM_SEG       EQU     0               ;Alarm LED is on the first segment
ALARM_DIG_BIT   EQU     00000001B       ;Alarm LED is in digit 0