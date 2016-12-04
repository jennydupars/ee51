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
; Input:            Users can specify which characters are input. 
; Output:           Characters are output through the serial channel. 
;
; User Interface: 	Users specify which characters are input, and these characters
; 					are transmitted through the serial channel. In this program,
; 					users interface with the serial channel through the RealTerm
; 					program to input characters and see the serial channel's output.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Limitations: 		Assumes the ASCII character set. 
; Known Bugs:       None.
;
; Revision History:
;    11/18/2016         Jennifer Du     initial revision
; 	 11/19/2016			Jennifer Du		commenting 


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP

;external function declarations

    ; These are contained in INT2 handler and event handler and chip select files
    EXTRN   InitCS:NEAR             	; initializes chip select logic
    EXTRN   ClrIRQvectors:NEAR      	; installs IllegalEventHandler for relevant 
										; interrupts in the vector table
	EXTRN   InitINT2:NEAR         	    ; initializes INT2 interrupts
    EXTRN   InstallINT2Handler:NEAR		; installs event handler for INT2 interrupts
    
	; test code 
	EXTRN 	SerialIOTest:NEAR 			; test code for serial channel routines 
	
	; a serialio.asm routine 
    EXTRN   InitSerial:NEAR				; initializes serial channel settings  

        
START:  

MAIN:
	
    MOV     AX, DGROUP              ; initialize the stack pointer
    MOV     SS, AX
    MOV     SP, OFFSET(DGROUP:TopOfStack)

    MOV     AX, DGROUP              ; initialize the data segment
    MOV     DS, AX
    

    CALL    InitCS                  ; initialize the 80188 chip selects
                                    ;   assumes LCS and UCS already setup

    CALL    ClrIRQVectors           ; initialize interrupt vector table

    CALL    InstallINT2Handler      ; install the event handler for INT2 
    CALL    InitINT2                ; initialize the INT2 interrupt 
	
    CALL    InitSerial				; initialize serial channel 

    STI                             ; and finally allow interrupts.
  
	CALL 	SerialIOTest 			; call test code 
	
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