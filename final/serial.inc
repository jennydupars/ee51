

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 SERIALIO.INC                               ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    TX_QUEUE_SIZE 		EQU 	0100H 		; transmit queue length (bytes)
	SELECT_BYTE_SIZE	EQU 	0000H 		; size of elements populating transmit 
											; queue: 0 = byte, 1 = word when passed in
	IIR_EVENT_MASK		EQU 	00000111B 	; mask that isolates the interrupt ID bits
	
	LSR_ERROR_MASK 		EQU 	00011110B 	; mask that isolates the errors in the line 
											; status register 
	IIR_INTPT_PEND_MASK EQU 	00000001B	; mask that isolates lowest bit in the IIR 
											; to see if any interrupts are pending 
    
	CLEAR_PARITY_MASK   EQU     11000111B   ; mask that isolates the parity bits, 
											; ANDing with LCR will clear parity bits
    LCR_SET_DLAB_MASK	EQU 	10000000B 	; mask sets dlab bit, preserves other bits

    IER_NO_THR_INT_MASK EQU     11111101B   ; mask resets THR bit when ANDED with 
                                            ; IER value 
    
	; event type values to be enqueued to EventQueue 
	
	DATA_AVAIL_EVENT	EQU 	0004H		; data is received event value 
	LINE_STATUS_EVENT	EQU 	0000H		; LSR events count as error events 
    TRANSMIT_QUEUE_FULL_ERROR   EQU     0000H ; Tx queue full error has value 08
    ERROR_VAL           EQU     0000H       ; AH event type number for errors 
	
    
; default serial channel settings index values 

	DEFAULT_PARITY_INDEX	EQU 	2 		; will select even parity as default
	DEFAULT_BAUD_INDEX		EQU 	14		; will select 9600 as default baud rate
	
; port locations 
	ACEBASE				EQU 	0100H 		; base address for serial port control registers 
	
	RBR_LOC 			EQU 	ACEBASE + 00H 	; receiver buffer register (when dlab = 0) read-only 
	THR_LOC 			EQU 	ACEBASE + 00H 	; transmitter holding register (when dlab = 0) write-only
	IER_LOC				EQU 	ACEBASE + 01H 	; Interrupt enable register 
	IIR_LOC 			EQU 	ACEBASE + 02H 	; Interrupt identity register 
	LCR_LOC 			EQU 	ACEBASE + 03H 	; Line control register
	MCR_LOC				EQU 	ACEBASE + 04H 	; Modem control register 
	LSR_LOC				EQU 	ACEBASE + 05H 	; Line status register 
	MSR_LOC				EQU 	ACEBASE + 06H 	; Modem status register 
	SCR_LOC				EQU 	ACEBASE + 07H 	; Scratch register 
	DLL_LOC				EQU 	ACEBASE + 00H 	; Divisor latch register (when dlab = 1)
	DLM_LOC				EQU		ACEBASE + 01H 	; Latch register (when dlab = 1)
	
				
	
; port values 
	IER_VAL 			EQU 	00001111B 	; value to be written to interrupt enable register 
											; 0000----  unused 
											; ----0--- 	disable modem status interrupt 
											; -----1--  enable receiver line status interrupt
											; ------1-  enable transmitter holding register empty interrupt 
											; -------1  enable received data available interrupt 
																						
	
	LCR_VAL 			EQU 	00011111B 	; default value of LCR port (DLAB not set)
											; 0------- 	divisor latch access bit not set 
											; -0------  break control bit not set 
											; --0-----  stick parity not set 
											; ---1----  select even parity 
											; ----1---  enable parity select
											; -----1--  select number of stop bits 
											; ------11  set word size to 8 bits 
											
	