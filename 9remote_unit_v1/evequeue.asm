; The functions in this file manage the event queue - dequeueing events as well 
; as enqueueing them. 

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

	PUSH 	AX 
CheckEventQueueFull:
	MOV 	SI, eventQueue 
	CALL 	QueueFull
	JNZ 	CanEnqueueEvent
	
	;JZ 	HandleEventQueueFull
HandleEventQueueFull:
	MOV 	criticalErrorFlag, TRUE 
	JMP 	EndEnqueueEvent

CanEnqueueEvent:
	POP 	AX 
	MOV 	SI, eventQueue
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
					
CheckEventQueueEmpty:
	MOV 	SI, eventQueue
	CALL 	QueueEmpty 
	JZ 		HandleEventQueueEmpty
	;JNZ 	CanDequeueEvent

CanDequeueEvent:
	MOV 	SI, eventQueue 
	CALL 	Dequeue 
	JMP 	EndDequeueEvent
HandleEventQueueEmpty: 
	MOV 	AX, 0 								; should i do this? ///////////////////////// 
	;JMP 	EndDequeueEvent 					; is there anything else i have to do? ////////////////
EndDequeueEvent: 
	RET 
	
DequeueEvent		ENDP 