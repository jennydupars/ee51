	NAME 	EVEQUEUE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;  			     	  Robotrike Event Queue Handling Routines                ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; The functions in this file manage the event queue - dequeueing events as well 
; as enqueueing them. 
; The included functions are all public: 
; 	InitEventQueue - initializes event queue for the system 
; 	EnqueueEvent - enqueues a word-sized event value to event queue 
; 	DequeueEvent - returns a word-sized event value, FIFO style 
; 	GetCriticalErrorFlag - returns value of critical error flag, so outside functions
; 			can tell if critical error has occurred
; 	SetCriticalErrorFlag - allows outside functions to set critical error flag 
; 			(more commonly used to reset flag)
;
; Revision History:
;     12/02/2016        Jennifer Du     initial revision 
; 	  12/04/2016 		Jennifer Du 	debugging, commenting 


; include files
 
$INCLUDE(macros.inc)		; commonly used macros and procedures 
$INCLUDE(common.inc)
$INCLUDE(queue.inc)
$INCLUDE(remoteui.inc)

        

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP
        
        
    EXTRN   QueueFull:NEAR 
    EXTRN   QueueEmpty:NEAR
    EXTRN   Enqueue:NEAR 
    EXTRN   Dequeue:NEAR
	EXTRN 	QueueInit:NEAR 
        
		
		
;
; InitEventQueue
;
;
; Description: 		This function is called by the main loop code to initialize the 
; 					event queue that will store error, key press, and serial character
; 					events. This event queue will store these events until they are 
;	 				able to be handled. 
;
; Operation:    	First pass in the address of the queue in SI, and select the 
; 					element size using BL. Then we initialize the queue using the 
; 					QueueInit function.
;
; Arguments:        SI - address of eventQueue 
; 					BL - selector argument for word-sized or byte-sized elements
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: eventQueue (w) - queue holding events to be handled
; Global Variables:	None.
; 
; Input:            None.
; Output:           None. 
;
; Algorithms: 		None. 
; Data Structures:  eventQueue - queue that holds events to be handled 
;		
InitEventQueue	PROC 	NEAR
				PUBLIC 	InitEventQueue

GetAddress: 
	MOV 	SI, OFFSET(eventQueue)		; initialize the queue and size
	MOV 	BL, WORDSIZE				; set queue element size by passing BL
										; we choose to make eventQueue a word queue
	
	CALL 	QueueInit					; initialize the event queue 
	
	RET 
InitEventQueue 	ENDP


;
; EnqueueEvent
;
;
; Description:  	This function enqueues events to the event queue when they 
; 					occur. The events that will be enqueued will be key press 
; 					events, serial port errors, and serial events. 
;
; Operation:    	First we check to see if the queue is full. If so, we set the
; 					critical error flag and return. If the queue is not full, we 
; 					enqueue the value passed in by AX. 
;
; Arguments:        AX - event value and type to be enqueued. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: criticalErrorFlag (r) - flag to see if we have a critical error
; 					eventQueue (r/w) - queue holding events to be handled
; Global Variables:	None.
; 
; Input:            None.
; Output:           None. 
;
; Algorithms: 		None. 
; Data Structures:  eventQueue - queue that holds events to be handled.

EnqueueEvent	PROC 	NEAR 
				PUBLIC 	EnqueueEvent

	PUSH 	AX 							; save value to be enqueued 
										; before QueueFull changes it 
CheckEventQueueFull:
	LEA 	SI, eventQueue 				; load address of eventQueue into SI
	CALL 	QueueFull					; argument is passed into QueueFull, 
										; Check if eventQueue is full.
	JNZ 	CanEnqueueEvent				; if not, then we can enqueue event 
	
	;JZ 	HandleEventQueueFull		; if the queue is full, 
HandleEventQueueFull:
	MOV 	criticalErrorFlag, TRUE     ; we set critical error flag 
	JMP 	EndEnqueueEvent				; and end without enqueueing. 

CanEnqueueEvent:						; if there is room to enqueue another event:
	POP 	AX 							; restore argument value AX to be enqueued 
	LEA 	SI, eventQueue				; load address of event queue to be modified
	CALL 	Enqueue 					; call Enqueue with args (AX, SI) ready

EndEnqueueEvent:
	RET 								; end function 
EnqueueEvent	ENDP
	
	
	

;
; DequeueEvent
;
;
; Description:  	This function dequeues events from the event queue when they 
; 					are handled. The events that will be dequeued will be key press 
; 					events, serial port errors, motor feedback display requeuests, 
; 					and serial events. The event value dequeued will be returned in 
; 					AX. 
;
; Operation:    	First we test if the queue is empty or not. If not, we dequeue 
; 					the next value. If the queue is empty, we return with a 
; 					designated event value that our event handler recognizes as a 
; 					non-event event value. 
; 
; Arguments:        None.
; Return Value:     AX - event value and type to be returned after calling this
;
; Local Variables:  None. 
; Shared Variables: eventQueue (w) - queue holding events to be handled
; Global Variables:	None.
; 
; Input:            None.
; Output:           None.
;
; Algorithms: 		None. 
; Data Structures:  None.

DequeueEvent 		PROC 	NEAR 
					PUBLIC 	DequeueEvent
					
CheckEventQueueEmpty:
	LEA 	SI, eventQueue				; populate address argument for event queue 
	CALL 	QueueEmpty 					; determine if queue is empty 
	JZ 		HandleEventQueueEmpty		; if event queue empty, don't dequeue anything
	;JNZ 	CanDequeueEvent				; if not empty, we can dequeue an event 

CanDequeueEvent:
	LEA 	SI, eventQueue 				; load address argument into SI 
	CALL 	Dequeue 					; dequeue the value next in line 
	JMP 	EndDequeueEvent				; and end function 
	
HandleEventQueueEmpty: 					; if the queue was empty: 
	MOV 	AX, NO_EVENT_VAL			; return special no-event event value
	;JMP 	EndDequeueEvent 			; before returning 
EndDequeueEvent: 
	RET 
	
DequeueEvent		ENDP 

 

; 
;
;
;
; GetCriticalErrorFlag 
;
;
; Description:  	This function allows other functions to determine the status of 
; 					the event queue. Calling this function returns the value of the 
; 					critical error flag in AL - if set, AL is non-zero. If the 
; 					critical error flag is not set, then AL is zero.
;
; Operation:    	We move the value of the critical error flag into AL to return.
; 
; Arguments:        None.
; Return Value:     AL - value of critical error flag.
;
; Local Variables:  None. 
; Shared Variables: criticalErrorFlag (r) - holds status of event queue (if full, 
; 						critical error flag is set. if not, criticalErrorFlag is 
; 						not set.)
; Global Variables:	None.
; 
; Input:            None.
; Output:           None.
;
; Algorithms: 		None. 
; Data Structures:  None. 
;

GetCriticalErrorFlag        PROC    NEAR 
                            PUBLIC  GetCriticalErrorFlag
    MOV     AX, 0                       ; clear higher byte of AX 
    MOV     AL, criticalErrorFlag		; move value of flag into AL for return
    
    RET 
GetCriticalErrorFlag        ENDP 



;
; SetCriticalErrorFlag 
;
;
; Description:  	This function allows other functions to set the status of 
; 					the critical error flag. Calling this function will allow other 
; 					functions to set or reset the value of the critical error flag. 
; 					A value passed into this function in AL 
;
; Operation:    	We move the value of the critical error flag into AL to return.
; 
; Arguments:        None.
; Return Value:     AL - value of critical error flag.
;
; Local Variables:  None. 
; Shared Variables: criticalErrorFlag (r) - holds status of event queue (if full, 
; 						critical error flag is set. if not, criticalErrorFlag is 
; 						not set.)
; Global Variables:	None.
; 
; Input:            None.
; Output:           None.
;
; Algorithms: 		None. 
; Data Structures:  None. 
;
ResetCriticalErrorFlag        PROC    NEAR 
                            PUBLIC  ResetCriticalErrorFlag 
    MOV     AX, 0                        
    MOV     criticalErrorFlag, AL       ;Set critical error flag to 0 
    RET 
ResetCriticalErrorFlag        ENDP 




CODE    ENDS





; the data segment 

DATA        SEGMENT     PUBLIC      'DATA'

criticalErrorFlag   DB  ?
	; tells us if there has been a critical error (event queue full)
eventQueue   qStruc      < >  
	; event queue storing events enqueued from keypad/serial routines
	

    DATA        ENDS
END 