	NAME		TMRSETUP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;								  Timer Setup                                ;
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

;external function declarations

    EXTRN   KeypadMux:NEAR             ; function for repeatedly checking input 

    
; include files 
;$INCLUDE(handlers.inc)					; include file for handlers, interrupts, timers 
$INCLUDE(timers.inc)

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
    
CallKeypadMux:
    CALL    KeypadMux               ; call KeypadMux to check for inputs 

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




; This program is an event handler that manages interrupt service routines for 
; the procedures for displaying strings on the LED display. The included 
; functions are general enough to be used by functions other than the display 
; functions. The included functions are: 
;   InitTimer - initializes timer 
;   InitCS  - initializes chip select
;   ClrIRQVectors  - installs IllegalEventHandler for all invalid interrupts 
;   IllegalEventHandler - sends EOI to interrupt handler to exit interrupt

								
;	
;	
;
; InitTimer  
;
; Description: 		This function will initialize the timer. The 
;					timer will be initialized to generate interrupts every
;					MS_PER_SEG milliseconds. The interrupt controller is 
;					also initialized here to allow the timer interrupts. 
;					The timer counts MS_PER_SEG long intervals to generate 
;					the interrupts. This function is based on Glen's code. 
;
; Operation:		The appropriate values are written to the timer control 
;					registers in the PCB. The timer count registers are set 
;					to zero. The interrupt controller is set up to accept 
;					timer interrupts and any pending interrupts are cleared
;					by sending a TimerEOI to the interrupt controller. 
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
InitTimer       PROC    NEAR
                PUBLIC  InitTimer
       

                                ;initialize Timer #0 for MS_PER_SEG ms interrupts
        MOV     DX, Tmr0Count   ;initialize the count register to 0
        XOR     AX, AX
        OUT     DX, AL

        MOV     DX, Tmr0MaxCntA ;setup max count for milliseconds per segment
        MOV     AX, COUNTS_PER_MS  ;   count so can time the segments
        OUT     DX, AL

        MOV     DX, Tmr0Ctrl    ;setup the control register, interrupts on
        MOV     AX, Tmr0CtrlVal
        OUT     DX, AL

                                ;initialize interrupt controller for timers
        MOV     DX, INTCtrlrCtrl;setup the interrupt control register
        MOV     AX, INTCtrlrCVal
        OUT     DX, AL

        MOV     DX, INTCtrlrEOI ;send a timer EOI (to clear out controller)
        MOV     AX, TimerEOI
        OUT     DX, AL


        RET                     ;done so return


InitTimer       ENDP

CODE        ENDS
   
    END