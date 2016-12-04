;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                              QUEUEFUNCTIONS.INC                            ;
;                           Queue Routine Functions                          ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the variable declarations for the event queue being 
; initialized in the main loop. 


;BYTEorWORD      	EQU     0001H       ; compare to passed-in argument to see if 
										; element size shoudl beif 1, it's a byte, if 0, word. 
;ARRAY_MOD_OP    	EQU     0FFFH
;ARRAY_SIZE      	EQU     1000H
;SELECT_BYTE_SIZE	EQU 	0000H 		; size of elements populating transmit ;
											; queue: 0 = byte, 1 = word when passed in;

;qStruc  STRUC
;    array       DB      ARRAY_SIZE      DUP     (?)
;    tail        DW      ?
;    head        DW      ?
;    elsize      DW      ?
;qStruc  ENDS

     
