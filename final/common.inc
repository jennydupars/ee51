;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  COMMON.INC                                ;
;                                   EE/CS 51                                 ;
;                    Include file for commonly used constants                ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains commonly used constants.

; Common size constants: 
INTVECSIZE 		EQU 		4 			; interrupt vector size is 4 bytes
WORDSIZE        EQU         2       	; 1 word is 2 bytes
BYTESIZE        EQU         1       	; 1 byte is 1 byte 

IS_SET 			EQU 		0001H 		; if something is set, it's set to 1 
NOT_SET 		EQU 		0000H		; if something is not set, equal to 0 

TRUE            EQU         1			; set 
FALSE           EQU         0 				;