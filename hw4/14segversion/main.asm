	NAME		MAIN
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;								   MAIN LOOP                                 ;
;                           	   Homework 4        		                 ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Description:      This program tests the display routine functions and event 
;					handling code for Homework #4. This is the main loop, and 
;                   it initializes the chip select logic, timers, interrupts, 
;                   and display code. Then, it calls DisplayTest, which 
;					tests each of the functions defined in display.asm. 
;
; Input:            None.
; Output:           None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
;
; Revision History:
;    10/27/2016         Jennifer Du     initial revision
; 	 10/29/2016			Jennifer Du 	commenting 


; include files
$INCLUDE(display.inc)
$INCLUDE(common.inc)


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP, SS:STACK

;external function declarations

    ; These are contained in timer handler and event handler files
    EXTRN   InitCS:NEAR             ; initializes chip select logic
    EXTRN   InitTimer:NEAR          ; initializes timer
    EXTRN   ClrIRQvectors:NEAR      ; intalls IllegalEventHandler for relevant 
                                    ; interrupts in the vector table
    EXTRN   InstallTimerHandler:NEAR; installs event handler for timer interrupt
    EXTRN   IllegalEventHandler:NEAR
    EXTRN   InitDisplay:NEAR
    
    ; This was written by Prof. George
    EXTRN   DisplayTest:NEAR        ; test function for display routines 
    
        
START:  

MAIN:
	
    MOV     AX, DGROUP              ;initialize the stack pointer
    MOV     SS, AX
    MOV     SP, OFFSET(DGROUP:TopOfStack)

    MOV     AX, DGROUP              ;initialize the data segment
    MOV     DS, AX
    

    CALL    InitCS                  ;initialize the 80188 chip selects
                                    ;   assumes LCS and UCS already setup

    CALL    ClrIRQVectors           ; initialize interrupt vector table

    CALL    InstallTimerHandler     ;install the event handler
                                    ;   ALWAYS install handlers before
                                    ;   allowing the hardware to interrupt.

    CALL    InitTimer               ;initialize the internal timer

    CALL    InitDisplay				;clear display and initialize muxing variables

    STI                             ;and finally allow interrupts.
    

    CALL    DisplayTest 	    		; call the test code

Forever: 
JMP    Forever                 ;sit in an infinite loop, nothing to
                                        ;   do in the background routine
        HLT                             ;never executed (hopefully)
        
        
		
        
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