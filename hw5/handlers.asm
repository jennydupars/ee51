	NAME		EVTHNDLR
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;								 EVENT HANDLERS                              ;
;                           	   Homework 5        		                 ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file includes functions that handle interrupts and timing for the keypad. 
; The included functions are: 
;	TimerEventHandler - calls KeypadMux at interrupts to repeatedly check for input 
;	InstallTimerHandler - installs timer event handler for the timer interrupt 

; Revision History:
;     11/02/16  	Jennifer Du      initial revision

    
; include files 
$INCLUDE(handlers.inc)					; include file for handlers, interrupts, timers 
$INCLUDE(keypad.inc)


CGROUP  GROUP   CODE

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP
    
    

;	
; ClrIRQVectors  
;
; Description: 		This functions installs the IllegalEventHandler for all
;              		interrupt vectors in the interrupt vector table.  Note
;              		that all 256 vectors are initialized so the code must be
;                   located above 400H.  The initialization skips  (does not
;                   initialize vectors) from vectors FIRST_RESERVED_VEC to
;                   LAST_RESERVED_VEC. This code is modelled after Glen's code.
;
; Arguments:		None.
; Return Value:		None.
;
; Local Variables:	CX - vector counter 
;					ES:SI - pointer to vector table 
; Shared Variables: None.
; Global Variables: None.
; Input:			None. 
; Output:			None. 
; Error Handling:	None.
; Algorithms:		None. 
; Data Structures: 	None. 
;
ClrIRQVectors   PROC    NEAR
                PUBLIC  ClrIRQVectors

InitClrVectorLoop:              ;setup to store the same handler 256 times

        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
        MOV     SI, 0           ;initialize SI to the first vector

        MOV     CX, 256         ;up to 256 vectors to initialize


ClrVectorLoop:                  ;loop clearing each vector
                                ;check if should store the vector
        CMP     SI, 4 * FIRST_RESERVED_VEC
        JB      DoStore         ;if before start of reserved field - store it
        CMP     SI, 4 * LAST_RESERVED_VEC
        JBE     DoneStore       ;if in the reserved vectors - don't store it
        ;JA     DoStore         ;otherwise past them - so do the store

DoStore:                        ;store the vector
        MOV     ES: WORD PTR [SI], OFFSET(IllegalEventHandler)
        MOV     ES: WORD PTR [SI + 2], SEG(IllegalEventHandler)

DoneStore:                      ;done storing the vector
        ADD     SI, 4           ;update pointer to next vector

        LOOP    ClrVectorLoop   ;loop until have cleared all vectors
        ;JMP    EndClrIRQVectors;and all done


EndClrIRQVectors:               ;all done, return
        RET


ClrIRQVectors   ENDP
							
							
							
;
;				
;				
; IllegalEventHandler 
;
; Description: 		This function will be modelled after Glen's code. This  
;					function is the event handler for illegal (uninitialized)
;					interrupts. It is called when an illegal interrupt occurs.
;
; Operation:		When this function is called, nothing happens, except that
;					it sends a non-specific EOI and returns. 
;
; Arguments:		None.
; Return Value:		None. 
; Local Variables:	None.
; Shared Variables: None.
; Global Variables: None.
; Input:			None. 
; Output:			None. 
; Error Handling:	None.
; Algorithms:		None.
; Data Structures: 	None.

IllegalEventHandler     PROC    NEAR
                        PUBLIC  IllegalEventHandler

        NOP                             ;do nothing (can set breakpoint here)

        PUSH    AX                      ;save the registers
        PUSH    DX

        MOV     DX, INTCtrlrEOI         ;send a non-sepecific EOI to the
        MOV     AX, NonSpecEOI          ;   interrupt controller to clear out
        OUT     DX, AL                  ;   the interrupt that got us here

EndIllegalEventHandler:
        POP     DX                      ;restore the registers
        POP     AX

        IRET                            ;and return


IllegalEventHandler     ENDP


CODE        ENDS
   
    END