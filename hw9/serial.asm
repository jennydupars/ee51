	NAME 	SERIALIO

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;  			     	     Robotrike Serial I/O Routines                       ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains routines for serial initialization and serial I/O 
; while the Robotrike system is running. The functions included are:
; Public functions: 
; 	SerialPutChar(c) - output the character c to the serial channel
; 	SerialPutString - puts string in serial channel for transmission
; 	InitSerial - initializes serial port
; 	SetBaudRate - sets baud rate to different values 
; 	SetParity - sets parity to different types 
; 	SerialEventHandler - handles serial actions at interrupts 
; Local functions: 
; 	ModemStatus	- read from modem register 
; 	LineStatus - enqueue line status error in event queue 
; 	TransmitterEmpty - output next value from transmit queue through serial port 
; 	DataAvailable - receive data and enqueue data events to eventQueue 

; Revision History:
;    11/18/2016         Jennifer Du     initial revision
; 	 11/20/2016			Jennifer Du		commenting
;    12/04/2016         Jennifer Du     fixed critical code, other large code changes 
;                                       to SetBaudRate and added SerialPutString         

; include files 
$INCLUDE(serial.inc)            ; constants used for serial channel
$INCLUDE(common.inc)            ; commonly used constants
$INCLUDE(queue.inc)             ; queue constants 
$INCLUDE(display.inc)           ; constants used for ASCII strings and display


	

CGROUP	GROUP	CODE
DGROUP	GROUP	DATA

CODE SEGMENT PUBLIC 'CODE'

		ASSUME	CS:CGROUP, DS:DGROUP
	
    
    ; External functions

	EXTRN 	EnqueueEvent:NEAR           ; enqueues events to event queue 
    
    EXTRN   Dequeue:NEAR                ; dequeues items from queue
    EXTRN   Enqueue:NEAR                ; enqueues items to queue
    EXTRN   QueueFull:NEAR              ; determines if a queue is full
    EXTRN   QueueInit:NEAR              ; initializes queues
    EXTRN   QueueEmpty:NEAR             ; determines if a queue is empty

;
;
;
; InitSerial 
;
;
; Description:  	This function initializes the serial port and other variables
; 					and data structures needed to output data through the serial 
; 					port, as well as take in information. The default baud rate and
;                   parity are set by this function.
; 
; Operation:    	We initialize a channel queue (where the values sit before being 
; 					output through the serial port) and a kickstartFlag (which tells us 
; 					whether or not the channel queue is empty). We also initialize the 
; 					interrupts by writing to the interrupt enable register. Then we 
; 					call SetBaudRate and SetParity to initialize the parity and baud 
; 					rate settings for the serial port. 
; 
; Arguments:        None.
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: kickstartFlag (w) - keeps track of whether or not the channel 
;                       queue is empty 
; 					transmitQueue (w) - holds values to be output to the Transmit 
;                       Holding Register 
; Global Variables:	None.
; 
; Input:            None.
; Output:           Output to serial chip.
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  transmitQueue - holds values to be output to the Transmit Holding Register 
;


InitSerial 		PROC 	NEAR 
				PUBLIC 	InitSerial 
	
StartInitSerial: 
	PUSHA							    ; save registers 
	
InitializeTransmitQueue: 	
	MOV 	SI, OFFSET(transmitQueue)	; get address of transmit queue 
	MOV 	BL, SELECT_BYTE_SIZE	 	; move in 2nd argument QueueInit will take 
                                        ; (size of each element)
	
	CALL 	QueueInit                   ; then initialize Queue

InitializeKickstartFlag: 	
	MOV 	kickstart, TRUE 			; set kickstart flag since transmit queue 
                                        ; is empty 
	
SetInitialBaudRate: 
	MOV 	BX, DEFAULT_BAUD_INDEX		; set index of the default baud rate (in 
	CALL 	SetBaudRate                 ; the baud rate table)

SetInitialParity: 
	MOV 	BX, DEFAULT_PARITY_INDEX    ; set index of default parity value (in the 
	CALL 	SetParity                   ; parity table), and set parity 
	
InitializeLCR: 
	MOV 	DX, LCR_LOC
	MOV 	AL, LCR_VAL	 	            ; DLAB not set so we can access receiving buffer 
	OUT 	DX, AL                      ; and transmitter holding buffer 
	
InitializeIER: 	
	MOV 	DX, IER_LOC					; write this value to interrupt enable 
	MOV 	AL, IER_VAL 				; register (IER) to enable transmiterr empty
										; interrupt, line status error interrupt, 
	OUT 	DX, AL 					    ; and data available interrupt
			
EndInitSerial: 
	POPA 						        ; restore registers 
	RET 
InitSerial 		ENDP 

	

;
;
;
; SerialPutChar 
;
;
; Description:  	The function outputs the passed character (c) to the serial channel.
; 					It returns with the carry flag reset if the character has been 
; 					"output" (put in the channel’s queue, not necessarily sent over the 
; 					serial channel) and set otherwise (transmit queue is full). The 
; 					character (c) is passed by value in AL.
; 
; 					This function puts the passed value into the queue of data to be sent. 		

; Operation:    	First, we check if the queue is full. If it is, we can't put anymore 
; 					things into it, so we just leave the function after setting the
; 					carry flag. If the queue is not full, then we enqueue the character. 
;                   We also reset the kickstartFlag and perform the kickstart, if the
;                   kickstart flag is set. The kickstart flag keeps track if the 
;                   queue is empty or not. 
; 
; Arguments:        c (AL) - the character to be added to the queue 
; Return Value:     CF - carry flag is set if the queue is full, not set if we are 
;                       able to enqueue to the queue.
;
; Local Variables:  None. 
; Shared Variables: kickstartFlag (r/w) - keeps track of whether the channel queue 
;                       is empty or not 
;                   transmitQueue (r) - holds values ready to be sent over serial 
; 						channel 
; Global Variables:	None.
; 
; Input:            None.
; Output:           None.
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  transmitQueue.

SerialPutChar	PROC 	NEAR 
				PUBLIC 	SerialPutChar 

StartSerialPutChar: 
	PUSHA							        ; save registers 
	MOV     CL, AL                          ; save AX's value (arg value) 
    
CheckTransmitQueueFull: 
	MOV 	SI, OFFSET(transmitQueue)       ; see if the transmit queue is full
	CALL 	QueueFull			
	
	JZ 		TransmitQueueIsFull             
	;JNZ 	TransmitQueueNotFull            ; if not full, then we can enqueue to it
	
TransmitQueueNotFull: 
EnqueueCharToTransmitQueue: 	            ; whether or not we need to kickstart, we
                                            ; enqueue char to transmit queue! 
	MOV 	SI, OFFSET(transmitQueue)		
											; AL should already have char value to be 
                                            ; enqueued 
                                                
    MOV     AL, CL                          ; restore AL with the value of argument  
    
	CALL 	Enqueue 		                ; both arguments populated, enqueue!

	CMP 	kickstart, IS_SET 		        ; see if kickstart flag is set 
	JE 		KickstartSerialChannel          ; if set, we need to kickstart serial 
                                            ; channel after enqueueing
	JNE 	SuccessfullyEnqueued            ; if kickstart was not set, we skip and
                                            ; go to successfully enqueued

KickstartSerialChannel:                     ; if the kickstart flag was set, earlier
	MOV 	kickstart, NOT_SET 	            ; reset kickstart flag 
	
	
	MOV 	DX, IER_LOC			            ; disable transmitter empty interrupt,
    IN      AL, DX 							; first read in IER value 
    MOV     CL, AL 							; store original value, so we can restore later 
    AND     AL, IER_NO_THR_INT_MASK			; use mask to clear THR bit
    OUT     DX, AL 							; then write updated IER value to location 
	
											; then enable it again:
	MOV 	AL, CL                     		; move original IER value into AL 
	OUT 	DX, AL 							; to restore IER value (same as beginning of func)
	JMP 	SuccessfullyEnqueued
    
TransmitQueueIsFull:            ; if transmit queue is full: set carry flag and return
	STC 						; set carry flag since no character was output to transmitQueue
	JMP 	EndSerialPutChar	; end function 

SuccessfullyEnqueued: 
	CLC                         ; clear carry flag if we've successfully enqueued 
	;JMP 	EndSerialPutChar    ; value
EndSerialPutChar: 
	POPA 						; restore registers 
	RET 
SerialPutChar	ENDP 
	
	
	
; SerialPutString
;
;
; Description:  	This function takes a string at a memory location, and sends 
; 					it through the serial channel. 
;
; Operation:    	We are passed the address of the first character in the string, 
; 					and we loop through the entire string by incrementing the
; 					pointer. At each character we point to, we call SerialPutChar 
; 					on that character. We stop looping when we reach the <NULL> 
; 					character, which is how strings in our system are ended. 
;	
; Arguments:        SI - address of string to be sent through serial channel.
; Return Value:     None. 
;
; Local Variables:  None. 
; Shared Variables: None. 
; Global Variables:	None.
; 
; Input:            None.
; Output:           String is passed through serial channel. 
;
; Error Handling:   If the transmit queue is full, we can't enqueue anymore to it.
;                   So, we enqueue an error event to the event queue to handle 
;                   later. 
; Registers Used:   AX.
; Algorithms: 		None. 
; Data Structures:  None.


SerialPutString		PROC 	NEAR 
					PUBLIC 	SerialPutString
	
GetCharacter: 
	MOV 	AL, ES:[SI]						; get character ASCII code 
	
CheckNullTermination: 
	CMP 	AL, ASCII_NULL                  ; check to see if current character 
                                            ; is the end of a string
	JZ 		EndSerialPutString	            ; if so, immediately put string in 
                                            ; through serial channel.
	
	PUSH 	SI                              ; save SI since SerialPutChar might 
                                            ; change it 
	CALL 	SerialPutChar                   ; Put character in AL in through 
                                            ; SerialPutChar
	JC 		HandleTransmitQueueFullError    ; SerialPutChar can raise this issue, 
                                            ; if transmit queue is all full. 
                                            ; in this case, handle the issue by 
                                            ; enqueueing error value and type
	;JNC 	GetNextCharacterToPutSerialChar ; if no carry flag was set, then we 
                                            ; successfully enqueued a character to
                                            ; transmit queue.

GetNextCharacterToPutSerialChar:            ; continue:
	POP 	SI                              ; increment pointer to next character
	INC 	SI                              ; in the string 
	JMP 	GetCharacter                    ; then loop and get this new character
	
HandleTransmitQueueFullError:               ; if transmit queue was full when 
                                            ; SerialPutChar was called:
	MOV 	AL, TRANSMIT_QUEUE_FULL_ERROR   ; enqueue Transmit queue full error
    MOV     AH, ERROR_VAL                   ; use unique transmit queue full identifier
	CALL 	EnqueueEvent 					; and enqueue error event 
	JMP 	EndSerialPutString              ; end function

EndSerialPutString:
	RET 
SerialPutString		ENDP 

;
; SerialEventHandler
;
;
; Description:  	This function handles serial actions at interrupts. The 
; 					possible interrupts we will need to manage are the line 
; 					status interrupt, the data available interrupt, the modem 
; 					status interrupt, and the transmitter empty interrupt. This 
;                   function operates on edge trigerring interrupts.
; 
; Operation:    	We read the interrupt identification register, and see what 
; 					it says. We can either have a line status interrupt, a data 
; 					available interrupt, a transmitter empty interrupt, or a 
; 					modem status interrupt. Based on the value of the IIR, we 
; 					will know which function to call to handle that specific 
; 					interrupt. We then loop back and read the value of the IIR 
;                   if there was an error that we handled. We do this and do not 
;                   exit the serial event handler until we have read the IIR 
;                   value and it indicates that there are no interrupts pending.
; 
; Arguments:        None. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: None. 
; Global Variables:	None.
; 
; Input:            None.
; Output:           None.
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  None.
;
; 

SerialEventHandler 		PROC 	NEAR 
						PUBLIC 	SerialEventHandler

StartSerialEventHandler: 
	PUSHA 						; save registers 
						
ReadIIRValue: 								
	MOV 	DX, IIR_LOC 	        ; store location of interrupt identification reg
	XOR     AX, AX                  ; clear AX to get just the address			
	IN 		AL, DX                  ; in AL after reading it from IIR
	AND		AL, IIR_EVENT_MASK 		; AND IIR value with event mask to get the 
                                    ; relevant event bits
	
IIRInterruptsPending: 
	
    TEST 	AL, IIR_INTPT_PEND_MASK ; test lowest bit to see if interrupts are pending
									; if lowest bit is 1, no interrupts are pending: 
	JNZ 	EndSerialEventHandler	; exit -- no interrupts to take care of 
	;JZ	 	GetInterruptEvent		; if lowest bit is 0, then interrupts are pending: 
									; identify/process specific interrupt event 
	
GetInterruptEvent: 
	
	MOV 	BX, AX 				; move value of interrupt into index register 
	CALL 	CS:Event_Table[BX]	; call one of the functions corresponding to
								; specific interrupt -- functions have been ordered 
								; the way the IIR stores values of interrupts. 
								; An IIR value of: 
								; 0 - modem status (all bits reset)
								; 2 - THR empty request (1st bit set)
								; 4 - received data available (2nd bit set)
								; 6 - receiver line status (1st and 2nd bit set)
								; We have created the CALL event table so that IIR 
								; value corresponds to index in table (word-sized 
								; elements)
	
    JMP     ReadIIRValue        ; read IIR value again to make sure there are no
                                ; more errors, or handle errors if they came up 
                                ; during this
	
EndSerialEventHandler:
	POPA						; restore registers 
	RET 						
SerialEventHandler 		ENDP 



;
;
; SetBaudRate 
;
;
; Description:  	This function sets the baud rate to a certain value, and outputs
; 					it to the baud rate address. 
; 
; Operation:    	Outputs a set baud rate value to the baud rate address. This function 
; 					turns off interrupts before changing the baud rate and turns on 
; 					interrupts afterwards because we don't want the serial port to 
; 					be outputting data while we're changing the baud rate. 
; 
; Arguments:        BX - index of desired baud rate (according to Baud_Rate_Table)
; 						can range from 0 to 18, and even index corresponds to a new 
; 						divisor in the table. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: baudRate - value that contains baud rate 
; Global Variables:	None.
; 
; Input:            None.
; Output:           None.
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  None.
;

SetBaudRate 	PROC 	NEAR 
				PUBLIC 	SetBaudRate

StartSetBaudRate: 							
	PUSHA 					; save registers 
	PUSHF 
	CLI 					; disable interrupts 
SetLCRDLABBit: 
	
	MOV 	DX, LCR_LOC 
	IN 		AL, DX 
	MOV 	CL, AL 					; save original LCR value 
	OR 		AL, LCR_SET_DLAB_MASK   ; set dlab bit 
        
	OUT 	DX, AL                  ; write new LCR value to LCR location 
	
PortChosenBaudRate: 
	MOV 	DX, DLL_LOC             ; now that dlab bit is set, we can modify
	MOV 	AX, CS:Baud_Rate_Table[BX]		; the baud rate with table lookup
	OUT 	DX, AX                  ; of the divisors that correspond to each 
                                    ; baud rate

ReturnToOriginalLCRValue:
	MOV 	DX, LCR_LOC             
	MOV 	AL, CL 					; restore original LCR value stored in CL 
	OUT 	DX, AL                  
    
EndSetBaudRate: 
    POPF                            ;restore flags
	POPA                            ;restore registers

	RET 
SetBaudRate		ENDP 



; 
;
; SetParity  
; 
;
; Description:  	This function sets the parity to a value found in the parity 
; 					table, specified by the index argument BX. This function 
; 					outputs the partiy to the parity address where it will be 'set'.
; 
; Operation:    	Outputs a set parity value to the parity address. Using the 
; 					passed in argument BX, this function uses the parity value at
; 					the index BX in the Parity_Table to set the parity value. It 
; 					ORs the specified parity value with the current value of the 
; 					line control register. 
; 
; Arguments:        BX - index of desired parity value (according to Parity_Table)
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: parityVal - contains the parity value 
; Global Variables:	None.
; 
; Input:            None.
; Output:           None.
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  None.
;


SetParity 		PROC 	NEAR 
				PUBLIC 	SetParity
				
StartSetParity: 
	PUSHF 
    CLI 					; disable interrupts                                    
	PUSHA 					; save registers 

PortChosenParity: 
	MOV 	DX, LCR_LOC 
    
    IN      AL, DX                          ; move LCR value back in 
	AND     AL, CLEAR_PARITY_MASK           ; clears bits 3, 4, and 5 
    
    MOV 	CL, CS:Parity_Table[BX]			; look up parity in table using passed 
                                            ; in argument BX 
        
    OR      AL, CL                          ; get the set bits of the LCR value 
                                            ; as well as the specified parity value 
	
	OUT 	DX, AL
	
EndSetParity: 
    POPF
	POPA 
	RET 
SetParity 		ENDP 



;
;
;
; ModemStatus 
;
;
; Description:  	This function reads from the modem register 
;
; Operation:    	This function reads from the modem register to clear the interrupt. 
; Arguments:        None. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: None.
; Global Variables:	None.
; 
; Input:            None.
; Output:           None.
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  None.

	
ModemStatus 	PROC 	NEAR 

StartModemStatusEvent: 
	PUSHA 
	
ReadModemStatusRegister:

	MOV 	DX, MSR_LOC
	IN 		AL, DX			; read the interrupt to clear it 
	
EndModemStatusEvent:
	POPA
	RET 
ModemStatus		ENDP 

;
;
;
; LineStatus
;
;
; Description:  	This function is called if there is a line status error. 
;
; Operation:    	If there is a line status error, then enqueue the error value
; 					to the event queue 
; 
; Arguments:        None. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: None.
; Global Variables:	None.
; 
; Input:            None.
; Output:           None.
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  None.


LineStatus 		PROC 	NEAR 

StartLineStatusEvent: 
	PUSHA 							; store registers 

ReadLSRValue:
	XOR     AX, AX					; clear register 
	MOV 	DX, LSR_LOC
	IN 		AL, DX 					; read value of line status reg 
	
GetRelevantLSRBits: 	
	AND 	AL, LSR_ERROR_MASK		; use error mask to mask out bits irrelevant 
									; for error handling
	CMP 	AL, FALSE 				; check if masked-out-bits were the only 
									; set bits, if the errors we care about have 
									; not been triggered
	JZ 		EndLineStatusEvent		; if so, end LSR event 

	; JNZ 	EnqueueLSREvent
	
EnqueueLSREvent:
	MOV 	AH, LINE_STATUS_EVENT	; we actually have bits set in the LSR that 
									; correspond to errors 
	SHR 	AL, 1 					; possible errors start at bit 1, so shift 
									; whole value right by 1 to get possible 
									; errors between 0 and 15.
	CALL    EnqueueEvent 			; enqueue error value 
		
EndLineStatusEvent:
	POPA							; restore registers
	RET 							; and return 
LineStatus		ENDP 

;
;
;
; TransmitterEmpty 
;
;
; Description:  	This function is called when the transmitter is empty and
; 					ready to take another value to send through the serial port. 
; 					If the transmit queue is empty, then we do not do this, because
; 					we don't have anything to put in it. We also set the kickstart 
; 					flag since the transmit queue is empty. If the transmit queue has
; 					stuff in it, then we move one value to the transmitter holding 
; 					register, where it will be output through the serial channel. 
; 
; Operation:    	First we check if the transmit queue is empty. If it is, we just 
; 					set the kickstart flag, which tells us the transmit queue is empty. 
; 					If it's not empty, we use the OUT command to put the queue's head
; 					value into the transmit holding register. 
; 
; Arguments:        None. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: transmitQueue (r) - holds values to be output through the serial channel
; 					kickstart (w) - flags whether or not system needs to be kickstarted 
; Global Variables:	None.
; 
; Input:            None.
; Output:           A byte to the THR.
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  transmitQueue - holds values to be output through the serial channel
; 					

	
TransmitterEmpty 	PROC 	NEAR 
	
StartTransmitterEmptyEvent:
	PUSHA
	
CheckTransmitQueueNotEmpty: 				; check if tx queue is empty 
	MOV 	SI, OFFSET(transmitQueue)
	CALL 	QueueEmpty 						
	JNZ 	THREmptyAndTransmitQueueNotEmpty; when thr empty, transmit queue not 
	;JZ 		THREmptyAndTransmitQueueEmpty	; tx queue and thr empty, nothing to do
	
THREmptyAndTransmitQueueEmpty: 			; when thr, tx queue empty: 
										; no values to dequeue, no values to send 
										; through serial 
	MOV 	kickstart, TRUE 			; set kickstart flag 
	JMP 	EndTransmitterEmptyHandler	; and end function 
	
THREmptyAndTransmitQueueNotEmpty: 
	MOV 	SI, OFFSET(transmitQueue)	; dequeue event if transmitQueue not empty
	CALL 	Dequeue 					
										; the value dequeued will be in AL
										
	MOV 	DX, THR_LOC 		
	OUT 	DX, AL 						; put dequeued value into transmitter 
										; holding register ready for serial output
	; JMP 	EndTransmitterEmptyHandler
					
EndTransmitterEmptyHandler:
	POPA
	RET 
TransmitterEmpty	ENDP 
	
;
;
;
; DataAvailable 
;
;
; Description:  	This function is called when there is data available to be
; 					read or used from serial. We look at the receiver buffer register 
; 					(RBR) and read what's there, and then enqueue this event using 
; 					the data-available event type identifier. 
; 
; Operation:    	We access the receiver buffer and write that value to the 
; 					event queue using EnqueueEvent. 
; 
; Arguments:        None. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: None.
; Global Variables:	None. 
; 
; Input:            None.
; Output:           None.
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  eventQueue - queue that stores all events that occur 

DataAvailable 		PROC 	NEAR 

StartDataAvailableEvent:
	PUSHA 
	XOR 	AX, AX 					; clear register 
	
ReadReceiverBufferRegister: 
	MOV 	DX, RBR_LOC
	IN 		AL, DX					; read receiver buffer register 

EnqueueReceivedData: 
	MOV 	AH, DATA_AVAIL_EVENT	; add data available identifier to event
	CALL 	EnqueueEvent			; enqueue to event queue so we can display
									; later on 
				
EndDataAvailableEvent:
	POPA
	RET 
DataAvailable		ENDP 	




; Tables 

Baud_Rate_Table 	LABEL 	WORD 
		
	DW 		480		; 1200 baud  
	DW 		320		; 1800 baud 
	DW 		288		; 2000 baud 
	DW 		240		; 2400 baud 
	DW 		160		; 3600 baud 
	DW 		120 	; 4800 baud 
	DW 		80		; 7200 baud 
	DW 		60		; 9600 baud 
	DW 		30		; 19200 baud 
	DW 		15 		; 38400 baud 
	
	
Parity_Table 		LABEL 	BYTE
	
	DB 		00000000B		; none parity 
	DB 		00001000B		; odd parity 
	DB 		00011000B		; even parity 
	DB 		00111000B		; stick parity 
	DB 		00101000B		; clear parity 
	
	

Event_Table 	LABEL 		WORD
				PUBLIC 		Event_Table
	
	DW 		ModemStatus			; 0 - modem status 
	DW 		TransmitterEmpty	; 2 - THR empty request 
	DW 		DataAvailable		; 4 - received data available
	DW 		LineStatus   		; 6 - receiver line status 


	
	
CODE 	ENDS
	
	
;
; the data segment 

DATA 	SEGMENT     PUBLIC 	'DATA'

    kickstart 	    DB 	    ?
	; this keeps track of whether or not our queue is empty (1=empty, 0=not)

    transmitQueue		qStruc      < >    
	; queue that holds values waiting to be output through the serial port


		
		
	
DATA 	ENDS

END