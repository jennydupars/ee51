        NAME    MAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 HW3 Main loop                              ;
;                                  EE/CS  51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program tests the queue routine functions for Homework
;                   #3.  It calls HW3TEST, which tests each of the functions 
;                   defined in queuefunctions.asm.  If all tests pass, it jumps 
;                   to the label AllTestsGood.  If any test fails it jumps to 
;                   the label TestFailed.
;
; Input:            None.
; Output:           None.
;
; User Interface:   No real user interface.  The user can set breakpoints at
;                   AllTestsGood and TestFailed to see if the code is working
;                   or not.
; Error Handling:   If a test fails the program jumps to TestFailed.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      The returned strings must be less than MAX_STRING_SIZE
;                   characters.
;
; Revision History:
;    10/19/2016         Jennifer Du     initial revision
;	 10/22/2016			Jennifer Du		writing assembly code 


; include files
$INCLUDE(queue.inc)
$INCLUDE(common.inc)



CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP


;external function declarations
    
        EXTRN   QueueTest:NEAR            ; Test code by Glen George

        
START:  

MAIN:
		MOV     AX, DGROUP              ;initialize the stack pointer
        MOV     SS, AX
        MOV     SP, OFFSET(DGROUP:TopOfStack)

        MOV     AX, DGROUP              ;initialize the data segment
        MOV     DS, AX

        
        MOV 	SI, OFFSET(queue)		; initialize the queue and array size
		MOV 	CX, ARRAY_SIZE			
		DEC 	CX						

        CALL QueueTest 					; call the test code
		
        
CODE    ENDS




; the data segment 

DATA        SEGMENT     PUBLIC      'DATA'

    queue   qStruc      < >                

    DATA        ENDS



;the stack

STACK   SEGMENT STACK  'STACK'

        DB      80 DUP ('Stack ')       ;240 words

        TopOfStack      LABEL   WORD

STACK   ENDS

        END         START