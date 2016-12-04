

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
	
	LSR_ERROR_MASK 		EQU 	00001110B 	; mask that isolates the errors in the line 
											; status register 
	LSR_OVERRUN_MASK	EQU 	00000010B 	; isolates the overrun error in LSR
	LSR_PARITY_MASK 	EQU 	00000100B 	; isolates the parity error in LSR
	LSR_FRAMING_MASK	EQU 	00001000B 	; isolates the framing error in LSR 
	
	CLEAR_PARITY_MASK   EQU     11000111B   ; mask that isolates the parity bits, 
											; ANDing with LCR will clear parity bits
    LCR_SET_DLAB_MASK	EQU 	10000000B 	; mask sets dlab bit, preserves other bits

	; event type values to be enqueued to EventQueue 
	
	DATA_AVAIL_EVENT	EQU 	0004H		; data is received event value 
	LINE_STATUS_EVENT	EQU 	0000H		; LSR events count as error events 			
	
; default serial channel settings index values 

	DEFAULT_PARITY_INDEX	EQU 	2 		; will select even parity as default
	DEFAULT_BAUD_INDEX		EQU 	18		; will select 9600 as default baud rate
	
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
											; ---1----  select even parity 
											; ----1---  enable parity select
											; -----1--  select number of stop bits 
											; ------11  set word size to 8 bits 
											
	