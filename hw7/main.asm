	NAME		MAIN
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;								   MAIN LOOP                                 ;
;                           	   Homework 7        		                 ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Description:      This program tests the functions controlling the serial port and
; 					the event handling code for Homework #7. This is the main loop, 
; 					and it initializes the chip select logic, timers, interrupts, 
;                   and serial port. Then, it calls SerialIOTest, which tests the 
; 					functions defined in serialio.asm. 
;
; Input:            Users specify which characters are input. /////////////////////////// is this right 
; Output:           Characters are output through the serial channel. 
;
; User Interface: 	Users specify which characters are input. 
;
; Algorithms:       None.
; Data Structures:  None.
;
; Limitations: 		Assumes the ASCII character set. 
; Known Bugs:       None.
;
; Revision History:
;    11/18/2016         Jennifer Du     initial revision
; 	 11/20/2016			Jennifer Du		commenting 






CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP

;external function declarations

    ; These are contained in timer handler and event handler files
    
	EXTRN   InitTimer0:NEAR         	; initializes timer 0 ////////////////////////////////////// should i do a different timer 
    EXTRN   ClrIRQvectors:NEAR      	; installs IllegalEventHandler for relevant 
										; interrupts in the vector table
    EXTRN   InstallTimer0Handler:NEAR	; installs event handler for timer 0 interrupts ///////////////////// different timer? 
    
	; test code 
	EXTRN 	SerialIOTest:NEAR 				; test code for serial channel 

	
	; a serialio.asm routine 
    EXTRN   InitSerial:NEAR				; initializes serial channel settings 

        
START:  

MAIN:
	
    MOV     AX, DGROUP              ;initialize the stack pointer
    MOV     SS, AX
    MOV     SP, OFFSET(DGROUP:TopOfStack)

    MOV     AX, DGROUP              ;initialize the data segment
    MOV     DS, AX
    

    
    CALL    ClrIRQVectors           ; initialize interrupt vector table

    CALL    InstallTimer0Handler    ;install the event handler

    CALL    InitTimer0              ;initialize the internal timer
	
    CALL    InitSerial				; initialize serial channel variables 

    STI                             ;and finally allow interrupts.
  

	CALL 	SerialIOTest 
	
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