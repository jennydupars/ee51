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
;
;
;
; InitEventQueue
;
;		
InitEventQueue	PROC 	NEAR
				PUBLIC 	InitEventQueue

GetAddress: 
	MOV 	SI, OFFSET(eventQueue)		; initialize the queue and size

	MOV 	BL, WORDSIZE				; if this argument is 0, that means we want the queue element size to be a byte. but we want a word. 
	
	CALL 	QueueInit
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
; 					critical error flag. If the queue is not full, we enqueue 
; 					the value passed in by AX. 
;
; Arguments:        AX - event value and type to be enqueued. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: criticalErrorFlag - flag tracking whether we have a critical error
; 					eventQueue - queue holding events to be handled
; Global Variables:	None.
; 
; Input:            None.
; Output:           None. 
;
; Algorithms: 		None. 
; Data Structures:  None.

EnqueueEvent	PROC 	NEAR 
				PUBLIC 	EnqueueEvent

	PUSH 	AX 
CheckEventQueueFull:
	LEA 	SI, eventQueue 
	CALL 	QueueFull
	JNZ 	CanEnqueueEvent
	
	;JZ 	HandleEventQueueFull
HandleEventQueueFull:
	MOV 	criticalErrorFlag, TRUE                    
	JMP 	EndEnqueueEvent

CanEnqueueEvent:
	POP 	AX 
	LEA 	SI, eventQueue
	CALL 	Enqueue 

EndEnqueueEvent:
	RET 
EnqueueEvent	ENDP
	
	
	

;
; DequeueEvent
;
;
; Description:  	This function dequeues events from the event queue when they 
; 					are handled. The events that will be dequeued will be key press 
; 					events, serial port errors, motor feedback display requeuests, 
; 					and serial events. 
;
; Operation:    	First we test if the queue is empty or not. If not, we dequeue 
; 					the next value. 
; 
; Arguments:        None.
; Return Value:     AX - event value and type to be returned after calling this.
;
; Local Variables:  None. 
; Shared Variables: eventQueue - queue holding events to be handled
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
	LEA 	SI, eventQueue
	CALL 	QueueEmpty 
	JZ 		HandleEventQueueEmpty
	;JNZ 	CanDequeueEvent

CanDequeueEvent:
	LEA 	SI, eventQueue 
	CALL 	Dequeue 
	JMP 	EndDequeueEvent
HandleEventQueueEmpty: 
	MOV 	AX, NO_EVENT_VAL									; should i do this? ///////////////////////// 
	;JMP 	EndDequeueEvent 					; is there anything else i have to do? ////////////////
EndDequeueEvent: 
	RET 
	
DequeueEvent		ENDP 

 

; 
;
;
;
; GetCriticalErrorFlag 
; 
; returns AX: set if critical error flag is set, not set if not.

GetCriticalErrorFlag        PROC    NEAR 
                            PUBLIC  GetCriticalErrorFlag
    MOV     AX, 0                         
    MOV     AL, criticalErrorFlag
    
    RET 
GetCriticalErrorFlag        ENDP 


; SetCriticalErrorFlag 

SetCriticalErrorFlag        PROC    NEAR 
                            PUBLIC  SetCriticalErrorFlag 
    MOV     AX, 0                        
    MOV     criticalErrorFlag, AL 
    RET 
SetCriticalErrorFlag        ENDP 




CODE    ENDS





; the data segment 

DATA        SEGMENT     PUBLIC      'DATA'

criticalErrorFlag   DB  ?
eventQueue   qStruc      < >  

    DATA        ENDS
END 