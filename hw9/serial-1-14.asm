



	NAME 	SERIALIO

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;  			     	     Robotrike Serial I/O Routines                       ;
;                           	   Homework 7        		                 ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains routines for serial initialization and serial I/O 
; while the Robotrike system is running. The functions included are:
; 	SerialPutChar(c) - output the character c to the serial channel
; 	InitSerial - initializes serial port
; 	SetBaudRate - sets baud rate to different values 
; 	SetParity - sets parity to different types 
; 	SerialEventHandler - handles serial actions at interrupts 
; 	ModemStatus	- read from modem register 
; 	LineStatus - enqueue line status error in event queue 
; 	TransmitterEmpty - output next value from transmit queue through serial port 
; 	DataAvailable - receive data 

; Revision History:
;    11/18/2016         Jennifer Du     initial revision
; 	 11/20/2016			Jennifer Du		commenting 

; include files 
$INCLUDE(serial.inc)
$INCLUDE(common.inc)
$INCLUDE(queue.inc)
$INCLUDE(display.inc)
;$INCLUDE(macros.inc)                                ;///////////////////////////////////////// how do i make macros work ///////////////////////////////////////////////


	
CGROUP	GROUP	CODE
DGROUP	GROUP	DATA

CODE SEGMENT PUBLIC 'CODE'

		ASSUME	CS:CGROUP, DS:DGROUP
	
    
    ; External functions

	EXTRN 	EnqueueEvent:NEAR
    
    EXTRN   Dequeue:NEAR
    EXTRN   Enqueue:NEAR
    EXTRN   QueueFull:NEAR
    EXTRN   QueueInit:NEAR
    EXTRN   QueueEmpty:NEAR

;
;
;
; InitSerial 
;
;
; Description:  	This function initializes the serial port and other variables
; 					and data structures needed to output data through the serial 
; 					port, as well as take in information. The default baud rate is 
; 					9600 baud and the default parity is even parity. 
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
; Shared Variables: kickstartFlag - keeps track of whether or not the channel queue is empty 
; 					transmitQueue - holds values to be output to the Transmit Holding Register 
; Global Variables:	None.
; 
; Input:            None.
; Output:           None.
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  transmitQueue - holds values to be output to the Transmit Holding Register 


InitSerial 		PROC 	NEAR 
				PUBLIC 	InitSerial 
	
StartInitSerial: 
	PUSHA							; save registers 
	
InitializeTransmitQueue: 	
	MOV 	SI, OFFSET(transmitQueue)		; get address of transmit queue 
	MOV 	BL, SELECT_BYTE_SIZE	 			; move in 2nd argument QueueInit will take (size of each element)
	
	CALL 	QueueInit

InitializeKickstartFlag: 	
	MOV 	kickstart, IS_SET 			; set kickstart flag since transmit queue is empty 
	
SetInitialBaudRate: 
	MOV 	BX, DEFAULT_BAUD_INDEX		; set index of the default baud rate (in the baud rate table)
	CALL 	SetBaudRate 

SetInitialParity: 
	MOV 	BX, DEFAULT_PARITY_INDEX
	CALL 	SetParity 
	
InitializeLCR: 
	MOV 	DX, LCR_LOC
	MOV 	AL, LCR_VAL	 	; DLAB not set so we can access receiving buffer and transmitter holding buffer 
	OUT 	DX, AL 
	
InitializeIER: 	
	MOV 	DX, IER_LOC
	MOV 	AL, IER_VAL 
	OUT 	DX, AL 					; write port value to enable interrupts 
			
EndInitSerial: 
	POPA 						; restore registers 
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
; 					carry flag. If the queue is not full,
; 					then we enqueue the character. We also reset the kickstartFlag, which 
; 					keeps track if the queue is empty or not. 
; Arguments:        c (AL) - the character to be added to the queue 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: kickstartFlag - keeps track of whether the channel queue is empty or not 
; Global Variables:	None.
; 
; Input:            None.
; Output:           None.
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  transmitQueue (not accessed in this function, but functions called in 
; 					this function change it)

SerialPutChar	PROC 	NEAR 
				PUBLIC 	SerialPutChar 

StartSerialPutChar: 
	PUSHA							; save registers 
	MOV     CL, AL                       ; save AX's value (arg value) 
    
CheckTransmitQueueFull: 
	MOV 	SI, OFFSET(transmitQueue)
	CALL 	QueueFull			
	
	JZ 		TransmitQueueIsFull
	;JNZ 	TransmitQueueNotFull
	
; TransmitQueueIsFull: 
	; STC 						; set carry flag since no character was output to transmitQueue
	; JMP 	EndSerialPutChar	; end function 

; TransmitQueueNotFull: 
	; CMP 	kickstart, IS_SET 		; see if kickstart flag is set 
	; JE 		KickstartSerialChannel
	; JNE 	EnqueueCharToTransmitQueue

; KickstartSerialChannel: 
	; MOV 	kickstart, NOT_SET 	; reset kickstart flag 
	; CLC 						; clear carry flag 
	
	; MOV 	DX, IER_LOC			; disable transmitter empty interrupt, then enable it again
	; MOV 	AL, IER_VAL_NO_THR_INT 	
	; OUT 	DX, AL
	
	; MOV 	AL, IER_VAL
	; OUT 	DX, AL 	
	
	; ; JMP 	EnqueueCharToTransmitQueue

; EnqueueCharToTransmitQueue: 	; whether or not we need to kickstart, we enqueue char to transmit queue! 
	; MOV 	SI, OFFSET(transmitQueue)		
												; ; AL should already have char value to be enqueued 
                                                
    ; MOV     AL, CL                  ; restore AL with the value of argument  
    
	; CALL 	Enqueue 	
	
TransmitQueueNotFull: 
EnqueueCharToTransmitQueue: 	; whether or not we need to kickstart, we enqueue char to transmit queue! 
	MOV 	SI, OFFSET(transmitQueue)		
												; AL should already have char value to be enqueued 
                                                
    MOV     AL, CL                  ; restore AL with the value of argument  
    
	CALL 	Enqueue 		

	CMP 	kickstart, IS_SET 		; see if kickstart flag is set 
	JE 		KickstartSerialChannel
	JNE 	SuccessfullyEnqueued;EndSerialPutChar;EnqueueCharToTransmitQueue

KickstartSerialChannel: 
	MOV 	kickstart, NOT_SET 	; reset kickstart flag 
	
	
	MOV 	DX, IER_LOC			; disable transmitter empty interrupt, then enable it again
	MOV 	AL, IER_VAL_NO_THR_INT 	
	OUT 	DX, AL
	
	MOV 	AL, IER_VAL
	OUT 	DX, AL 	
	JMP 	SuccessfullyEnqueued
TransmitQueueIsFull: 
	STC 						; set carry flag since no character was output to transmitQueue
	JMP 	EndSerialPutChar	; end function 
SuccessfullyEnqueued: 
	CLC 
	;JMP 	EndSerialPutChar
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
; Error Handling: 
; Registers Used: 
; Algorithms: 		None. 
; Data Structures:  None.

SerialPutString		PROC 	NEAR 
					PUBLIC 	SerialPutString

GetCharacter: 
	MOV 	AL, DS:[SI]
	CALL 	SerialPutChar 
	JC 		HandleTransmitQueueFullError 
	;JNC 	CheckNullTermination
CheckNullTermination: 
	CMP 	AL, 0;ASCII_NULL 
	JE 		EndSerialPutString
	;JNE 	GetNextCharacterToPutSerialChar:
GetNextCharacterToPutSerialChar: 
	INC 	SI 
	JMP 	GetCharacter
	
HandleTransmitQueueFullError: 
	MOV 	AL, 09;TRANSMIT_QUEUE_FULL_ERROR 		; or whatever value corresponds to a transmit queue full error 
    MOV     AH, 0                       ; ERROR_VAL s
	CALL 	EnqueueEvent 
	JMP 	EndSerialPutString 

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
; 					status interrupt, and the transmitter empty interrupt. 
; 
; Operation:    	We read the interrupt identification register, and see what 
; 					it says. We can either have a line status interrupt, a data 
; 					available interrupt, a transmitter empty interrupt, or a 
; 					modem status interrupt. Based on the value of the IIR, we 
; 					will know which function to call to handle that specific 
; 					interrupt. 
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
						
ReadIIRValue: 								; i was jumping to the wrong place for a long time, did not recheck what IIR was after every iteration 
	MOV 	DX, IIR_LOC 	
	MOV     AX, 0000H           ; CLR(AX)					; use macro defined in macros.inc to clear a register 
	IN 		AL, DX 
	AND		AL, IIR_EVENT_MASK 				; get just the lowest 3 bits 
	
InterruptsPending: 
	
	;TESTBIT(AL, 0)				; test lowest bit (interrupt pending bit)	 
    TEST 	AL, 00000001B
	JNZ 	EndSerialEventHandler	; if 1, then exit 
	JZ	 	GetInterruptEvent		; if bit is 0, then interrupts are pending. 
	
GetInterruptEvent: 
	
    ;SHR 	AX, 1 				; get rid of lowest bit to isolate value of interrupt 
	MOV 	BX, AX 				; move value of interrupt into index register 
	CALL 	CS:Event_Table[BX]	; call one of the functions 
	
    JMP     ReadIIRValue 
	
	
	
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

StartSetBaudRate: 							; I used the wrong index for baud rate, forgot it was a word table 
	;CLI
	PUSHA 					; save registers 
	PUSHF 
	CLI 					; disable interrupts 
SetLCRDLABBit: 
 
	; MOV 	DX, LCR_LOC
	; MOV 	AL, LCR_VAL_DLAB	 	; set DLAB so that we can set baud rate 
	; OUT 	DX, AL 
	
	MOV 	DX, LCR_LOC 
	IN 		AL, DX 
	MOV 	CL, AL 					; save original LCR value 
	OR 		AL, LCR_SET_DLAB_MASK
	
	OUT 	DX, AL 
	
PortChosenBaudRate: 
	MOV 	DX, DLL_LOC 
	MOV 	AX, CS:Baud_Rate_Table[BX]	
	; OUT 	DX, AL 
	
    ; MOV     DX, DLM_LOC 
    ; MOV     AL, AH 
    ; OUT     DX, AL 
	
	OUT 	DX, AX

ReturnToOriginalLCRValue:
	MOV 	DX, LCR_LOC
	MOV 	AL, CL 					; restore original LCR value stored in CL 
	OUT 	DX, AL 
    
EndSetBaudRate: 
    POPF 
	POPA 
    ;STI 					; enable interrupts again 
	RET 
SetBaudRate		ENDP 



; 
;
; SetParity  
; 
;
; Description:  	This function sets the parity to a TBD value, and outputs
; 					it to the parity address where it will be 'set'.
; 
; Operation:    	Outputs a set parity value to the parity address. 
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
	;CLI 					; disable interrupts                                    
	PUSHA 					; save registers 
    PUSHF 

PortChosenParity: 
	MOV 	DX, LCR_LOC 
    
    IN      AL, DX                          ; move LCR value back in 
	AND     AL, CLEAR_PARITY_MASK           ; clears bits 3, 4, and 5 
    
    MOV 	CL, CS:Parity_Table[BX]			
        
    OR      AL, CL                          ; get the set bits of the LCR value as well as the specified parity value 
	
	OUT 	DX, AL
	
EndSetParity: 
	;STI 					; enable interrupts again 
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
; Shared Variables: eventQueue - queue that stores all events that occur  
; Global Variables:	None.
; 
; Input:            None.
; Output:           None.
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  eventQueue - queue that stores all events that occur 

	
ModemStatus 	PROC 	NEAR 
				PUBLIC 	ModemStatus

StartModemStatusEvent: 
	PUSHA 
	
ReadModemStatusRegister:
	MOV     AX, 0000H       ; CLR(AX)
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
; Global Variables:	eventQueue - queue that stores all events that occur  
; 
; Input:            None.
; Output:           None.
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  eventQueue - holds events in a queue 


LineStatus 		PROC 	NEAR 

StartLineStatusEvent: 
	PUSHA 

ReadLSRValue:
	;MOV     AX, 0000H           ; CLR(AX)
	MOV 	DX, LSR_LOC
	IN 		AL, DX 
	
GetRelevantLSRBits: 	
	AND 	AL, LSR_ERROR_MASK
	CMP 	AL, 0 
	JZ 		EndLineStatusEvent
EnqueueLSREvent:
	MOV 	AH, LINE_STATUS_EVENT
	
	CALL    EnqueueEvent 
	JMP 	ReadLSRValue
EndLineStatusEvent:
	POPA
	RET 
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
; Shared Variables: transmitQueue - holds values to be output through the serial channel
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
	
CheckTransmitQueueNotEmpty: 
	MOV 	SI, OFFSET(transmitQueue)
	CALL 	QueueEmpty 
	JZ 		THREmptyAndTransmitQueueEmpty	; when empty, ZF=1
	JNZ 	THREmptyAndTransmitQueueNotEmpty
	
THREmptyAndTransmitQueueEmpty: 
	MOV 	kickstart, IS_SET 			; set kickstart flag 
	JMP 	EndTransmitterEmptyHandler	; and end function 
	
THREmptyAndTransmitQueueNotEmpty: 
	MOV 	SI, OFFSET(transmitQueue)
	CALL 	Dequeue 					
										; the value dequeued will be in AL
										
	MOV 	DX, THR_LOC 	
	OUT 	DX, AL 
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
; 					read or used. We look at the receiver buffer register (RBR)
; 					and read what's there, and then enqueue this event. 
; 
; Operation:    	We access the receiver buffer and write that value to the 
; 					event queue. 
; 
; Arguments:        None. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: None.
; Global Variables:	eventQueue - queue that stores all events that occur 
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
	MOV     AX, 0000H           ; CLR(AX)
	
ReadReceiverBufferRegister: 
	MOV 	DX, RBR_LOC
	IN 		AL, DX					; read receiver buffer register 

EnqueueReceivedData: 
	MOV 	AH, DATA_AVAIL_EVENT
	CALL 	EnqueueEvent
				
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