	NAME		TMRHNDLR
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;								 TIMER HANDLERS                              ;
;                           	   Homework 4        		                 ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file includes . The included 
; functions are: 
;	TimerEventHandler - calls DisplayMUX repeatedly to sustain display 
;	InstallTimerHandler - installs timer event handler for the timer interrupt 

; Revision History:
;     10/27/16  	Jennifer Du      initial revision

;external function declarations

    EXTRN   DisplayMux:NEAR             ; multiplexing function for LED display

    
$INCLUDE(handlers.inc)					; include file for handlers, interrupts, timers 
;$INCLUDE(display.inc)					; optional, used in timer event handelr


CGROUP  GROUP   CODE

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP
    
    
    
; TimerEventHandler 
;
; Description: 		This function is the event handler for the timer 
;					interrupts. It outputs the next pattern 
;					to the LED display by calling DisplayMux whenever 
;					interrupted. 
;
; Operation:		This function calls DisplayMux, which displays the 
;					current digit to be displayed, as stored by the variable 
;					currentSeg. 	
;
; Arguments:		None.
; Return Value:		None.
; Local Variables:	None. 
; Shared Variables: None. 
; Global Variables: None. 
; Input:			None. 
; Output:			A digit will be displayed on the LED display.
; Error Handling:	None.
; Algorithms:		None.
; Data Structures: 	None.
;

    
TimerEventHandler       PROC    NEAR
                        PUBLIC  TimerEventHandler

StartTimerEventHandler:
    PUSH    AX                      ; save the registers
    PUSH    BX
    PUSH    DX  

;UpdateScrollPos:
	;CMP 	stringLength, numDigits (8)
	;JLE 	CallDisplayMux
	; if string length is greater than 8: we can do scrolling 

	;IN 	AL, Tmr0Count
	;CMP 	Tmr0Count, 0
	;JNE 	CallDisplayMux
	
	;JE 	this next stuff: update scroll count, count times it's muxed so we can see when to update scroll position 
	;INC 	scrollCnt
	;CMP 	scrollCnt, UPDATE_SCROLL_POS_VALUE ; update scroll count after an amount of muxes 
	;JNE 	CallDisplayMux
	
	;JE 	this next stuff: 
	;CALL 	UpdateScrollPos (just increments the scroll position)
	; then DisplayMux
    
CallDisplayMux:
    CALL    DisplayMux              ; call DisplayMux once to flash one digit

EndTimerEventHandler:
    MOV     DX, INTCtrlrEOI         ;send the EOI to the interrupt controller
    MOV     AX, TimerEOI
    OUT     DX, AL                  
    
    POP     DX                      ;restore the registers
    POP     BX
    POP     AX


    IRET                            ;return (Event Handlers end with IRET not RET)

TimerEventHandler   ENDP

    
;
;
;
; InstallTimerHandler 
;
; Description: 		This function installs the event handler for the timer 
;					interrupt. It is based on Glen's code. 
;			
; Operation:		The event handler address is written to the timer 
;					interrupt vector. 
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
;	
	
InstallTimerHandler  PROC    NEAR
                     PUBLIC  InstallTimerHandler

StartInstallTimerHandler:
        
		XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * Tmr0Vec), OFFSET(TimerEventHandler)
        MOV     ES: WORD PTR (4 * Tmr0Vec + 2), SEG(TimerEventHandler)

        RET                     ;all done, return
		
InstallTimerHandler  ENDP


CODE        ENDS
   
    END