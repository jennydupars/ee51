	NAME		MAIN
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;				        MAIN LOOP FOR MOTORS UNIT: Motors                    ;
;                           	   Homework 10        		                 ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program is the main loop for the motor unit which controls
; 					the main movement motors, the turret rotation motor, and the 
; 					turret elevation motor. 
;
;					The main loop will initialize everything necessary to parse 
; 					serial commands and send these commands to be reflected in the 
; 					movement of the motors. 
;
; Input:            Serial input from remote unit.
; Output:           Motors and laser activation, and serial output.
;
; User Interface: 	When keys are pressed, the proper commands are sent to the motor
; 					unit. These commands will be executed by the motors and laser.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Limitations: 		Assumes the ASCII character set. Hardware limitations create 
;					limits for what the Robotrike can do. The maximum speed is 
; 					limited by the hardware, and some motors are not able to rotate
; 					a full 360 degrees. 
; 
; Known Bugs:       None.
;
; Revision History:
;    11/29/2016         Jennifer Du     initial revision
; 	 11/30/2016 		Jennifer Du 	writing assembly code 
; 	 12/07/2016 		Jennifer Du 	testing code 

$INCLUDE(common.inc)
$INCLUDE(queue.inc)		; constants used for queue 


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP

;external function declarations
	
; initialization functions 
	EXTRN 	InitCS:NEAR					; initialize chip select				
	EXTRN 	ClrIRQVectors:NEAR 			; clear IRQ vectors - in interrupt vector table
	EXTRN 	InstallINT2Handler:NEAR 	; install INT2 handler for INT2 interrupts
	EXTRN	InitINT2:NEAR 				; initialize INT2 interrupts 
	EXTRN 	InitSerial:NEAR 			; initialize serial channel 
	EXTRN	InstallTimer0Handler:NEAR	; install event handler for timer 0 interupts
	EXTRN 	InitTimer0:NEAR 			; initialize timer 0 interrupts 
	
	EXTRN 	InitializeStateMachine:NEAR ; initialize character parsing state machine
	EXTRN 	InitRobot:NEAR 				; initialize motors and laser on robotrike
	
; Event queue management functions 
	EXTRN 	InitEventQueue:NEAR 		; initialize event queue 
	EXTRN 	DequeueEvent:NEAR 			; dequeues an event from event queue 
    EXTRN   GetCriticalErrorFlag:NEAR	; get and set critical error flag, to see if 
    EXTRN   ResetCriticalErrorFlag:NEAR ; event queue is full and we must reset system
    
; Event handler for events dequeued from event queue 
    EXTRN   QueueEventHandler:NEAR 		; redirects to error, serial character, or key 
										; press event handlers 
	
			
	
            
START:  

MAIN: 

InitializeSystem:	

	CLI 	

	MOV     AX, DGROUP              ;initialize the stack pointer
	MOV     SS, AX
	MOV     SP, OFFSET(DGROUP:TopOfStack)

	MOV     AX, DGROUP              ;initialize the data segment
	MOV     DS, AX

	CALL    InitCS                  ; initialize the 80188 chip selects
                                    ;   assumes LCS and UCS already setup

    CALL    ClrIRQVectors           ; initialize interrupt vector table

    CALL    InstallINT2Handler      ; install the event handler for INT2 
    CALL    InitINT2                ; initialize the INT2 interrupt 
	
    CALL    InitSerial				; initialize serial channel 
	
	CALL    InstallTimer0Handler     ;install the event handler

    CALL    InitTimer0               ;initialize the internal timer
	
	CALL 	InitRobot 				; initialize robot settings 
	
	CALL 	InitializeStateMachine	; initialize parser 
   
    STI                             ; and finally allow interrupts.
	
InitializeEventQueue: 
	
	CALL 	InitEventQueue			; initialize event queue management variables
									; clear critical error flag
    CALL    ResetCriticalErrorFlag	; after initializing

	

TryToDequeueEvent: 					; attempt to dequeue event from event queue 
	CALL 	DequeueEvent 			; either an event value or non-event value will be
									; returned in AX 
	CALL 	QueueEventHandler		; returned event value is sent to queue event 
									; handler to be processed 
	;JMP 	CheckCriticalErrorFlag	; after we are done, check critical error flag
	
CheckCriticalErrorFlag: 
    CALL    GetCriticalErrorFlag 	; get critical error flag value in AX 
	CMP 	AX, IS_SET				; if critical error occurred, then critical flag
									; is set, and event queue is full
	JE 		InitializeSystem		; re-initialize everything, and start over since 
									; this error event is disastrous
									; jump to re-initialize all system variables and 
									; settings 
	
    JMP  	TryToDequeueEvent		; if critical error did not occur, we dequeue 
									; next event 
	
CODE    ENDS

CheckParseErrors:
	CALL 	GetParseErrorStatus
	CMP	 	AX, 0 
	JE 		CheckSerialErrors
	; if not equal to no-err val: 
	CALL 	HandleErrorEvent				; value of error is already in AL 
	;JMP 	CheckSerialErrors

CheckSerialErrors: 
	CALL 	GetSerialErrorStatus 
	CMP 	AX, 0 
	JE 		ProceedToDequeueEvent
	; if not equal to no-err val: 
	CALL 	HandleErrorEvent
	;JMP 	ProceedToDequeueEvent
	
ProceedToDequeueEvent: 
	
	CALL 	DequeueEvent				; do i need to check if empty or is this a blocking funciton? 
	CALL 	HandleEvents
		
		
		
CODE    ENDS

; will be put with the other parse functions later
GetParseErrorStatus 	PROC 	NEAR 
						PUBLIC 	GetParseErrorStatus
	MOV 	AX, errorStatus 
	RET 
GetParseErrorStatus		ENDP 





; the data segment 
; empty so we can initialize 
DATA        SEGMENT     PUBLIC      'DATA'               

    DATA        ENDS



;the stack

STACK   SEGMENT STACK  'STACK'

        DB      80 DUP ('Stack ')       ;240 words

        TopOfStack      LABEL   WORD

STACK   ENDS



        END         START

	
      