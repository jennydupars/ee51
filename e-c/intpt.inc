;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  INTPT.INC                                 ;
;                          80188 Interrupt Controller                        ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the 80188 Interrupt control unit. It contains
; register addresses, control and status register bits, and commands like specific 
; EOIs and non-specific EOIs. 
;
;
; Revision History:
;    11/01/16  Jennifer Du       initial revision
;


; Addresses - Master mode 
MI3CON          EQU         PeriphBase + 03EH      	; INT3 interrupt control reg 
MI2CON          EQU         PeriphBase + 03CH      	; INT2 interrupt control reg 
MI1CON          EQU         PeriphBase + 03AH      	; INT1 interrupt control reg 
MI0CON          EQU         PeriphBase + 038H      	; INT0 interrupt control reg 
MDMA1CON        EQU         PeriphBase + 036H      	; DMA1 interrupt control reg 
MDMA0CON        EQU         PeriphBase + 034H      	; DMA0 interrupt control reg 
MTCUCON         EQU         PeriphBase + 032H      	; Timer control unit interrupt control reg
MINTSTS         EQU         PeriphBase + 030H	   	; Interrupt status register 
MREQST          EQU         PeriphBase + 02EH		; Interrupt request register 
MINSERV         EQU         PeriphBase + 02CH		; Interrupt in-service register 
MPRIMSK         EQU         PeriphBase + 02AH		; Priority mask for registers 
MIMASK          EQU         PeriphBase + 028H		; Interrupt mask register 
MPOLLSTS        EQU         PeriphBase + 026H		; Poll status register 
MPOLL           EQU         PeriphBase + 024H		; Poll register 
MEOI            EQU         PeriphBase + 022H		; End of Interrupt register 

; Addresses - Slave mode 
ST2CON          EQU         PeriphBase + 03AH		; Timer 2 control register 
ST1CON          EQU         PeriphBase + 038H		; Timer 1 control register 
SDMA1CON        EQU         PeriphBase + 036H		; DMA1 control register 
SDMA0CON        EQU         PeriphBase + 034H		; DMA0 control register 
STmr0CON        EQU         PeriphBase + 032H		; Timer 0 control register 
SINTSTS         EQU         PeriphBase + 030H		; Interrupt status register 
SREQST          EQU         PeriphBase + 02EH		; Interrupt Request register 
SINSERV         EQU         PeriphBase + 02CH		; Interrupt In-service register 
SPRIMSK         EQU         PeriphBase + 02AH		; Priority Mask register 
SIMASK          EQU         PeriphBase + 028H		; Interrupt mask register 
SEOI            EQU         PeriphBase + 022H		; End of Interrupt register 
INTVEC          EQU         PeriphBase + 020H 		; Interrupt Vector register 

; EOIs 
TimerEOI        EQU     	00008H          ;Timer EOI command (same for all timers)
NonSpecEOI      EQU		    08000H          ;Non-specific EOI command

; Interrupt Vectors 
Tmr0Vec     	EQU     	8               ; interrupt vector for Timer 0
Tmr1Vec 		EQU 		18				; interrupt vector for Timer 1 
Tmr2Vec			EQU			19				; interrupt vector for Timer 2
DMA0Vec 		EQU 		10				; interrupt vectors for each type of interrupt 
DMA1Vec 		EQU 		11 
INT0Vec 		EQU 		12
INT1Vec 		EQU 		13
INT2Vec 		EQU 		14
INT3Vec 		EQU 		15 


; Master Mode Register Values 

; Interrupt Control Registers (internal sources)
; Timer control unit (TCU), DMA0, DMA1 

MTCUCON_MSK     EQU     0000000000001000B       ; disabled interrupts for timer control unit 
MTCUCON_PM2     EQU     0000000000000100B       ; priority bit 2 set (+4 priority)
MTCUCON_PM1     EQU     0000000000000010B       ; priority bit 1 set (+2 priority)
MTCUCON_PM0     EQU     0000000000000001B       ; priority bit 0 set (+1 priority)

MDMA0CON_MSK    EQU     0000000000001000B       ; disabled interrupts for DMA0  
MDMA0CON_PM2    EQU     0000000000000100B       ; priority bit 2 set (+4 priority)
MDMA0CON_PM1    EQU     0000000000000010B       ; priority bit 1 set (+2 priority)
MDMA0CON_PM0    EQU     0000000000000001B       ; priority bit 0 set (+1 priority)

MDMA1CON_MSK    EQU     0000000000001000B       ; disabled interrupts for DMA1  
MDMA1CON_PM2    EQU     0000000000000100B       ; priority bit 2 set (+4 priority)
MDMA1CON_PM1    EQU     0000000000000010B       ; priority bit 1 set (+2 priority)
MDMA1CON_PM0    EQU     0000000000000001B       ; priority bit 0 set (+1 priority)

; Interrupt Control Registers (non-cascadable pins) 
; INT2, INT3 

MI2CON_LVL      EQU     0000000000010000B       ; set to select level interrupt triggering mode
MI2CON_MSK      EQU     0000000000001000B       ; disable INT2 interrupts   
MI2CON_PM2      EQU     0000000000000100B       ; priority bit 2 set (+4 priority)
MI2CON_PM1      EQU     0000000000000010B       ; priority bit 1 set (+2 priority)
MI2CON_PM0      EQU     0000000000000001B       ; priority bit 0 set (+1 priority)

MI3CON_LVL      EQU     0000000000010000B       ; set to select level interrupt triggering mode
MI3CON_MSK      EQU     0000000000001000B       ; disabled INT3 interrupts   
MI3CON_PM2      EQU     0000000000000100B       ; priority bit 2 set (+4 priority)
MI3CON_PM1      EQU     0000000000000010B       ; priority bit 1 set (+2 priority)
MI3CON_PM0      EQU     0000000000000001B       ; priority bit 0 set (+1 priority)

; Interrupt Control Register (cascadable pins)
; INT1, INT0 

MI1CON_SFNM     EQU     0000000001000000B       ; set to enable special fully nested mode 
MI1CON_CAS      EQU     0000000000100000B       ; set to enable cascade mode 
MI1CON_LVL      EQU     0000000000010000B       ; set to select level interrupt triggering mode
MI1CON_MSK      EQU     0000000000001000B       ; disable INT2 interrupts   
MI1CON_PM2      EQU     0000000000000100B       ; priority bit 2 set (+4 priority)
MI1CON_PM1      EQU     0000000000000010B       ; priority bit 1 set (+2 priority)
MI1CON_PM0      EQU     0000000000000001B       ; priority bit 0 set (+1 priority)

MI0CON_SFNM     EQU     0000000001000000B       ; set to enable special fully nested mode 
MI0CON_CAS      EQU     0000000000100000B       ; set to enable cascade mode 
MI0CON_LVL      EQU     0000000000010000B       ; set to select level interrupt triggering mode
MI0CON_MSK      EQU     0000000000001000B       ; disabled INT3 interrupts   
MI0CON_PM2      EQU     0000000000000100B       ; priority bit 2 set (+4 priority)
MI0CON_PM1      EQU     0000000000000010B       ; priority bit 1 set (+2 priority)
MI0CON_PM0      EQU     0000000000000001B       ; priority bit 0 set (+1 priority)


; Interrupt Request Register (Master Mode)
; Stores pending interrupt requests, bits are set for corresponding interrupt requests 

REQST_INT3      EQU     0000000010000000B
REQST_INT2      EQU     0000000001000000B
REQST_INT1      EQU     0000000000100000B
REQST_INT0      EQU     0000000000010000B

REQST_DMA1      EQU     0000000000001000B
REQST_DMA0      EQU     0000000000000100B

REQST_TMR       EQU     0000000000000001B 



; Master Mode Interrupt Mask Register
; Masks Individual interrupt sources, bits are set for interrupts to be ignored 

MIMASK_INT3     EQU     0000000010000000B
MIMASK_INT2     EQU     0000000001000000B
MIMASK_INT1     EQU     0000000000100000B
MIMASK_INT0     EQU     0000000000010000B

MIMASK_DMA1     EQU     0000000000001000B
MIMASK_DMA0     EQU     0000000000000100B

MIMASK_TMR      EQU     0000000000000001B



; Priority Mask Register 
; For masking lower priority interrupt sources (takes on any value between 0 and 7)
; Bits are set to value at which all lower priority interrupts should be ignored 
PRIMSK0   		EQU     0000000000000000B
PRIMSK1   		EQU     0000000000000001B
PRIMSK2   		EQU     0000000000000010B
PRIMSK4   		EQU     0000000000000100B


; In-service register (Master Mode)
; tells us which interrupt handlers are in progress
; Bit is set for whichever interrupts are being handled currently 

MINSERV_INT3    EQU     0000000010000000B 
MINSERV_INT2    EQU     0000000001000000B
MINSERV_INT1    EQU     0000000000100000B
MINSERV_INT0    EQU     0000000000010000B

MINSERV_DMA1    EQU     0000000000001000B
MINSERV_DMA1    EQU     0000000000000100B

MINSERV_TMR     EQU     0000000000000001B



; Poll register 
POLL_IREQ    	EQU     1000000000000000B       ; set to indicate pending interrupt

POLL_VT4  	    EQU     0000000000010000B       ; 4th bit set for interrupt type
POLL_VT3     	EQU     0000000000001000B       ; 3th bit set for interrupt type
POLL_VT2     	EQU     0000000000000100B       ; 2th bit set for interrupt type
POLL_VT1     	EQU     0000000000000010B       ; 1th bit set for interrupt type
POLL_VT0     	EQU     0000000000000001B       ; 0th bit set for interrupt type


; Poll Status Register 
POLLSTS_IREQ    EQU     1000000000000000B       ; set to indicate pending interrupt

POLLSTS_VT4     EQU     0000000000010000B       ; 4th bit set for interrupt type
POLLSTS_VT3     EQU     0000000000001000B       ; 3th bit set for interrupt type
POLLSTS_VT2     EQU     0000000000000100B       ; 2th bit set for interrupt type
POLLSTS_VT1     EQU     0000000000000010B       ; 1th bit set for interrupt type
POLLSTS_VT0     EQU     0000000000000001B       ; 0th bit set for interrupt type


; Master Mode EOI Register 
MEOI_NSPEC    	EQU     1000000000000000B       ; set to issue nonspecific EOI 

MEOI_VT4      	EQU     0000000000010000B       ; 4th bit set for interrupt type
MEOI_VT3      	EQU     0000000000001000B       ; 3th bit set for interrupt type
MEOI_VT2      	EQU     0000000000000100B       ; 2th bit set for interrupt type
MEOI_VT1      	EQU     0000000000000010B       ; 1th bit set for interrupt type
MEOI_VT0      	EQU     0000000000000001B       ; 0th bit set for interrupt type


; Interrupt Status Register 
INTSTS_DHLT  	EQU     1000000000000000B       ; suspend DMA activity 

INTSTS_TMR2     EQU     0000000000000100B       ; pending interrupt from tmr 2
INTSTS_TMR1     EQU     0000000000000010B       ; pending interrupt from tmr 1
INTSTS_TMR0     EQU     0000000000000001B       ; pending interrupt from tmr 0



; Slave Mode Register Values 

; Slave Mode Interrupt Vector Register 
SINTVEC_VT4      EQU     0000000000010000B		; Bits correspond to 5 most significant
SINTVEC_VT3      EQU     0000000000001000B			; bits of interrupt type for 
SINTVEC_VT2      EQU     0000000000000100B			; internal interrupts 
SINTVEC_VT1      EQU     0000000000000010B
SINTVEC_VT0      EQU     0000000000000001B


; Slave Mode EOI Register 						
; stores value of interrupt to be ended 

SEOI_TMR0		EQU 	0000000000000000B 		; for sending EOI to the different 
SEOI_TMR1		EQU 	0000000000000100B 			; possible interrrupts 
SEOI_TMR2		EQU 	0000000000000101B 
SEOI_DMA0		EQU 	0000000000000010B 
SEOI_DMA1		EQU 	0000000000000011B 


; Slave Mode Interrupt Request Register
; Bits are set for whichever interrupts are being requested 

SREQST_TMR2     EQU     0000000000100000B
SREQST_TMR1     EQU     0000000000010000B

SREQST_DMA0     EQU     0000000000001000B
SREQST_DMA1     EQU     0000000000000100B

SREQST_TMR0     EQU     0000000000000001B 

; Slave Mode In-Service Register 
; Bits are set for whichever interrupts are currently being handled 

SINSERV_TMR2     EQU     0000000000100000B
SINSERV_TMR1     EQU     0000000000010000B

SINSERV_DMA0     EQU     0000000000001000B
SINSERV_DMA1     EQU     0000000000000100B

SINSERV_TMR0     EQU     0000000000000001B 

; Slave Mode Interrupt Mask 
; Bits are set for whichever interrupts are meant to be ignored 

SIMASK_TMR2      EQU     0000000000100000B
SIMASK_TMR1      EQU     0000000000010000B 

SIMASK_DMA0      EQU     0000000000001000B
SIMASK_DMA1      EQU     0000000000000100B

SIMASK_TMR0      EQU     0000000000000001B 


