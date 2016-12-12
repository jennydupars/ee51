    NAME    QUEUE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                QUEUE ROUTINES                              ;
;                           Queue Routine Functions                          ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains queue routines that initialize a queue, dequeue values, enqueue
; values, and check to see if a queue is full or empty. The structure of a queue 
; is defined in the qStruc struct, stored in queue.inc. The queues initialized 
; and managed using these routines will be of fixed length, 256 bytes. These queues
; will be managed with head and tail pointer wrapping around, so we can use the 
; same memory locations for constantly changing values in these queues. These 
; functions have been written to accomodate only queues with a size that is 
; a power of 2. This simplifies tail and head pointer wrapping. 

;
; This file contains 5 public queue routines: 
;   QueueInit   - initializes the queue based on the arguments given  
;   QueueEmpty  - determines if queue is empty 
;   QueueFull   - determines if queue is full
;   Dequeue     - remove element from head of queue
;   Enqueue     - add element to tail of queue
;
;
; Revision History:
;     10/17/16  	Jennifer Du      initial revision
;     10/19/16      Jennifer Du      writing assembly code
;	  10/22/16 		Jennifer Du		 debugging and commenting 
;     12/01/16      Jennifer Du      fixing critical code 

; include files
$INCLUDE(queue.inc)		; defines queue structure and other queue constants
$INCLUDE(common.inc)	; commonly used constants


CGROUP      GROUP       CODE
CODE        SEGMENT     PUBLIC   'CODE'
            ASSUME      CS:CGROUP


; QueueInit
;
; Description: 		Initialize the queue of the passed element size
;				   	at the passed address (SI). This procedure does all the
;					necessary initialization to prepare the queue for use. 
;					After calling this procedure the queue is empty 
;					and ready to accept values. The maximum number of bytes that 
;                   can be stored in the queue will be 256, or 128 words. 
;					The passed element size specifies whether each entry in 
;					the queue is a byte or a word. If it is 
;					true (non-zero) the elements are words and if it is false 
;					(zero) they are bytes. The address is passed in	SI by value 
;					(thus the queue starts at DS:SI) and the element size is
;                   passed by value in BL.
;
; Operation: 		Set the STRUC's values according to the values passed into 
;					the function: element size is selected by a passed-in value
; 					in BL, head is initialized to the 0th index in the queue, the
; 					tail pointer is initialized to be at the 0th index in the queue
; 					as well. The queue is initialized at the passed-in location given
; 					by the SI argument. 
;
; Arguments: 		SI - address passed in by the function
;					BL - size of element (bytes or words)
;                   AX - length of queue (ignored, because this function initializes 
;						a fixed-length queue)
; Return Value:		None. 
;
; Local Variables:	SI - address passed in by the function
;					BL - size of element (bytes or words)
;                   AL - size of element (ignored since fixed-length queue)
;
; Shared Variables: None. 
;
; Global Variables: None. 
;
; Input: 			None. 
; Output: 			None. 
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures: 	STRUC: has properties element size, address, head pointer,
;					and tail pointer
;



QueueInit   PROC    NEAR
            PUBLIC  QueueInit

StartQueueInit:    
            
SetQueueElementSize:
    
    CMP     BL, BYTE_EL_SIZE    ; see if size selected by BL argument corresponds
								; to a desired byte or word queue 
    JE      SizeIsByte			; if argument is selector value for byte-sized queue,
								; set size to byte
    ;JNE     SizeIsWord			; if not, set element size to word 
    
SizeIsWord:						
    
    MOV [SI].elsize, WORDSIZE	; store size of elements in queue in elsize variable
    JMP SetHeadPTR 				; then move on to set head pointer index in array

SizeIsByte:
    
    MOV [SI].elsize, BYTESIZE	; define that element size is byte-sized 
    JMP SetHeadPTR				; and move on to define other queue variables 

SetHeadPTR:
    MOV [SI].head, 0000H   		; set head to 0 index location in queue

SetTailPTR:
    MOV [SI].tail, 0000H   		; set tail to index that is the same as head in 
								; queue (empty queue starts off with head and 
								; tail at same index)

    RET 
QueueInit   ENDP




; QueueEmpty
;
; Description: 		The function is called with the address (a) of the queue to
;					be checked and returns with the zero flag set if the queue 
;					is empty and with the zero flag reset otherwise. The address 
;					(a) is passed in (SI) by value (thus the queue starts at 
;					(DS:SI).
;
; Operation: 		Compare the addresses of the tail pointer and head pointer. 
;					If their difference is 0, then that means the the queue is 
;					empty. There are no elements and the ZF will be set. 
;			
; Arguments: 		SI - address of queue to be checked
; Return Value: 	ZF - set to 1 if queue is empty, 0 if not.
;
; Local Variables: 	AX - address of head pointer
; Shared Variables: None.
; Global Variables:	None. 
;
; Input: 			None. 
; Output: 			None.
;
; Error Handling: 	None.
;
; Algorithms: 		None.
;
; Data Structures: 	STRUC: has properties element size, address, head pointer,
;					and tail pointer
;

QueueEmpty  PROC    NEAR
            PUBLIC  QueueEmpty

QueueEmptyInit:

    MOV AX, [SI].head       ; compare head and tail values: if they are the same,
    CMP AX, [SI].tail       ; no elements are between them, indicating that the 
							; queue is empty. Comparing head and tail pointers 
							; will naturally set the ZF if queue is empty. 

    RET 
QueueEmpty  ENDP 	


;
;
; QueueFull
;
; Description: 		The function is called with the address of the queue to be
;					checked and returns with the zero flag set if the queue is 
;					full and with the zero flag reset otherwise. The address is
;					passed in by value (thus the queue starts at DS:SI).
;
; Operation:		We will add 1 to the tail pointer, mod it by the length, and 
;					see if it is equal to the head pointer. This takes care of 
;					queue wraparound.
;
; Arguments:		SI - address of the queue to be checked
; Return Value:		ZF - set if queue is full, clear otherwise. 
;
; Local Variables:	CX - length of queue
;                   AX - tail pointer 
;                   DX - value of (tail + 1) mod length
; Shared Variables: None.
; Global Variables: None. 
;
; Input:			None. 
; Output:			None. 
;
; Error Handling:	None. 
;
; Algorithms:		None.
;
; Data Structures: 	STRUC: has properties element size, address, head pointer,
;					and tail pointer
; 
; Limitations: 		The procedure used here to determine if the queue is full only 
; 					works for queues of length 2^n.
;


QueueFull   PROC    NEAR
            PUBLIC  QueueFull

QueueFullInit:					; if the queue's tail, incremented by 1, points 
								; to the same place as the head pointer, then the
								; queue is full because we are not able to add a 
								; value to the queue without overwriting previously
								; written values. in that case, the queue would be 
								; full.

    MOV AX, [SI].tail          	; move tailPTR into AX so we can operate on it
                                ; without changing value of tailPTR
								
    ADD AX, [SI].elsize         ; increment tail's value to point to next spot
								; in queue 
								
	AND AX, ARRAY_SIZE-1		; ANDing (tail + 1) and (array_size - 1) will give
								; us the index of the new tail pointer, mod length, 
								; which accounts for wrapping around to the lower 
								; addresses in the queue. Note that this "trick"
								; only works for queues of size 2^n.
								
	CMP AX, [SI].head			; compare: if tail+1=head, then queue is full.

    RET 
QueueFull   ENDP  



;
;
;
;
; Dequeue
;
; Description: 		This function removes either an 8-bit value or a 
;					16-bit value (depending on the queue's element size) 
;					from the head of the queue at the passed address (a) 
;					and returns it in AL or AX. The value is returned in 
;					AL if the element size is bytes and in AX if it is words. 
;					If the queue is empty it waits until the queue has a 
;					value to be removed and returned. It does not return 
;					until a value is taken from the queue. The address (a)
;					is passed in SI by value (thus the queue starts at DS:SI).
;
; Operation:		Return the value by storing first element into AX (if word 
;                   sized) or AL (if byte sized), and then increment the head 
;                   pointer (mod length of queue if there is wraparound).
;
; Arguments:		SI - address of the queue to be checked
; Return Value:		AL or AX - the first thing in line
;
; Local Variables:	Shared. 
; Shared Variables: None.
; Global Variables:	None. 
;
; Input:			None.
; Output:			None.
;
; Error Handling:	None. 
;
; Algorithms:		We will return the value at the head of the queue, and move
;					the head pointer up a spot. However, if the queue is empty,
;					we will loop until interrupted, and only dequeue when there 
; 					is something available to be dequeued. 
;
; Data Structures: 	STRUC: has properties element size, address, head pointer,
;					and tail pointer
;

Dequeue     PROC    NEAR
            PUBLIC  Dequeue
            
DequeueInit:
    
IfQueueIsEmpty:
    CALL 	QueueEmpty             	; check if the queue is empty or not 
    JZ 		IfQueueIsEmpty          ; if it's empty, keep checking
    ;JNZ 	QueueNotEmpty           ; if it's not empty, exit loop 
    
QueueNotEmpty:
    CMP [SI].elsize, WORDSIZE   	; compare the size to the size of a word 
    JZ DequeueWordSizedValue      	; if word-sized elements, return a word 
    ;JNZ DequeueByteSizedValue		; else, return a byte

DequeueByteSizedValue: 
    MOV BX, [SI].head          		; load head address into BX 
    MOV AL, BYTE PTR[SI].array[BX]  ; get element from array at head
    ADD BX, BYTESIZE    	    	; increment the head by 1 byte to locate 
									; new head after dequeueing a value 
                                    ; we will get (head + 1) mod length 
                                    ; by performing (head + 1) AND (size - 1)
									; (only for 2^n length queues)
    AND BX, ARRAY_SIZE-1         	; new head index, now accounting for wraparound
    MOV     [SI].head, BX           ; store updated head value 
    JMP EndDequeue 					; then we end dequeue function with desired 
									; value in AL 
    
DequeueWordSizedValue:
    MOV BX, [SI].head          		; load head address into BX 
    MOV AX, WORD PTR[SI].array[BX]  ; get element from array at pos BX
    ADD BX, WORDSIZE    			; increment the head by a word to locate 
									; new head pointer after dequeueing a value 
                                    ; we will get (head + word_size) mod length 
                                    ; by performing (head + 2) AND (size - 1) 
									; using trick for queues of length 2^n
    AND BX,ARRAY_SIZE-1          	; wrapped around value is stored in head 
    MOV     [SI].head, BX     		; and new head index is stored in head pointer
    
    ;JMP EndDequeue 				; end dequeue function with return value in AX
    
EndDequeue:	
    RET
Dequeue     ENDP 



;
;
; Enqueue
;
; Description: 		This function adds the passed 8-bit or 16-bit(depending 
;					on the element size) value (v) to the tail of the queue 
;					at the passed address (a). If the queue is full, it waits 
;					until the queue has an open space in which to add the 
;					value. It does not return until the value is added to the 
;					queue. The address (a) is passed in SI by value and the 
; 					value to enqueue is passed by value in AL if the element size 
; 					for the queue is bytes, in AX if it is words.
;
; Operation:		Move new element to the spot pointed to by the tail pointer
;					and then increment the tail pointer by the appropriate 
;                   amount (by 2 bytes if elements are word-sized, 1 byte if elements
; 					are byte sized). 
;
; Arguments:		AL or AX - value to be added to end of queue 
;					SI - address of queue 	
; Return Value:		None. 
;
; Local Variables:	AL - if queue holds byte-sized elements, this is value to 
;                        add to the queue
;                   AX - if queue holds word-sized elements, this is value to 
;                        add to the queue
; Shared Variables: None.
; Global Variables: None. 
;
; Input:			None. 
; Output:			None. 
;
; Error Handling:	None. 
;	
; Algorithms:		None. 
;
; Data Structures: 	STRUC: has properties element size, address, head pointer,
;					and tail pointer
; Limitations: 		Method of accounting for tail pointer wrapround in the queue 
; 					memory relies on the fact that queue is of size 2^n. 
;


Enqueue     PROC    NEAR
            PUBLIC  Enqueue
    
EnqueueInit:
	MOV CX,AX						; store argument value to enqueue in CX before 
									; QueueFull changes AX
IfQueueIsFull:
    CALL QueueFull             	 	; check if the queue is full 
    JZ IfQueueIsFull           		; if it's full, keep checking
    ;JNZ QueueNotFull            	; if not full, exit loop, & enqueue value
    
QueueNotFull:
	MOV BX, [SI].tail          		; load tail address into BX 
    CMP [SI].elsize, WORDSIZE    	; compare element size to the size of a word
    JE EnqueueWord               	; if elements are word-sized, then enqueue a word
    ; JNE EnqueueByte 				; if not, then enqueue a byte 
	
EnqueueByte: 
	
    MOV BYTE PTR[SI].array[BX], CL  ; move CL value into the queue at tail
    ADD BX,BYTESIZE					; increment tail pointer location
	AND BX, ARRAY_SIZE-1	 		; the operation (tail+1) AND (size-1)
									; gives us the wrapped around value for tail 
									; according to trick used for 2^n length queues
	MOV [SI].tail, BX				; wrapped around value is stored in tail again 
	
	JMP EndEnqueue 					
    
EnqueueWord:
	
    MOV WORD PTR[SI].array[BX], CX  ; move CX value into the array at queue.tail
    ADD BX, WORDSIZE    			; increment the tail by size of a word 
                                    ; we will get (tail + 2) mod length 
                                    ; by performing (tail + 2) AND (size - 1) 
    AND BX, ARRAY_SIZE-1          	; mod value will be stored in BX as new
									; tail pointer, accounting for wraparound
	MOV [SI].tail, BX          		; move the mod length value into queue.tail
    ;JMP EndEnqueue 
    
EndEnqueue:
    RET
Enqueue     ENDP 
			

CODE    ENDS

    END