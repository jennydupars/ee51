	NAME		MAIN
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;								   MAIN LOOP                                 ;
;                           	   Homework 8        		                 ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program tests the parsing state machine for Homework #8. 
; 					This is the main loop, and it initiates the state machine that
; 					will parse input strings. Then, it calls ParseTest, which 
; 					tests the functions defined in parse.asm, which are responsible
; 					for parsing sample input command strings for the Robotrike. 
;
; Input:            None.
; Output:           The parsing functions call motor routines, which output motor
; 					movement to the Robot. 
;
; User Interface: 	None. 
;
; Algorithms:       Finite state machine. 
; Data Structures:  None.
;
; Limitations: 		Assumes the ASCII character set. 
; Known Bugs:       None.
;
; Revision History:
;    11/23/2016         Jennifer Du     initial revision
; 	 11/26/2016 		Jennifer Du 	wrote assembly code 
; 	 11/27/2016			Jennifer Du		added comments 


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP

;external function declarations
    
	; test code written by Glen George 
	EXTRN 	ParseTest:NEAR 					
	
	; code that initializes parsing state machine
	EXTRN   InitializeStateMachine:NEAR     
    
            
START:  

MAIN:
	
    MOV     AX, DGROUP              ; initialize the stack pointer
    MOV     SS, AX
    MOV     SP, OFFSET(DGROUP:TopOfStack)

    MOV     AX, DGROUP              ; initialize the data segment
    MOV     DS, AX

    CALL    InitializeStateMachine	; initialize state machine 

	CALL 	ParseTest				; call test code 
	
Forever: 
	JMP    Forever                  ; sit in an infinite loop
        HLT                             
   
CODE    ENDS

; the data segment 
; initialized but empty so we can set up DGROUP 
DATA        SEGMENT     PUBLIC      'DATA'
DATA        ENDS

;the stack
STACK   SEGMENT STACK  'STACK'
        DB      80 DUP ('Stack ')       ;240 words
        TopOfStack      LABEL   WORD
STACK   ENDS

        END         START