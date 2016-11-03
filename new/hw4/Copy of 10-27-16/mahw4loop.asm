        NAME    HW4Loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   HW4LOOP                                  ;
;                            Homework #4 Test Code                           ;
;                                  EE/CS  51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Table of Contents:
;	MAIN - main loop that calls the display test functions
; Description:      This program sets up the program through a main loop for the test
;					functions of homework 4.  <INCLUDE MORE IN FUNC SPEC>
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
; Revision History: 10/27/16	Maitreyi Ashok		Wrote the basic structure of the main loop
;					
;    

;definitions

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK



CODE    SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP



;external function declarations

        EXTRN   InitCS:NEAR
        EXTRN   InitTimer:NEAR
        EXTRN   ClrIRQvectors:NEAR
        EXTRN   InstallTimerHandler:NEAR
        EXTRN   DisplayTest:NEAR      ;test function of queue routines


START:  

MAIN:
        MOV     AX, DGROUP          ;initialize the stack pointer
        MOV     SS, AX
        MOV     SP, OFFSET(DGROUP:TopOfStack)

        MOV     AX, DGROUP          ;initialize the data segment
        MOV     DS, AX

        CALL    InitCS
        CALL    ClrIRQvectors
        CALL    InstallTimerHandler
        CALL    InitTimer
        STI
        CALL    DisplayTest
DoneMain:
		JMP		DoneMain        	; After the queue test ends, just continuously 
									; loop until program is stopped
        
CODE    ENDS




;the data segment

DATA    SEGMENT PUBLIC  'DATA'

DATA    ENDS




;the stack

STACK   SEGMENT STACK  'STACK'

                DB      80 DUP ('Stack ')       ;240 words

TopOfStack      LABEL   WORD

STACK   ENDS



        END START