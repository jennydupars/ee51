	NAME		MAIN
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;								   MAIN LOOP                                 ;
;                           	   Homework 6        		                 ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Description:      This program tests the motor routine functions and event 
;					handling code for Homework #6. This is the main loop, and 
;                   it initializes the chip select logic, timers, interrupts, 
;                   parallel port, and motor variables. Then, it calls MotorTest, 
; 					which tests the functions defined in motors.asm. 
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
;    11/08/2016         Jennifer Du     initial revision
; 	 11/12/2016			Jennifer Du		commenting 


; include files
$INCLUDE(motors.inc)



CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP;, SS:STACK

;external function declarations

    ; These are contained in timer handler and event handler and chip select files
    EXTRN   InitCS:NEAR             	; initializes chip select logic
    EXTRN   InitTimer0:NEAR         	; initializes timer 0
    EXTRN   ClrIRQvectors:NEAR      	; installs IllegalEventHandler for relevant 
										; interrupts in the vector table
	EXTRN 	InitPP:NEAR 				; initializes parallel port 
    EXTRN   InstallTimer0Handler:NEAR	; installs event handler for timer 0 interrupts
    
	; test code 
	EXTRN 	MotorTest:NEAR 				; test code for motor routines 
	
	; a motors.asm routine 
    EXTRN   InitRobot:NEAR				; initializes robot settings 

        
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

    CALL    InstallTimer0Handler    ;install the event handler

    CALL    InitTimer0              ;initialize the internal timer

	CALL 	InitPP 					; initialize parallel ports 
	
    CALL    InitRobot				; initialize robot motor and laser variables

    STI                             ;and finally allow interrupts.
  

	CALL 	MotorTest 
	
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