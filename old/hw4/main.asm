	NAME		MAIN
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;								   MAIN LOOP                                 ;
;                           	   Homework 4        		                 ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


You will need to write a main loop to test your code. This just initializes the 
chip select logic, timers, interrupts, and display code then calls the 
DisplayTest procedure.

; Description:      This program tests the display routine functions and event 
;					handling code for Homework #4. It calls HW4TEST, which 
;					tests each of the functions defined in display.asm. 
;
; Input:            None.
; Output:           None.
;
; User Interface:   
; Error Handling:   
;
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      
;
; Revision History:
;    10/27/2016         Jennifer Du     initial revision


; include files
$INCLUDE(display.inc)
$INCLUDE(common.inc)



CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP


;external function declarations
    
        EXTRN   HW4TEST:NEAR            ; Test code by Glen George

        
START:  

MAIN:
		MOV     AX, STACK               ;initialize the stack pointer
        MOV     SS, AX
        MOV     SP, OFFSET(TopOfStack)

        MOV     AX, DATA                ;initialize the data segment
        MOV     DS, AX

		
		
        CALL    InitCS                  ;initialize the 80188 chip selects
                                        ;   assumes LCS and UCS already setup

        CALL    ClrIRQVectors           ;clear (initialize) interrupt vector table

                                        ;initialize the variables for the timer event handler
        MOV     Digit, 0                ;start on digit 0
        MOV     Segmnt, 0               ;start with segment pattern 0

        CALL    InstallHandler          ;install the event handler
                                        ;   ALWAYS install handlers before
                                        ;   allowing the hardware to interrupt.

        CALL    InitTimer               ;initialize the internal timer
        STI                             ;and finally allow interrupts.

Forever: JMP    Forever                 ;sit in an infinite loop, nothing to
                                        ;   do in the background routine
        HLT                             ;never executed (hopefully)
        
        CALL HW4Test 					; call the test code
		
        
CODE    ENDS




; the data segment 

DATA        SEGMENT     PUBLIC      'DATA'

    

    DATA        ENDS



;the stack

STACK   SEGMENT STACK  'STACK'

        DB      80 DUP ('Stack ')       ;240 words

        TopOfStack      LABEL   WORD

STACK   ENDS

        END         START