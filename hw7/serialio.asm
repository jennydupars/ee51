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
; 	 11/19/2016			Jennifer Du		commenting 

; include files 
$INCLUDE(serialio.inc)	; constants used for configuring & sending info through serial
$INCLUDE(common.inc)	; commonly used constants 
$INCLUDE(queue.inc)		; queue variables defined here 
	

CGROUP	GROUP	CODE
DGROUP	GROUP	DATA

CODE SEGMENT PUBLIC 'CODE'

		ASSUME	CS:CGROUP, DS:DGROUP
	
    
    ; External functions

	EXTRN 	EnqueueEvent:NEAR		; adds values to event queue 
    
    EXTRN   Dequeue:NEAR			; queue routines 
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
; Operation:    	We initialize a transmit queue (where the values sit before being
; 					output through the serial port) and a kickstart flag (which 
; 					tells whether or not the transmit queue is empty). We also 
; 					initialize interrupts by writing to the interrupt enable 
; 					register. Then we call SetBaudRate and SetParity to initialize 
; 					the parity and baud rate settings for the serial port. The 
; 					default baud rate is 9600 and the default parity is even. The 
; 					default queue element size is byte. 
; 
; Arguments:        None. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: kickstart - keeps track of whether channel queue is empty
; 					transmitQueue - queue of values to be sent to THR 
; Global Variables:	None.
; 
; Input:            None.
; Output:           None.
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  transmitQueue - queue of values to be sent to THR 


InitSerial 		PROC 	NEAR 
				PUBLIC 	InitSerial 
	
StartInitSerial: 
	PUSHA								; save registers 
	
InitializeTransmitQueue: 	
	MOV 	SI, OFFSET(transmitQueue)	; get address of transmit queue 
	MOV 	BL, SELECT_BYTE_SIZE	 	; move in 2nd argument QueueInit will take
										; (size of each element)
	CALL 	QueueInit					; then initialize queue at that address 

InitializeKickstartFlag: 	
	MOV 	kickstart, IS_SET 			; set kickstart flag, transmit queue is empty
	
SetInitialBaudRate: 
	MOV 	BX, DEFAULT_BAUD_INDEX		; set default baud rate index (found in
	CALL 	SetBaudRate 				; Baud_Rate_Table), corresponds to 9600 baud

InitializeLCR: 
	MOV 	DX, LCR_LOC					; write to line control register to set word 
	MOV 	AL, LCR_VAL	 				; length, stop bits, parity 
	OUT 	DX, AL 

SetInitialParity: 
	MOV 	BX, DEFAULT_PARITY_INDEX	; set default parity value 
	CALL 	SetParity 					; set parity 
	
InitializeIER: 	
	MOV 	DX, IER_LOC					; write this value to interrupt enable 
	MOV 	AL, IER_VAL 				; register (IER) to enable transmitter empty
	OUT 	DX, AL 						; interrupt, line status error interrupt, 
										; and data available interrupt 			
EndInitSerial: 
	POPA 						; restore registers 
	RET 
InitSerial 		ENDP 

;
;
;
; SerialPutChar 
;
; Description:  	The function outputs the passed character (c) to the serial 
; 					channel. It returns with the carry flag reset if the character 
; 					has been "output" (put in the channel’s queue, not necessarily 
; 					sent over the serial channel) and set otherwise (transmit queue
; 					is full). The character (c) is passed by value in AL. This 
; 					function puts the passed value into the queue of data to be sent.

; Operation:    	First, we check if the queue is full. If it is, we cannot put 
; 					more things into it, so we just leave the function after setting
; 					the	carry flag. If the queue is not full, then we enqueue the 
; 					character. We also reset the kickstartFlag, which keeps track 
; 					if the queue is empty or not, and then actually kickstart the 
; 					serial channel. 
;
; Arguments:        c (AL) - the character to be added to the queue 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: kickstart - keeps track of whether transmitQueue is empty or not
;								and if system needs to be kickstarted later 
; 					transmitQueue - holds values to be sent through serial channel 
; Global Variables:	None.
; 
; Input:            None.
; Output:           None.
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  transmitQueue - holds values to be sent through serial channel 

SerialPutChar		PROC 	NEAR 
					PUBLIC 	SerialPutChar 

StartSerialPutChar: 
	PUSHA							; save registers 
	MOV     CL, AL                  ; save AL's value (character arg value) 
    
CheckTransmitQueueFull: 
	MOV 	SI, OFFSET(transmitQueue)	; move transmit queue address into SI 
	CALL 	QueueFull					; and check if transmit queue is full 
	
	JZ 		TransmitQueueIsFull			; if full, we can't add another character
	JNZ 	TransmitQueueNotFull		; if not, go ahead!
	
TransmitQueueIsFull: 		; can't add character to transmit queue 
	STC 						; set carry flag, nothing was added to transmitQueue
	JMP 	EndSerialPutChar	; end function 

TransmitQueueNotFull: 		; if we can add character to transmit queue (not full)
	CMP 	kickstart, IS_SET 		; see if kickstart flag is set 
	JE 		KickstartSerialChannel	; if it is, kickstart the serial channel 
	JNE 	EnqueueCharToTransmitQueue 	; if not, just enqueue character 

KickstartSerialChannel: 	; if we are kickstarting serial channel: 
	MOV 	kickstart, NOT_SET 		; reset kickstart flag 
	CLC 							; clear carry flag 
	
	MOV 	DX, IER_LOC				; disable transmitter empty interrupt,
	IN 		AL, DX
	AND 	AL, DISABLE_THRE_MASK	; preserves all bits except the one corresponding
									; to transmitter holding register empty interrupt
	OUT 	DX, AL 				
									; enable transmitter empty interrupts 
	OR 		AL, ENABLE_THRE_MASK 	; preserves all bits, sets THRE bit to enable 
	OUT 	DX, AL 					; change the IER register 
	
	; JMP 	EnqueueCharToTransmitQueue

EnqueueCharToTransmitQueue: 	; whether or not we need to kickstart, we enqueue
								; char to transmit queue! 
	
	MOV 	SI, OFFSET(transmitQueue)	; get queue we would like to enqueue to 											
                                                
    MOV     AL, CL                  ; restore AL with the value of char argument
    
	CALL 	Enqueue 				; enqueue char to transmit queue 
	
EndSerialPutChar: 
	POPA 						; restore registers 
	RET 
SerialPutChar	ENDP 
	

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
	MOV 	DX, IIR_LOC 		; read in value of interrupt identifying register
	MOV     AX, 0000H           
	IN 		AL, DX 				
	
	AND		AL, IIR_EVENT_MASK 	; get just the lowest 3 bits (corresponding to the 
								; errors and interrupt pending status)
	
InterruptsPending: 
	
    TEST 	AL, 00000001B		; test lowest bit to see if interrupts are pending 
									; if lowest bit is 1, no interrupts are pending:
	JNZ 	EndSerialEventHandler		; exit--no interrupts to take care of 
									; if lowest bit is 0, interrupts are pending:
	JZ	 	GetInterruptEvent			; identify/process specific interrupt event
										
	
GetInterruptEvent: 				; identify what interrupt has been raised 
	
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
	
    JMP     ReadIIRValue 		; read IIR value again to see if another interrupt 
								; has occurred 
		
EndSerialEventHandler:
	POPA						; restore registers 
	RET 						
SerialEventHandler 		ENDP 



;
;
; SetBaudRate 
;
;
; Description:  	This function sets the baud rate to a value found in the baud
; 					rate table, specified by the index argument BX. This function 
; 					outputs	the desired baud rate's corresponding divisor to the 
; 					divisor latch locations. 
; 
; Operation:    	Outputs a set baud rate to the divisor latch address. Using the
; 					passed in argument BX, this function uses the baud rate divisor
; 					value at the index BX in the Baud_Rate_Table to set the baud 
; 					rate. Since some baud rate divisors will take more than 8 bits
; 					to store, the secondary address might also be storing bits that
; 					represent the baud rate divisor. 
; 
; 					Before setting the baud rate, the DLAB bit in the LCR must be 
; 					set in order to access the DLL and DLM. After setting the baud 
; 					rate, the LCR will be set back to its original value, with the 
; 					DLAB bit reset. 
; 
; Arguments:        BX - index of desired baud divisor (according to Baud_Rate_Table)
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
SetBaudRate 		PROC 	NEAR 
					PUBLIC 	SetBaudRate

StartSetBaudRate: 							
	CLI 					; disable interrupts 
	PUSHA 					; save registers and flags 
	PUSHF 
	
SetLCRDLABBit: 
 
	MOV 	DX, LCR_LOC
	MOV 	AX, 0000H				
	IN 		AL, DX 					; read line control register value 
	OR 		AL, SET_DLAB_MASK		; preserve all bits, set dlab=1 
	OUT 	DX, AL 					; write value to LCR 
	MOV 	CL, AL 					; save register value (for later dlab reset)
	
PortChosenBaudRate: 		; set chosen baud rate here 
	MOV 	AX, 0000H 				; clear register again 
	MOV 	DX, DLL_LOC 			; get divisor latch register ready 
	MOV 	AX, CS:Baud_Rate_Table[BX]	; get desired index (passed through BX)
	OUT 	DX, AL 					; write lower byte to lower register 
	
    MOV     DX, DLM_LOC 			; write higher byte to higher register (DLM)
    MOV     AL, AH 
    OUT     DX, AL 

ReturnToDefaultLCRValue:	; reset dlab bit, done changing baud rate 

	MOV 	AL, CL 			;  restore register value 
	AND 	AL, RESET_DLAB_MASK ; preserve all bits, set dlab = 0 
	MOV 	DX, LCR_LOC 		
	OUT 	DX, AL 			; write updated LCR value to LCR 
    
EndSetBaudRate: 
    POPF 
	POPA 					; restore registers and flags 
    STI 					; enable interrupts again 
	RET 
SetBaudRate		ENDP 

; 
;
; SetParity  
; 
;
; Description:  	This function sets the parity to a value found in the parity 
; 					table, specified by the index argument BX. This function 
; 					outputs	the parity to the parity address where it will be 'set'.
; 
; Operation:    	Outputs a set parity value to the parity address. Using the 
; 					passed in argument BX, this function uses the parity value at 
; 					the index BX in the Parity_Table to set the parity value. It 
; 					ANDs the specified parity value with the current value of the 
; 					line control register. 
; 
; Arguments:        BX - index of desired parity value (according to Parity_Table)
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

SetParity 		PROC 	NEAR 
				PUBLIC 	SetParity
				
StartSetParity: 
	CLI 					; disable interrupts                                    
	PUSHA 					; save registers 
    PUSHF 

PortChosenParity: 
	MOV 	DX, LCR_LOC 				; move current LCR value into AL 
    IN      AL, DX                      
	
	AND     AL, CLEAR_PARITY_MASK       ; clear bits 3, 4, and 5 (set parity bits)
										; of the LCR value 
    
    MOV 	CL, CS:Parity_Table[BX]		; look up specified parity value 
        
    OR      AL, CL                      ; ORing the processed LCR value and the 
										; desired parity bits preserves previously 
										; set LCR value and updates the parity bits
	
	OUT 	DX, AL						; send updated LCR value to LCR
	
EndSetParity: 
	STI 					; enable interrupts again 
    POPF
	POPA 					; restore registers and flags 
	RET 
SetParity 		ENDP 

;
;
;
; ModemStatus 
;
;
; Description:  	This function reads from the modem register, clearing the modem
; 					status error interrupt. However, when modem status interrupts 
;	 				are disabled, this function will not be called since modem 
; 					status interrupts will not be raised. 
;
; Operation:    	This function reads from the modem register to clear interrupt. 
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
	PUSHA 					; save registers 
	
ReadModemStatusRegister:
	MOV     AX, 0000H       ; clear register 
	MOV 	DX, MSR_LOC
	IN 		AL, DX			; read the interrupt to clear it 
	
EndModemStatusEvent:
	POPA					; restore registers 
	RET 
ModemStatus		ENDP 

;
;
;
; LineStatus
;
;
; Description:  	This function is called if there is a line status error. 
; 					The possible errors are an overrun error, parity error, 
; 					or framing error. 
;
; Operation:    	If there is a line status error, then enqueue the error value
; 					to the event queue. There are 3 possible errors: overrun error,
; 					parity error, or framing error. These errors are defined by bits
; 					1, 2, and 3, so before enqueuing a line status error event, we 
; 					mask out the irrelevant bits to get the specific value of the 
; 					line status error. 
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
				PUBLIC 	LineStatus

StartLineStatusEvent: 
	PUSHA 						; save registers 

ReadLSRValue:
	MOV     AX, 0000H           ; clear register 
	MOV 	DX, LSR_LOC			; read line status register value 
	IN 		AL, DX 				; value of error will be in bits 1, 2, 3 
	
GetRelevantLSRBits: 			; here we perform masking to get relevant value
	AND 	AL, LSR_ERROR_MASK	; LSR_ERROR_MASK sets all but bits 1-3 to 0. 
	
EnqueueLSREvent:
	MOV 	AH, LINE_STATUS_EVENT	; store line status error event identifier value
	
	CALL    EnqueueEvent 		; enqueue line status error 

EndLineStatusEvent:
	POPA						; restore registers 
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
; 					flag since the transmit queue is empty. If the transmit queue 
; 					has stuff in it, then we move one value to the transmitter 
; 					holding register, where it will be output through the serial 
; 					channel. 
; 
; Operation:    	First we check if the transmit queue is empty. If it is, we just
; 					set the kickstart flag, which tells us the transmit queue is 
; 					empty. If it's not empty, we use the OUT command to put the 
; 					queue's head value into the transmit holding register. 
; 
; Arguments:        None. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: transmitQueue - holds values to be output through serial channel
; Global Variables:	None.
; 
; Input:            None.
; Output:           A byte to the THR.
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  transmitQueue - holds values to be output through serial channel
; 					

	
TransmitterEmpty 		PROC 	NEAR 
						PUBLIC 	TransmitterEmpty
	
StartTransmitterEmptyEvent:
	PUSHA									; save registers 
	
CheckTransmitQueueNotEmpty: 			; check if the transmit queue is empty
	MOV 	SI, OFFSET(transmitQueue)			; store address of queue in SI 
	CALL 	QueueEmpty 							
	
	JZ 		THREmptyAndTransmitQueueEmpty		; when empty, ZF is set. Thus THR
												; is empty, so is transmit queue.
	JNZ 	THREmptyAndTransmitQueueNotEmpty	; when not empty, ZF = 0. Thus THR
												; is empty, transmit queue is not.
	
THREmptyAndTransmitQueueEmpty: 			; When transmit queue is empty: 
										; Can't send any values to THR, so end. 
	MOV 	kickstart, IS_SET 				; set kickstart flag,
	JMP 	EndTransmitterEmptyHandler		; and end function (nothing to send to 
											; THR)
	
THREmptyAndTransmitQueueNotEmpty: 		; When transmit queue not empty: 
										; Send a value to THR to output.
	MOV 	SI, OFFSET(transmitQueue)		
	CALL 	Dequeue 						; dequeue value from transmit queue
											; the value dequeued is in AL
										
	MOV 	DX, THR_LOC 					; output dequeued value to THR 
	OUT 	DX, AL 
	; JMP 	EndTransmitterEmptyHandler
					
EndTransmitterEmptyHandler:
	POPA								; restore registers 
	RET 
TransmitterEmpty		ENDP 
	
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
	PUSHA 							; save registers 
	MOV     AX, 0000H           	; clear AX register 
	
ReadReceiverBufferRegister: 	; read the RBR value for received data
	MOV 	DX, RBR_LOC				
	IN 		AL, DX					; read receiver buffer register 

EnqueueReceivedData: 			; then enqueue data received event 
	MOV 	AH, DATA_AVAIL_EVENT	; get event identifier value into AH 
	CALL 	EnqueueEvent			
				
EndDataAvailableEvent:
	POPA							; restore registers 
	RET 
DataAvailable		ENDP 	


; Tables 

	; This is the baud rate table, defining the different baud rates available 
	; for this serial channel. Each value in the table is the divisor, 
	; corresponding to the real baud rate listed to the right of it. 
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
	
	
	; This is the parity table, defining the parity bits for each possible parity
	; type. Only bits 3, 4, and 5 are relevant for setting the parity, so the other
	; bits are set to 0. This table is used in the SetParity function. 
Parity_Table 		LABEL 	BYTE
					PUBLIC 	Parity_Table
	
	DB 		00000000B		; none parity 
	DB 		00001000B		; odd parity 
	DB 		00011000B		; even parity 
	DB 		00111000B		; stick parity 
	DB 		00101000B		; clear parity 
	

	; this is the CALL table that we will use to direct the serial event handler 
	; to the right procedure to perform, based on the interrupts identified in 
	; the IIR. 
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
	; this keeps track of whether or not our queue is empty 
	; and this determines whether or not we have to kickstart channel 

    transmitQueue		qStruc      < >    
	; queue that holds values waiting to be output through the serial port
	; of the structure type qStruc, defined in queue.inc 
DATA 	ENDS

END