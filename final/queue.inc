;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                              QUEUEFUNCTIONS.INC                            ;
;                           Queue Routine Functions                          ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the variable declarations for the queue functions 
; QueueInit, QueueEmpty, QueueFull, Dequeue, and Enqueue.


BYTE_EL_SIZE      	EQU     0000H       ; if 1, it's a byte, if 0, word. 
										; used to compare to passed-in argument
										; that sets element size of array 
										
ARRAY_SIZE      	EQU     256	 	  	; maximum size of array (bytes)


; qStruc defines the structure of a queue. A queue consists of a tail pointer,
; head pointer, element size variable, and the actual array, which is of size 
; ARRAY_SIZE bytes in capacity. 

qStruc  STRUC
    tail        DW      ?								; tail pointer
    head        DW      ?								; head pointer 
    elsize      DW      ?								; size of element 
	array       DW      ARRAY_SIZE      DUP     (?)		; actual queue 
qStruc  ENDS

     
