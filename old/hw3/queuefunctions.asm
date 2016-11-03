NAME    CONVERTS

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
$INCLUDE(queuefunctions.inc)
$INCLUDE(common.inc)

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE    SEGMENT    PUBLIC   'CODE'
DATA    SEGMENT    PUBLIC   'DATA'
        ASSUME CS:CGROUP, DS:DGROUP
        

; QueueInit
;
; Description: 		Initialize the queue of the passed length and element size
;				   	at the passed address. This procedure does all the 
;					necessary initialization to prepare the queue for use. 
;					After calling this procedure the queue should be empty 
;					and ready to accept values. 

////////////////////////////////// IS THERE A MAX here (max items)
;                   The passed length is the 
;					maximum number of items that can be stored in the queue. 
;					The passed element size specifies whether each entry in 
;					the queue is a byte or a word. If it is 
;					true (non-zero) the elements are words and if it is false 
;					(zero) they are bytes. The address is passed in	SI by value 
;					(thus the queue starts at DS:SI), the length (passed by 
;					value in AX, and the element size (passed by value in BL). 
;
;
; Operation: 		Set the STRUC's values according to the values passed into 
;					the function:
;                   length - will be set to l, the maximum number of elements
;					size - the size of elements to be put in 
;						  (size = 1 means word, size = 0 means byte)
;					headPTR - holds the address of the first element 
; 					tailPTR - holds the address of the spot after the last element
;
; Arguments: 		SI - address passed in by the function
;					AX - length of queue
;					BL - size of element (bytes or words)
; Return Value:		None. 
;
; Local Variables:	Shared. /////////////////////////////////////////////////////////
//////////////////////////// talk about size of each variable
; Shared Variables: The STRUC: We'll call it struc. 
; 					length - will be set to l, the maximum number of elements
;					size - the size of elements to be put in 
;						  (size = 1 means word, size = 0 means byte)
;					headPTR - holds the address of the first element 
; 					tailPTR - holds the address of the spot after the last element
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
;                   length  - the maximum number of elements that can be stored
;					size    - the size of elements to be put in (words or bytes)
;					headPTR - address of the first element 
; 					tailPTR - address of the spot after the last element
;
;
//////////////////////////////////// furrreal what do i do
;Pseudocode:

;	struc.length = l 
;	struc.size = s 
;	struc.headPTR = 0
;	struc.tailPTR = 0 

depending on s=0 or 1, set size = 1 or 2 (BYTESIZE or WORDSIZE)




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
; Local Variables: 	Shared. 
; Shared Variables:	The STRUC: We'll call it struc. 
; 					length - will be set to l, the maximum number of elements
;					size - the size of elements to be put in 
;						  (size = 1 means word, size = 0 means byte)
;					headPTR - holds the address of the first element 
 					tailPTR - holds the address of the last element ///////////////////// no this doesnt work/////////////////////////////////////////
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
; Data Structures: 	STRUC: has properties length, size, address, head pointer,
;					and tail pointer
;
;

	
	
QueueEmptyInit:
    MOV AX, qstruc.headPTR      ; move headPTR's value into AX
    CMP AX, qstruc.tailPTR      ; if values are equal, then queue is empty
	
			; do i need to move it into register to cmp

	

;
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
; Return Value:		ZF - set if queue is full, clear otherwize. 
;
; Local Variables:	Shared. 
; Shared Variables:	The STRUC: We'll call it struc. 
; 					length - will be set to l, the maximum number of elements
;					size - the size of elements to be put in 
;						  (size = 1 means word, size = 0 means byte)
;					headPTR - holds the address of the first element 
; 					tailPTR - holds the address of the spot after the last element 
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
; Data Structures: 	STRUC: has properties length, size, address, head pointer,
;					and tail pointer
; 
;
; Pseudocode: 
	
;	// we want struc.tailPTR + 1 to be headPTR mod length, so that even when it wraps 
;	// around it will be at the same spot.
;
;	If (struc.tailPTR + 1 % struc.length == struc.headPTR):
;		set zero flag (CMP (struc.tailPTR + 1 % struc.length), struc.headPTR)
;
QueueFullInit:
    MOV CX, qstruc.length       ; not necessary if we can directly DIV AX by length ////////////////////////////////////////////////////
    MOV AX, qstruc.tailPTR      ; move tailPTR into AX so we can operate on it
                                ; without changing value of tailPTR

    ADD AX, qstruc.size         ; increment tailPTR's value to point to next spot
    DIV CX                      ; divide tailPTR + size by length of queue, for wraparound
                                ; DX contains remainder (x mod length = DX)
    CMP DX, qstruc.headPTR      ; if (tail+1) mod length are equal, then the queue is full.
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
; Shared Variables:	The STRUC: We'll call it struc. 
; 					length - will be set to l, the maximum number of elements
;					size - the size of elements to be put in 
;						  (size = 1 means word, size = 0 means byte)
;					headPTR - holds the address of the first element 
; 					tailPTR - holds the address of the spot after the last element 
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
; Data Structures: 	STRUC: has properties length, size, address, head pointer,
;					and tail pointer
;
;
; Pseudocode:
; 	while (QueueEmpty):
;		// loops forever until you stop it 
;	endwhile
;
; 	// take the element pointed to by the tail pointer, 
;	// and MOV it to AX or AL depending on the element size.
;	
;	CMP struc.size to 0 and 1: 
;		if 1: they're words
;			Move element[headPTR] -> AX
;			// set headPTR equal to headPTR+2 % length just in case it wraps around
;			headPTR += 2 // to new head of queue 
;			headPTR = headPTR % struc.length // for wraparound
;		if 0: they're bytes
;			Move element[headPTR] -> AL 
;			headPTR += 1 // to new head of queue 
;			headPTR = headPTR % struc.length  //for wraparound 
;	
;
;
;
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
; Local Variables:	Shared.
; Shared Variables:	The STRUC: We'll call it struc. 
; 					length - will be set to l, the maximum number of elements
;					size - the size of elements to be put in 
;						  (size = 1 means word, size = 0 means byte)
;					headPTR - holds the address of the first element 
; 					tailPTR - holds the address of the spot after the last element
;
; Global Variables: None. 
;
; Input:			None. 
; Output:			None. 
;
; Error Handling:	None. 
;	
; Algorithms:		If the queue is full, we will loop forever until the queue 
;					is not full. If the queue is empty, we will put the value
;					at the tail, and then increment the tail. Otherwise, we 
;					will put the value to the tail
;					of the queue and increment the tail pointer. 
; Data Structures: 	STRUC: has properties length, size, address, head pointer,
;					and tail pointer
;
;
;
; Pseudocode:
	
	while(QueueFull):
		// this is an infinite loop until stopped at some point.
	endwhile 
	ig
	// else, if there's space:
	//Move value -> element[tailPTR]
			///////////////////////////////////////////////////////////////////////////////// move value into queue in tailPTR+1 spot 
	MOV value -> array[tailPTR + 1]
	
	// appropriately increment tail pointer 
	CMP SIZE to 0 and 1: 
		if 1: value was a word:	
			tailPTR += 2 
			tailPTR = tailPTR % struc.length		// for wraparound 
		if 0: value was a byte: 
			tailPTR += 1 
			tailPTR = tailPTR % struc.length		// for wraparound
			
	//////////// first move element in and then increment tail pointer 
			

CODE    ENDS


; the data segment

DATA    SEGMENT     PUBLIC     'DATA'
    ////////////// how do you make a struc
    STRUC   qstruc
        var_name    D[size]     value (can be ?)
        headPTR     size????    0       /////////////// should it be ? or 0
        tailPTR     size????    0
        size        DB      ?
        length      size????    ?
    ENDSTRUC
DATA    ENDS

    END