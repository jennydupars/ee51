    NAME    QUEUE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                QUEUE ROUTINES                              ;
;                           Queue Routine Functions                          ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Contains 5 queue routines: QueueInit, QueueEmpty, QueueFull, Dequeue, Enqueue. 
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

; include files
$INCLUDE(queue.inc)
$INCLUDE(common.inc)

CGROUP      GROUP       CODE

CODE        SEGMENT     PUBLIC   'CODE'

            ASSUME      CS:CGROUP

; QueueInit
;
; Description: 		Initialize the queue of the passed element size
;				   	at the passed address. This procedure does all the 
;					necessary initialization to prepare the queue for use. 
;					After calling this procedure the queue should be empty 
;					and ready to accept values. The maximum number of items that 
;                   can be stored in the queue will be 256.  
;					The passed element size specifies whether each entry in 
;					the queue is a byte or a word. If it is 
;					true (non-zero) the elements are words and if it is false 
;					(zero) they are bytes. The address is passed in	SI by value 
;					(thus the queue starts at DS:SI) and the element size is
;                   passed by value in BL.
;
; Operation: 		Set the STRUC's values according to the values passed into 
;					the function:
;					elsize - the size of elements to be put in 
;						  (size = 1 means word, size = 0 means byte)
;					head - holds the address of the first element 
; 					tail - holds the address of the spot after the last element
;
; Arguments: 		SI - address passed in by the function
;					BL - size of element (bytes or words)
; Return Value:		None. 
;
; Local Variables:	SI - address passed in by the function
;					BL - size of element (bytes or words)
;                   AL - size of element (in bytes)
;
; Shared Variables: The STRUC is called qStruc, and the queue is called queue. 
; 					elsize (DB) - the size of elements it holds (in bytes)
;					head (DW) - holds the address of the first element 
; 					tail (DW) - holds the address of spot after last element
;
; Global Variables: None. 
;
; Input: 			None. 
; Output: 			None. 
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures: 	STRUC: has properties length, size, address, head pointer,
;					and tail pointer
;                   alength  - the maximum number of elements that can be stored
;					elsize  - the size of elements to be put in (words or bytes)
;					head    - address of the first element 
; 					tail    - address of the spot after the last element
;


QueueInit   PROC    NEAR
            PUBLIC  QueueInit


SetSize:
    MOV AL, BL              ; put given size into AL
    CMP AL, BYTEorWORD      ; see if size = 1 or = 0
    JZ SizeIsWord
    ;JNZ SizeIsByte 

SizeIsByte:
    MOV AL, BYTESIZE        ; set the size = 1 byte 
    MOV [SI].elsize, AX 
    JMP SetHeadPTR	
    
SizeIsWord:
    MOV AL, WORDSIZE        ; set the size = 2 bytes
    MOV [SI].elsize, AX 
    ;JMP SetHeadPTR 
    
SetHeadPTR:
    MOV [SI].head, 0000H   ; set it to 0

SetTailPTR:
    MOV [SI].tail, 0000H   ; set it to 0

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
;					empty. 
;			
; Arguments: 		SI - address of queue to be checked
; Return Value: 	ZF - set to 1 if queue is empty, 0 if not.
;
; Local Variables: 	AX - address of head pointer
; 
; Shared Variables: The STRUC is called qStruc, and the queue is called queue. 
; 					elsize (DB) - the size of elements it holds (in bytes)
;					head (DW) - holds the address of the first element 
; 					tail (DW) - holds the address of spot after last element
;
; Global Variables:	None. 
;
; Input: 			None. 
; Output: 			None.
;
; Error Handling: 	None.
;
; Algorithms: 		Compare the tail and head pointer. If they're the same, 
;					there are no elements and the ZF will be set. 
;
; Data Structures: 	STRUC: has properties length, size, address, head pointer,
;					and tail pointer
;                   alength  - the maximum number of elements that can be stored
;					elsize  - the size of elements to be put in (words or bytes)
;					head    - address of the first element 
; 					tail    - address of the spot after the last element
;

QueueEmpty  PROC    NEAR
            PUBLIC  QueueEmpty

QueueEmptyInit:

    MOV AX, [SI].head      ; move head's value into AX
    CMP AX, [SI].tail      ; if values are equal, zero flag is set

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
; 
; Shared Variables: The STRUC is called qStruc, and the queue is called queue. 
; 					elsize (DB) - the size of elements it holds (in bytes)
;					head (DW) - holds the address of the first element 
; 					tail (DW) - holds the address of spot after last element
;
; Global Variables: None. 
;
; Input:			None. 
; Output:			None. 
;
; Error Handling:	None. 
;
; Algorithms:		Add 1 to the tail pointer, and mod it by length of queue. 
;					If the tail pointer is then equal to the head, then the 
;					queue is full. 
;
; Data Structures: 	STRUC: has properties length, size, address, head pointer,
;					and tail pointer
;                   alength  - the maximum number of elements that can be stored
;					elsize  - the size of elements to be put in (words or bytes)
;					head    - address of the first element 
; 					tail    - address of the spot after the last element
; 
;


QueueFull   PROC    NEAR
            PUBLIC  QueueFull

QueueFullInit:
    ;MOV CX, [SI].alength        ; not necessary if we can directly DIV AX by length
    MOV AX, [SI].tail          ; move tailPTR into AX so we can operate on it
                                ; without changing value of tailPTR

    ADD AX, [SI].elsize         ; increment tailPTR's value to point to next spot
;	MOV DX, 0					; clear so you can divide
;	DIV [SI].alength       ; divide (tailPTR + size) by length of queue
                                ; DX contains remainder (x mod length = DX)
	AND AX, ARRAY_SIZE-1
	CMP AX, [SI].head         ; if they are equal, then the queue is full.

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
; Shared Variables: The STRUC is called qStruc, and the queue is called queue. 
; 					elsize (DB) - the size of elements it holds (in bytes)
;					head (DW) - holds the address of the first element 
; 					tail (DW) - holds the address of spot after last element
; 					
; Global Variables:	None. 
;
; Input:			None.
; Output:			None.
;
; Error Handling:	None. 
;
; Algorithms:		We will return the value at the head of the queue, and move
;					the head pointer up a spot. 
;
; Data Structures: 	STRUC: has properties length, size, address, head pointer,
;					and tail pointer
;                   alength - the maximum number of elements that can be stored
;					elsize  - the size of elements to be put in (words or bytes)
;					head    - address of the first element 
; 					tail    - address of the spot after the last element
;
;

Dequeue     PROC    NEAR
            PUBLIC  Dequeue
            
DequeueInit:
    
IfQueueIsEmpty:
    CALL QueueEmpty             ; check if the queue is empty or not 
    JZ IfQueueIsEmpty          ; if it's empty, keep checking
    ;JNZ QueueNotEmpty           ; if it's not empty, exit loop 
    
QueueNotEmpty:
    CMP [SI].elsize, WORDSIZE   ; compare the size to the size of a word 
    JZ ReturnWord               ; if size is 2, then we return a word 
    ; JNZ ReturnByte 

ReturnByte: 
    MOV BX, [SI].head          ; load head address into BX 
    MOV AL, BYTE PTR[SI].array[BX]     ; get element from array at pos BX
    ADD [SI].head, BYTESIZE    ; increment the head by 1 byte 
    MOV CX, ARRAY_SIZE        ; we will get (head + 1) mod length 
    DEC CX                      ; by performing (head + 1) AND (size - 1) 
    AND [SI].head, CX          ; mod value will be stored in CX 
    JMP EndDequeue 
    
ReturnWord:
    MOV BX, [SI].head          ; load head address into BX 
    MOV AX, WORD PTR[SI].array[BX]     ; get element from array at pos BX
    ADD [SI].head, WORDSIZE    ; increment the head by 2 bytes 
    MOV CX, ARRAY_SIZE        ; we will get (head + 2) mod length 
    DEC CX                      ; by performing (head + 2) AND (size - 1) 
    AND CX, [SI].head          ; mod value will be stored in CX 
    MOV [SI].head, CX          ; move the mod length value into queue.head 
    ;JMP EndDequeue 
    
EndDequeue:
    RET
Dequeue     ENDP 



;
;
; Enqueue
;
; Description: 		This function adds the passed 8-bit or 16-bit(depending 
;					on the element size) value (v) to the tail of the queue 
;					at the passed address (a). If the queue is full it waits 
;					until the queue has an open space in which to add the 
;					value. It does not return until the value is added to the 
;					queue. (This is called a "blocking function".) The address 
;					(a) is passed in SI by value (thus the queue starts at 
;					DS:SI) and the value to enqueue (v) is passed by value 
;					in AL if the element size for the queue is bytes and in 
;					AX if it is words.
;
; Operation:		Move new element to the spot pointed to by the tail pointer
;					and then increment the tail pointer by the appropriate 
;                   amount (by 2 if elements are word sized, 1 if elements are 
;                   byte sized). 
;
; Arguments:		AL or AX - value to be added
;					SI - address of queue 	
; Return Value:		None. 
;
; Local Variables:	AL - if queue holds byte-sized elements, this is value to 
;                        add to the queue
;                   AX - if queue holds word-sized elements, this is value to 
;                        add to the queue
;
; Shared Variables: The STRUC is called qStruc, and the queue is called queue. 
; 					elsize (DB) - the size of elements it holds (in bytes)
;					head (DW) - holds the address of the first element 
; 					tail (DW) - holds the address of spot after last element
;
; Global Variables: None. 
;
; Input:			None. 
; Output:			None. 
;
; Error Handling:	None. 
;	
; Algorithms:		If the queue is full, we will loop forever until the queue 
;					is not full. Otherwise, we will add the value to the tail
;					of the queue and increment the tail pointer. 
;
; Data Structures: 	STRUC: has properties length, size, address, head pointer,
;					and tail pointer
;                   alength  - the maximum number of elements that can be stored
;					elsize  - the size of elements to be put in (words or bytes)
;					head    - address of the first element 
; 					tail    - address of the spot after the last element
;
;


Enqueue     PROC    NEAR
            PUBLIC  Enqueue
    
EnqueueInit:
	MOV CX,AX				; store value to enqueue in CX before QueueFull 
							;changes AX
IfQueueIsFull:
    CALL QueueFull              ; check if the queue is full or not 
    JZ IfQueueIsFull           ; if it's full, keep checking
    ;JNZ QueueNotFull            ; if it's not full, exit loop and enqueue value
    
QueueNotFull:
    CMP [SI].elsize, WORDSIZE    ; compare the size to the size of a word 
    JE EnqueueWord               ; if size is 2, then we return a word 
    ; JNE EnqueueByte 
	
EnqueueByte: 
	MOV AX, CX
    MOV BX, [SI].tail          ; load tail address into BX 
    MOV [SI].array[BX], AL     ; move AL value into the array at queue.tail
    ;ADD [SI].tail, BYTESIZE    ; increment the tail by 1 byte 
    ;MOV CX, [SI].alength       ; we will get (tail + 1) mod length 
    ;DEC CX                     ; by performing (tail + 1) AND (size - 1) 
    ;AND CX, [SI].tail          ; mod value will be stored in CX 
    ;MOV [SI].tail, CX          ; move the mod length value into queue.tail  
    ADD BX,BYTESIZE		; tail + 1
	AND BX, ARRAY_SIZE-1	; and it to get mod
	MOV [SI].tail, BX
	
	JMP EndEnqueue 
    
EnqueueWord:
	MOV AX, CX
    MOV BX, [SI].tail          ; load tail address into BX 
    MOV WORD PTR[SI].array[BX], AX     ; move AX value into the array at queue.tail
    ADD [SI].tail, WORDSIZE    ; increment the tail by 2 bytes
    MOV CX, ARRAY_SIZE        ; we will get (tail + 2) mod length 
    DEC CX                      ; by performing (tail + 2) AND (size - 1) 
    AND CX, [SI].tail          ; mod value will be stored in CX 
    MOV [SI].tail, CX          ; move the mod length value into queue.tail
    ;JMP EndEnqueue 
    
EndEnqueue:
    RET
Enqueue     ENDP 
			

CODE    ENDS

    END