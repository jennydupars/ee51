	NAME 	INITCS
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;					     Initialize Chip Select - Motors                     ;
;                           	   Homework 6        		                 ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; The function included in this file is for initializing chip select for the keypad: 
; 		InitCS - initializes chip select 

; Revision History:
;     11/09/16  	Jennifer Du      initial revision

;external function declarations



    
; include files 
$INCLUDE(initcs.inc)					; include file for initializing chip select 


CGROUP  GROUP   CODE

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP
;	
;	
;	
; InitCS  
;
; Description: 		This function will initialize the peripheral chip 
;					selects on the 80188. 
;
; Operation:		This writes the initial values to the PACS and 
;					MPCS registers.
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


InitCS  PROC    NEAR
        PUBLIC  InitCS

        MOV     DX, PACSreg     ;setup to write to PACS register
        MOV     AX, PACSval
        OUT     DX, AL          ;write PACSval to PACS (base at 0, 3 wait states)

        MOV     DX, MPCSreg     ;setup to write to MPCS register
        MOV     AX, MPCSval
        OUT     DX, AL          ;write MPCSval to MPCS (I/O space, 3 wait states)


        RET                     ;done so return

InitCS  ENDP

CODE        ENDS
   
    END