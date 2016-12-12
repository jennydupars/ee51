NAME 	INITPP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;					    Initialize Parallel Ports - Motors                   ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; The function included in this file is for initializing the parallel port so 
; that we can output motor settings to it: 
; 		InitPP - initializes parallel port

; Revision History:
;     11/09/16  	Jennifer Du      initial revision
    
; include files 
$INCLUDE(initpp.inc)					; include file for initializing parallel port


CGROUP  GROUP   CODE

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP
;	
;	
;	
; InitPP  
;
; Description: 		This function will initialize the parallel port on the 80188 
; 					and set it to mode 0.
;
; Operation:		This writes the value to the parallel port control register 
; 					making it possible to communicate with the parallel ports. 
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


InitPP  PROC    NEAR
        PUBLIC  InitPP

        MOV     DX, ParallelPortCtrlReg     ;setup to write to control register
        MOV     AX, ParallelPortVal
        OUT     DX, AL          			;write ParallelPortVal to register 


        RET                     ;done so return

InitPP  ENDP

CODE        ENDS
   
    END