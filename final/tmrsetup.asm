	NAME		TMRSETUP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;								  Timer Setup                                ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file includes functions that handle the motor side of the 
; Robotrike. We use timer 0 for interrupts, so these functions are for 
; initializing timer 0.
;
; The included functions are: 
;	Timer0EventHandler - Calls MotorEventHandler at interrupts 
;	InstallTimer0Handler - installs timer event handler for the timer interrupt 
; 	InitTimer0 - initializes timer's max counts, EOI, etc 
; All three functions are public functions.

; Revision History:
;     11/02/16  	Jennifer Du      initial revision
; 	  11/04/16 		Jennifer Du 	 commenting 
; 	  11/30/16 		Jennifer Du 	 adding keypad and display actions to timer event
; 									 handler to manage both 

;external function declarations

   
    EXTRN   MotorEventHandler:NEAR  ; function for repeatedly updating motor speed 
                                    ; and direction and laser status 
; include files 
$INCLUDE(timers.inc)				; constants for setting up timers 
$INCLUDE(intrpvec.inc)				; constants setting up interrupt vector table 
$INCLUDE(common.inc)				; contains commonly used constants 

CGROUP  GROUP   CODE

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP
    
    
  
; Timer0EventHandler 
;
; Description: 		This function is the event handler for the timer 
;					interrupts.  
;
; Operation:		This function calls MotorEventHandler every time an interrupt 
; 					occurs. Then it sends an EOI request to the interrupt controller 
; 					to end the interrupt. 
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

    
Timer0EventHandler       PROC    NEAR
                        PUBLIC  Timer0EventHandler

StartTimer0EventHandler:
    PUSH    AX                      ; save the registers
    PUSH    BX
    PUSH    DX  
	
CallMotorEventHandler: 
	CALL 	MotorEventHandler		; call MotorEventHandler at every interrupt 
									; to update motors and laser status 

EndTimerEventHandler:
    MOV     DX, INTCtrlrEOI         ;send the EOI to the interrupt controller
    MOV     AX, TimerEOI
    OUT     DX, AL                  
    
    POP     DX                      ;restore the registers
    POP     BX
    POP     AX


    IRET                            ;return 

Timer0EventHandler   ENDP

    
;
;
;
; InstallTimer0Handler 
;
; Description: 		This function installs the event handler for the timer 
;					interrupt. 
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
	
InstallTimer0Handler  PROC    NEAR
                     PUBLIC  InstallTimer0Handler

StartInstallTimer0Handler:
        
		XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vectors
        MOV     ES: WORD PTR (INTVECSIZE * Tmr0Vec), OFFSET(Timer0EventHandler)
        MOV     ES: WORD PTR (INTVECSIZE * Tmr0Vec + WORDSIZE), SEG(Timer0EventHandler)

        RET                     ;all done, return
		
InstallTimer0Handler  ENDP




								
;	
;	
;
; InitTimer0  
;
; Description: 		This function will initialize the timer. The 
;					timer will be initialized to generate interrupts every
;					COUNTS_PER_MS milliseconds. The interrupt controller is 
;					also initialized here to allow the timer interrupts. 
;					The timer counts COUNTS_PER_MS long intervals to generate 
;					the interrupts. 
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
InitTimer0       PROC    NEAR
                PUBLIC  InitTimer0
       

                                ;initialize Timer #0 for COUNTS_PER_MS interrupts
        MOV     DX, Tmr0Count   ;initialize the count register to 0
        XOR     AX, AX
        OUT     DX, AL

        MOV     DX, Tmr0MaxCntA ;setup max count to time the segments
        MOV     AX, COUNTS_PER_MS  
        OUT     DX, AL

        MOV     DX, Tmr0Ctrl    ;setup the control register, interrupts on
        MOV     AX, Tmr0CtrlVal
        OUT     DX, AL

                                ;initialize interrupt controller for timers
        MOV     DX, INTCtrlrCtrl;setup the interrupt control register
        MOV     AX, TmrINTCtrlrCVal
        OUT     DX, AL

        MOV     DX, INTCtrlrEOI ;send a timer EOI (to clear out controller)
        MOV     AX, TimerEOI
        OUT     DX, AL


        RET                     ;done so return


InitTimer0       ENDP

CODE        ENDS
   
    END