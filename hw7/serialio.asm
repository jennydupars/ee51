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
$INCLUDE(serialio.inc)
$INCLUDE(macros.inc)

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP
	
	; pre-written code used to populate event queue
	EXTRN 	EnqueueEvent:NEAR
	
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
	MOV 	SI, DS:OFFSET(transmitQueue)		; get address of transmit queue 
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
	
CheckTransmitQueueFull: 
	MOV 	SI, DS:OFFSET(transmitQueue)
	CALL 	QueueFull			
	
	JZ 		TransmitQueueIsFull
	JNZ 	TransmitQueueNotFull
	
TransmitQueueIsFull: 
	STC 						; set carry flag since no character was output to transmitQueue
	JMP 	EndSerialPutChar	; end function 

TransmitQueueNotFull: 
	CMP 	kickstart, IS_SET 		; see if kickstart flag is set 
	JE 		KickstartSerialChannel
	JNE 	EnqueueCharToTransmitQueue

KickstartSerialChannel: 
	MOV 	kickstart, NOT_SET 	; reset kickstart flag 
	CLC 						; clear carry flag 
	
	MOV 	DX, IER_LOC			; disable transmitter empty interrupt, then enable it again
	MOV 	AL, IER_VAL_NO_THR_INT 	
	OUT 	DX, AL
	
	MOV 	AL, IER_VAL
	OUT 	DX, AL 	
	
	; JMP 	EnqueueCharToTransmitQueue

EnqueueCharToTransmitQueue: 	; whether or not we need to kickstart, we enqueue char to transmit queue! 
	MOV 	SI, DS:OFFSET(transmitQueue)		; don't need to redo it if i don't change it ///////////////////////////////
												; AL should already have char value to be enqueued 
	CALL 	Enqueue 	
	
EndSerialPutChar: 
	POPA 						; restore registers 
	RET 
SerialPutChar	ENDP 
	

;
;
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
						
ReadIIRValue: 
	MOV 	DX, IIR_LOC 	
	%CLR(AX)					; use macro defined in macros.inc to clear a register 
	IN 		AL, DX 
	AND		AL, IIR_EVENT_MASK 				; get just the lowest 3 bits 
	
InterruptsPending: 
	
	%TESTBIT(AL, 0)				; test lowest bit (interrupt pending bit)	
	JE 		EndSerialEventHandler	; if 1, then exit 
	JNE 	GetInterruptEvent		; if bit is 0, then interrupts are pending. 
	
GetInterruptEvent: 
	SHR 	AL, 1 				; get rid of lowest bit to isolate value of interrupt 
	MOV 	BX, AL 				; move value of interrupt into index register 
	JMP 	CS:Event_Table[BX]	; jump to a place 
		//////////////////////////////////////////////////////////////////////////////// do i do EOI somewhere here 
	
	; do i test the lowest bit again to see if i jump back to top /////////////////////////////////////////////////////////////////////
	%TESTBIT(AL, 0)				; test lowest bit (interrupt pending bit)	
	JE 		EndSerialEventHandler	; if 1, then exit 
	JNE 	GetInterruptEvent		; if bit is 0, then interrupts are pending. 
	
EndSerialEventHandler:
	POPA						; restore registers 
	IRET 						; do i do IRET here ////////////////////////////////////////////////////////////////////////////////
SerialEventHandler 		ENDP 


		//////////////////////////////////////////////////////////// which of these 4 events do i need to enqueue 

	read the IIR (interrupt identification register)
		see which of these to do based on the set bits: 
		
		case1: 								; line status - when there's a serial error
			AH = line_status_event_constant	; store these values here for enqueueEvent 
			AL = line_status_regs_val 			; later (event constant in AH, val in 
			CALL lineStatus 					; AL)
		
		case2:  							; modem status - read modem status register 
			AH = modem_control_constant 	; store these values for enqueueEvent later 
			AL = modem_control_regs_val 	
			CALL modemStatus
			
		case3:  							; transmitter is empty case
			AH = thr_empty_constant 		; store these values for enqueueEvent later 
			AL = thr_val					; transmitter holding register value 
			CALL transmitterEmpty
			
		case4: 								; data available - gets data from receiving buffer
			AH = data_received_constant		; store these values for enqueueEvent later 
			AL = received_data_val 			
			CALL dataAvailable
	
	read the IIR again to take care of next interrupt (if more than one)

;
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
; Arguments:        BX - what you want the baud rate to be /////////////////////////////////////////////
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
	CLI 					; disable interrupts 
	PUSHA 					; save registers 
	
											; //////////////////////// WAIT WHAT KIND OF INTERRUPTS DO I DISABLE ////////////////////
	
SetLCRDLABBit: 
 
	MOV 	DX, LCR_LOC
	MOV 	AL, LCR_VAL_DLAB	 	; set DLAB so that we can set baud rate 
	OUT 	DX, AL 
	
PortChosenBaudRate: 
	MOV 	DX, DLL_LOC 
	MOV 	AL, DS:Baud_Rate_Table[BX]	
	OUT 	DX, AL 
	
ReturnToDefaultLCRValue:
	MOV 	DX, LCR_LOC
	MOV 	AL, LCR_VAL	 	
	OUT 	DX, AL 
	
EndSetBaudRate: 
	STI 					; enable interrupts again 
	POPA 
	RET 
SetBaudRate		ENDP 


	disable interrupts 
	OUT baudRate to BAUD_RATE_ADDRESS 
	enable interrupts 
	
;
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
; Arguments:        None. 
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
	CLI 					; disable interrupts 
	PUSHA 					; save registers 
	
											; //////////////////////// WAIT WHAT KIND OF INTERRUPTS DO I DISABLE ////////////////////	
PortChosenParity: 
	MOV 	DX, LCR_LOC 
	MOV 	AL, DS:Parity_Table[BX]				/////////////////////////////////////// why are parity table values defined as words 
	SHL 	AL, 3 			; get the 1st bit to the 4th bit position (where the parity bits are)
	%CLRBIT(AL,3)
	%CLRBIT(AL,4)
	%CLRBIT(AL,5)
	
	OR 		AL, LCR_VAL_BLANK_PARITY 	
	OUT 	DX, AL
	

	//////////////////////////// how does parity values work, not makeing sense 
EndSetParity: 
	STI 					; enable interrupts again 
	POPA 
	RET 
SetParity 		ENDP 

	OUT parity to PARITY_ADDRESS 	; (bits 3,4,5 of serial LCR)

;
;
;
; ModemStatus 
;
;
; Description:  	This function reads from the modem register 
;
; Operation:    	This function reads from the modem register and stores the 
; 					value in AX so we can use it later. 
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
	%CLR(AX)
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
; Data Structures:  eventQueue - holds events in a queue (not initialized in this code)





LineStatus 		PROC 	NEAR 
				PUBLIC 	LineStatus

StartLineStatusEvent: 
	PUSHA 

ReadLSRValue:
	%CLR(AX)
	MOV 	DX, LSR_LOC
	IN 		AL, DX 
	
GetRelevantLSRBits: 	
	AND 	AL, LSR_ERROR_MASK
	
EnqueueLSREvent:
	MOV 	AH, LINE_STATUS_EVENT
	
	EnqueueEvent 

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
					PUBLIC 	TransmitterEmpty
	
StartTransmitterEmptyEvent:
	PUSHA
	
CheckTransmitQueueNotEmpty: 
	MOV 	SI, DS:OFFSET(transmitQueue)
	CALL 	QueueEmpty 
	JZ 		THREmptyAndTransmitQueueEmpty	; when empty, ZF=1
	JNZ 	THREmptyAndTransmitQueueNotEmpty
	
THREmptyAndTransmitQueueEmpty: 
	MOV 	kickstart, IS_SET 			; set kickstart flag 
	JMP 	EndTransmitterEmptyHandler	; and end function 
	
THREmptyAndTransmitQueueNotEmpty: 
	MOV 	SI, DS:OFFSET(transmitQueue)
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
					PUBLIC 	DataAvailable

StartDataAvailableEvent:
	PUSHA 
	%CLR(AX)
	
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



	
	
CODE 	ENDS
	
	
;
; the data segment (SHARED VARIABLES)

DATA 	SEGMENT     PUBLIC 	'DATA'


kickstartFlag 	DB 	?
	; this keeps track of whether or not our queue is empty (1=empty, 0=not)

transmitQueue		DB 		TX_QUEUE_SIZE 		DUP 	(?)
	; queue that holds values waiting to be output through the serial port

; Tables 

Baud_Rate_Table 	LABEL 	WORD 
					PUBLIC 	Baud_Rate_Table
		
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
	
	
Parity_Table 		LABEL 	WORD 
					PUBLIC 	Parity_Table
	
	DW 		0000B		; none parity 
	DW 		0100B		; odd parity 
	DW 		0110B		; even parity 
	DW 		0101B		; space parity 
	DW 		0111B		; mark parity 
	
	/////////////////////////////////////////////////////why do these need to be words 


Event_Table 	LABEL 		WORD
				PUBLIC 		Event_Table
	
	DW 		OFFSET(ModemStatus)			; 0 - modem status 
	DW 		OFFSET(TransmitterEmpty)	; 2 - THR empty request 
	DW 		OFFSET(DataAvailable)		; 4 - received data available
	DW 		OFFSET(LineStatus)			; 6 - receiver line status 
		
		
	
DATA 	ENDS

END