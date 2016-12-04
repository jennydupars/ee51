

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 SERIALIO.INC                               ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; transmit queue definitions

    TX_QUEUE_SIZE 		EQU 	0100H 		; size of transmit queue 
	SELECT_BYTE_SIZE	EQU 	0000H 		; indicates size of elements populating
											; transmit queue will be a byte 
	
; register masks 

	IIR_EVENT_MASK		EQU 	00000111B 	; mask that isolates interrupt ID bits
    
	LSR_ERROR_MASK 		EQU 	00001110B 	; mask that isolates errors in the 
											; line status register 
	CLEAR_PARITY_MASK   EQU     11000111B   ; mask that isolates parity bits, ANDing
											; this with LCR will clear parity bits
	SET_DLAB_MASK		EQU 	10000000B 	; mask that turns on the dlab bit. 
	RESET_DLAB_MASK 	EQU 	01111111B 	; mask that turns off the dlab bit.
	
	DISABLE_THRE_MASK 	EQU 	11111101B 	; mask that disables THRE interrupts 
	ENABLE_THRE_MASK 	EQU 	00000010B 	; mask that enables transmitter holding 
											; register empty interrupts 
    
; event types to be enqueued to EventQueue 
	
	DATA_AVAIL_EVENT	EQU 	00A0H		; Event value enqueued when data received	
	LINE_STATUS_EVENT	EQU 	00B0H		; Event value enqueued when LSR error 
	
	
; default serial channel settings index values 

	DEFAULT_PARITY_INDEX	EQU 	2 		; will select even parity 
	DEFAULT_BAUD_INDEX		EQU 	14		; will select 9600 as baud rate 
	
	
; port locations 
	ACEBASE			EQU 	0100H    ; base address for serial port control registers
	
	RBR_LOC 		EQU 	ACEBASE + 00H 	; receiver buffer register (dlab=0)
	THR_LOC 		EQU 	ACEBASE + 00H 	; transmitter holding register (dlab=0)
	IER_LOC			EQU 	ACEBASE + 01H 	; Interrupt enable register 
	IIR_LOC 		EQU 	ACEBASE + 02H 	; Interrupt identity register 
	LCR_LOC 		EQU 	ACEBASE + 03H 	; Line control register
	MCR_LOC			EQU 	ACEBASE + 04H 	; Modem control register 
	LSR_LOC			EQU 	ACEBASE + 05H 	; Line status register 
	MSR_LOC			EQU 	ACEBASE + 06H 	; Modem status register 
	SCR_LOC			EQU 	ACEBASE + 07H 	; Scratch register 
	DLL_LOC			EQU 	ACEBASE + 00H 	; Divisor latch register (dlab = 1)
	DLM_LOC			EQU		ACEBASE + 01H 	; Latch register (dlab = 1)
				
	
; port values 
	IER_VAL 			EQU 	00001111B 	; value to interrupt enable register 
							  ; 0000----  unused 
				   			  ; ----0---  disable modem status interrupt 
							  ; -----1--  enable receiver line status interrupt
							  ; ------1-  enable THR empty interrupt
							  ; -------1  enable received data available interrupt 
											
	LCR_VAL 			EQU 	00011111B ; default value of LCR port (DLAB not set)
							  ; 0-------  divisor latch access bit not set 
							  ; -0------  break control bit not set 
							  ; --0-----  stick parity not set 
							  ; ---1----  select even parity 
							  ; ----1---  enable parity select
							  ; -----1--  select number of stop bits 
							  ; ------11  set word size to 8 bits 
											