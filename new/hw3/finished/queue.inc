;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                              QUEUEFUNCTIONS.INC                            ;
;                           Queue Routine Functions                          ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the variable declarations for the queue functions 
; QueueInit, QueueEmpty, QueueFull, Dequeue, and Enqueue.


BYTEorWORD      EQU     0001H         ; if 1, it's a byte, if 0, word. 
ARRAY_MOD_OP    EQU     0FFFH
ARRAY_SIZE      EQU     1000H

qStruc  STRUC
    array       DB      ARRAY_SIZE      DUP     (?)
    tail        DW      ?
    head        DW      ?
    elsize      DW      ?
qStruc  ENDS

     
