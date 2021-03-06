	NAME		MAIN
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;								   MAIN LOOP                                 ;
;                           	   Homework 5        		                 ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Description:      This program tests the keypad routine functions and event 
;					handling code for Homework #5. This is the main loop, and 
;                   it initializes the chip select logic, timers, interrupts, 
;                   and keypad code. Then, it calls HW5Test, which 
;					tests the functions defined in keypad.asm. 
;
; Input:            User input to the keypad. 
; Output:           None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; User Interface: 	The user will be able to use a keypad with 4 rows and 4 columns
; 					to provide keypad input to the system.
; Error Handling: 	??????????????????????????????????????????????????????????????????????????????????????
;
; Known Bugs:       None.
;
; Revision History:
;    11/02/2016         Jennifer Du     initial revision
; 	 11/04/2016			Jennifer Du		commenting 


; include files
$INCLUDE(keypad.inc)
$INCLUDE(common.inc)


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP;, SS:STACK

;external function declarations

    ; These are contained in timer handler and event handler and chip select files
    EXTRN   InitCS:NEAR             ; initializes chip select logic
    EXTRN   InitTimer0:NEAR         ; initializes timer 0
    EXTRN   ClrIRQvectors:NEAR      ; installs IllegalEventHandler for relevant 
                                    ; interrupts in the vector table
    EXTRN   InstallTimer0Handler:NEAR; installs event handler for timer 0 interrupts
    
	; a keypad.asm routine 
    EXTRN   InitKeypad:NEAR			; initializes keypad variables

        
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

    CALL    InstallTimer0Handler     ;install the event handler

    CALL    InitTimer0               ;initialize the internal timer

    CALL    InitKeypad				; initialize keypad scanning variables

    STI                             ;and finally allow interrupts.
  

Forever: 
	JMP    Forever                 ;sit in an infinite loop
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