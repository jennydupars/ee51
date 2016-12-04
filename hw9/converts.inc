
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  CONVERTS.INC                              ;
;                               Conversion Functions                         ;
;                                  Include File                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;This file contains the non-magic numbers for convert.

; constants used in both:

ASCIIa		EQU		65          ; ascii value for 'A' 
ASCII0		EQU		48          ; ascii value for '0' 
ASCIIdash	EQU 	45          ; ascii value for '-'
NULL        EQU     0 			; ascii value for null character

; no magic numbers for BX counter
bFIVE       EQU     0005H
bFOUR       EQU     0004H
bTHREE      EQU     0003H
bTWO        EQU     0002H
bONE        EQU     0001H
ZERO        EQU     0000H



; constants used in Dec2String:

TENto4      EQU     2710H		; powers of 10: 10000
TENto3      EQU     03E8H		; powers of 10: 1000
TENto2      EQU     0064H		; powers of 10: 100
TENto1      EQU     000AH		; powers of 10: 10

SIGN_BIT_MASK   EQU    1000000000000000B     ; test first bit for 1 or 0



; constants used in Hex2String:

FOURBITS	EQU		4 			; used for shifting 4 bits left or right

FIRST4BITS  EQU     0F000H      ; gets first 4 digits of numbers compared to it
TEN         EQU     000AH       ; for use when comparing numbers to 10