	NAME		MAIN
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;				  MAIN LOOP FOR REMOTE UNIT: Keypad and Display              ;
;                           	   Homework 9        		                 ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program is the main loop for the remote unit which 
;	 				manages the keypad and display units. The main loop manages
; 					the keypad user interface, the serial interface, and any error
; 					handling that needs to be done in the main loop (serial port 
; 					errors, key entry errors, etc.). All errors, including serial
; 					errors and parsing errors, will be reported to the user. 
; 
; 					The main loop initializes the keypad and display settings so 
; 					the user can use them. It also initializes the serial port,
; 					so users can send commands to the motors and receive status 
; 					updates back.
;
;					The main loop constantly checks for errors and also handles the
; 					events populating the event queue. Depending on what kind of 
; 					event it is, the main loop will call the appropriate function 
; 					to handle the event.
;
; Input:            Keypad, and serial input. 
; Output:           Display, and serial output to the motor board.
;
; User Interface: 	Keys pressed by the user are registered as key press events, and 
; 					are handled by sending the key value through the serial port to 
; 					the motor board. The display will show current motor status, 
; 					system status, and commands when they are requested by user key 
; 					presses. 
;
;					This diagram shows the layout of the keyboard and the 
; 					corresponding command for each key: 
;		+---------------+---------------+---------------+---------------+
;		|				|				|				|				|
;		|  Reset robot	|	V-256		|	V+256		|	D90 		|
;		|	(stop or	| reduce speed	| increase speed| set direction	|
;		|	reset all	| by about 0.4	| by about 0.4	| to the right	|
;		|	movement)	|				|				|				|
;		+---------------+---------------+---------------+---------------+
;		|		S0		|	S65534		|	  D0		|	D180		|
;		|	set speed	|	set speed	| set direction	| set direction	|
;		|	to minimum	|	to maximum	|  to straight	| to backwards	|
;		|	 (stop)		|				|	  ahead		|				|
;		|				|				|				|				|
;		+---------------+---------------+---------------+---------------+
;		|	Laser on	|	Laser off	|	D-15		|	D+15		|
;		|		F		|		O		| move at 15 deg| move at 15 deg|
;		|				|				| more to the 	| more to the 	|
;		|				|				|	left		|	right		|
;		|				|				|				|				|
;		+---------------+---------------+---------------+---------------+
;		|	  T-60		|	  T60		|	D270		|	 clear 		|
;		| 	Change		|	Change		| set direction	| error display	|
;		|	 turret 	|	 turret		|  to exactly	|  message  	|
;		| elevation to 	| elevation to	|	 left 		|	 		    |
;		|  -60 degrees	|  60 degrees	|				|				|
;		+---------------+---------------+---------------+---------------+
;
; 		Also, for the second row, multiple key presses are allowed. Pressing 
; 		keys one and two at the same time sets the robot's movement to half 
; 		speed. Pressing keys three and four at the same time causes the robot
; 		to move at 90 degrees. 
; 		
; 		For the fourth row, multiple key presses are also allowed. Pressing 
;		the first key by itself will send a turret elevation -60 degrees 
; 		command, and the 2nd key by itself will send a turret elevation 
; 		60 degrees command. Pressing both will result in a turret elevation
; 		of 0 degrees with respect to the horizontal. Combining keys 1 and 3 
; 		will result in a turret elevation of -30 degrees, and combining keys
; 		2 and 3 will result in a turret elevation of positive 30 degrees. 
;
;		Autorepeat of key presses is also possible. In the first row of keys,
; 		holding keys 2 and 3 down for longer times will result in more change 
; 		in speed as if the button was pressed repeatedly. In the third row of 
; 		keys, autorepeat is possible for keys 3 and 4. Holding these keys for
; 		prolonged periods of time will result in multiple requests for direction
; 		change. 

;
; 		
; Algorithms:       None.
; Data Structures:  None.
;
; Limitations: 		Assumes the ASCII character set. 
; Known Bugs:       None.
;
; Revision History:
;    11/29/2016         Jennifer Du     initial revision
; 	 12/04/2016 		Jennifer Du 	writing assembly code 


$INCLUDE(common.inc)	; commonly used constants 
$INCLUDE(queue.inc)		; constants used for queue, event queue 


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
	EXTRN 	InitDisplay:NEAR 			; intialize display variables 
	EXTRN 	InitKeypad:NEAR 			; intialize keypad variables 
	
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

	CLI 							; don't allow interrupts 

	MOV     AX, DGROUP              ;initialize the stack pointer
	MOV     SS, AX
	MOV     SP, OFFSET(DGROUP:TopOfStack)

	MOV     AX, DGROUP              ;initialize the data segment
	MOV     DS, AX

	CALL    InitCS                  ; initialize the 80188 chip selects
                                    ;   assumes LCS and UCS already setup

    CALL    ClrIRQVectors           ; initialize interrupt vector table

    CALL    InitINT2                ; initialize the INT2 interrupt 
    CALL    InstallINT2Handler      ; install the event handler for INT2 
    
	
    CALL    InitSerial				; initialize serial channel 
	
    CALL    InitTimer0              ; initialize the internal timer
	CALL    InstallTimer0Handler    ; install the event handler

    CALL    InitDisplay				; clear display and initialize muxing variables

    CALL    InitKeypad				; initialize keypad scanning variables
   
                                    ; clear critical error flag
    CALL    ResetCriticalErrorFlag	; after initializing
	
InitializeEventQueue: 				; initialize event queue

	CALL 	InitEventQueue			; function intializes event queue management 
									; variables 
    
    STI                             ; and finally allow interrupts.
	
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


; the data segment 
; empty, to initialize data segment 
DATA        SEGMENT     PUBLIC      'DATA'

DATA        ENDS


;the stack
STACK   SEGMENT STACK  'STACK'
        DB      80 DUP ('Stack ')       ;240 words
        TopOfStack      LABEL   WORD
STACK   ENDS

        END         START