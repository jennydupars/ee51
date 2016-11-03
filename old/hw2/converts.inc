;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  CONVERTS.INC                              ;
;                               Conversion Functions                         ;
;                                  Include File                              ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;This file contains the non-magic numbers for convert.

ASCIIa		EQU		65          ; ascii value for 'A' 
ASCII0		EQU		48          ; ascii value for '0' 
ASCIIdash	EQU 	45          ; ascii value for '-'
NULL        EQU     0 			; ascii value for null character

FOURBITS	EQU		4 			; used for shifting 4 bits left or right

TENto4      EQU     2710H		; powers of 10: 10000
TENto3      EQU     03E8H		; powers of 10: 1000
TENto2      EQU     0064H		; powers of 10: 100
TENto1      EQU     000AH		; powers of 10: 10

