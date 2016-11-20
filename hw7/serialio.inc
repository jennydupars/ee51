

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 SERIALIO.INC                               ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    TX_QUEUE_SIZE 		EQU 	0100H 		; what hsould i set this to? 	//////////////////////////////////////////////
	SELECT_BYTE_SIZE	EQU 	0000H 		; size of elements populating transmit queue 
	IIR_EVENT_MASK		EQU 	00000111B 	; mask that isolates the interrupt ID bits
	LSR_ERROR_MASK 		EQU 	00001110B 	; mask that isolates the errors in the line status register 
	CLEAR_PARITY_MASK   EQU     11000111B   ; mask that isolates the parity bits, ANDing this with LCR will clear the parity bits 
    
; event type values to be enqueued to EventQueue 
	
	DATA_AVAIL_EVENT	EQU 	00A0H		; Event value to be enqueued when data is received	
	LINE_STATUS_EVENT	EQU 	00B0H				
	
; default serial channel settings index values 
	DEFAULT_PARITY_INDEX	EQU 	1 		; will select odd parity 
	DEFAULT_BAUD_INDEX		EQU 	14		; will select 9600 as baud rate 
	
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
											
	IER_VAL_NO_THR_INT 	EQU 	00001101B 	; value to be written to interrupt enable register (THR interrupts disabled)
											; 0000----  unused 
											; ----0--- 	disable modem status interrupt 
											; -----1--  enable receiver line status interrupt
											; ------0-  disable transmitter holding register empty interrupt 
											; -------1  enable received data available interrupt 
											
	LCR_VAL 			EQU 	00011111B 	; default value of LCR port (DLAB not set)
											; 0------- 	divisor latch access bit not set 
											; -0------  break control bit not set 
											; --0-----  stick parity not set 
											; ---1----  select even parity ///////////////////////////////////////////// wat is this 
											; ----1---  enable parity select
											; -----1--  select number of stop bits 
											; ------11  set word size to 8 bits 
											
	LCR_VAL_DLAB 		EQU 	10011111B	; value of LCR port (DLAB set)
											; 1-------  divisor latch access bit set 
											; -0------  break control bit not set 
											; --0-----  stick parity not set 
											; ---1----  select even parity ///////////////////////////////////////////// wat is this 
											; ----1---  enable parity select
											; -----1--  select number of stop bits 
											; ------11  set word size to 8 bits 
	

	
	