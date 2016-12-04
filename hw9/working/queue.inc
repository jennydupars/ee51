;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                              QUEUEFUNCTIONS.INC                            ;
;                           Queue Routine Functions                          ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the variable declarations for the queue functions 
; QueueInit, QueueEmpty, QueueFull, Dequeue, and Enqueue.


BYTE_EL_SIZE      EQU     0000H         ; if 1, it's a byte, if 0, word. 
ARRAY_SIZE      EQU     256	 	  ; maximum size of array (256)

qStruc  STRUC
    array       DB      ARRAY_SIZE      DUP     (?)		; actual queue 
    tail        DW      ?								; tail pointer
    head        DW      ?								; head pointer 
    elsize      DW      ?								; size of element 
qStruc  ENDS

     