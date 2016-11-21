	NAME		INT2
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;						      INT2 Interrupt Setup                           ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file includes functions that handle the INT2 interrupts. The functions 
; included in this file are: 
;   InitINT2 - initializes the INT2 interrupts
;   INT2EventHandler - event handler when INT2 interrupts arise 
;   InstallINT2Handler - installs event handler 

; Revision History:
;     11/19/16  	Jennifer Du      initial revision
    
; include files 
$INCLUDE(int2.inc)				; contains constants for setting up INT2 interrupts 


CGROUP  GROUP   CODE

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP
      
    ;external function declarations
    EXTRN   SerialEventHandler:NEAR  
    
    
    
; INT2EventHandler 
;
; Description: 		This function is the event handler for the INT2 interrupts. It 
; 					calls SerialEventHandler every time an INT2 interrupt occurs. 
;
; Operation:		This function calls SerialEventHandler every time an interrupt 
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

    
INT2EventHandler       	PROC    NEAR
                        PUBLIC  INT2EventHandler

StartINT2EventHandler:
    PUSH    AX                      ; save the registers
    PUSH    BX
    PUSH    DX  
	
CallSerialEventHandler: 
	CALL 	SerialEventHandler		; call SerialEventHandler at every interrupt to 
									; manage different types of events 
EndINT2EventHandler:
    MOV     DX, INTCtrlrEOI         ;send the EOI to the interrupt controller 
    MOV     AX, INT2EOI
    OUT     DX, AL                  
    
    POP     DX                      ;restore the registers
    POP     BX
    POP     AX

    IRET                            ;return 
INT2EventHandler   ENDP
   
;
;
;
; InstallINT2Handler 
;
; Description: 		This function installs the event handler for the INT2
;					interrupt. 
;			
; Operation:		The event handler address is written to the INT2 interrupt 
; 					vector. Since each interrupt vector takes the space of 2 
; 					words, or 4 bytes, we multiply the vector value by 4 to get
; 					to the address, and then store the address of the event 
; 					handler there. This way, when the INT2 interrupt occurs, the 
;					program will automatically jump to the INT2 event handler. 
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
	
InstallINT2Handler  	PROC    NEAR
						PUBLIC  InstallINT2Handler

StartInstallTimer0Handler:
        
		XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vectors
								; since each vector takes up 4 bytes, we multiply
								; vector number by 4 to get address 
								; then store segment offset of event handler 
        MOV     ES: WORD PTR (4 * INT2Vec), OFFSET(INT2EventHandler)
								; increment by 2 to get to the next word
								; then store segment of event handler 
        MOV     ES: WORD PTR (4 * INT2Vec + 2), SEG(INT2EventHandler)

        RET                     ;all done, return
		
InstallINT2Handler  ENDP
								
;	
;	
;
; InitINT2
;
; Description: 		This function will initialize the INT2 interrupt. The interrupt 
; 					controller is also initialized here to allow INT2 interrupts. 
;
; Operation:		The appropriate values are written to the INT2 control 
;					registers in the PCB. The interrupt controller is set up to accept 
;					INT2 interrupts, and any pending interrupts are cleared
;					by sending an INT2EOI to the interrupt controller. 
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
InitINT2       	PROC    NEAR
                PUBLIC  InitINT2
                                ;initialize interrupt controller for INT2 interrupts 
        MOV     DX, INT2CtrlrCtrl;setup the interrupt control register
        MOV     AX, INTCtrlrCVal
        OUT     DX, AL

        MOV     DX, INTCtrlrEOI ;send an INT2 EOI (to clear out controller)
        MOV     AX, INT2EOI
        OUT     DX, AL
		
        RET                     ;done so return
InitINT2       ENDP

CODE        ENDS
   
    END