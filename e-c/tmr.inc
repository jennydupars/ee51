;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   TMR.INC                                  ;
;                            80188 Timer Definitions                         ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the 80188 Timer control unit. It contains 
; bits for the control registers, addresses of all the registers, and interrupt 
; vectors. 
;
;
; Revision History:
;    11/01/16  Jennifer Du       initial revision
;

; Addresses 

T0CNT       EQU     PeriphBase + 050H 			; timer 0 count register 
T0CMPA      EQU     PeriphBase + 052H 			; timer 0 compare A value 
T0CMPB      EQU     PeriphBase + 054H 			; timer 0 compare B value 
T0CON       EQU     PeriphBase + 056H 			; timer 0 control register 

T1CNT       EQU     PeriphBase + 058H 			; timer 1 count register 
T1CMPA      EQU     PeriphBase + 05AH 			; timer 1 compare A register 
T1CMPB      EQU     PeriphBase + 05CH 			; timer 1 compare B register 
T1CON       EQU     PeriphBase + 05EH			; timer 1 control register 

T2CNT       EQU     PeriphBase + 060H 			; timer 2 count register 
T2CMPA      EQU     PeriphBase + 062H 			; timer 2 compare register 
T2CON       EQU     PeriphBase + 066H			; timer 2 control register 
 

; Interrupt Vectors
Tmr0Vec     EQU     8               ; interrupt vector for Timer 0
Tmr1Vec 	EQU 	18				; interrupt vector for Timer 1 
Tmr2Vec		EQU		19				; interrupt vector for Timer 2



; Timer 0 control register

T0CON_EN    EQU     1000000000000000B   ; enable timer 
T0CON_INH   EQU     0100000000000000B   ; set to enable writes to EN bit, clear to ignore writes 
T0CON_INT   EQU     0010000000000000B   ; set to generate interrupt request when max count is reached 
T0CON_RIU   EQU     0001000000000000B   ; 1 = maxcount CMP B register in use, 0 = maxcount CMP A register 

T0CON_MC    EQU     0000000000100000B   ; set when counter reaches max count 
T0CON_RTG   EQU     0000000000010000B   ; 1 = reset count, 0 = enable counter 
T0CON_P     EQU     0000000000001000B   ; 1 = increment timer when timer 2 reaches maxcount, 0 = increment timer at 1/4 clkout (ignored if ext=1)
T0CON_EXT   EQU     0000000000000100B   ; 1 = use extenal clock, 0 = use internal 
T0CON_ALT   EQU     0000000000000010B   ; 1 = specify dual maxcount mode, 0 = specify single maxcount mode 
T0CON_CONT  EQU     0000000000000001B   ; 1 = continuous running, 0 = display counter after each counting sequence 


; Timer 1 control register 

T1CON_EN    EQU     1000000000000000B   ; enable timer 
T1CON_INH   EQU     0100000000000000B   ; set to enable writes to EN bit, clear to ignore writes 
T1CON_INT   EQU     0010000000000000B   ; set to generate interrupt request when max count is reached 
T1CON_RIU   EQU     0001000000000000B   ; 1 = maxcount CMP B register in use, 0 = maxcount CMP A register 

T1CON_MC    EQU     0000000000100000B   ; set when counter reaches max count 
T1CON_RTG   EQU     0000000000010000B   ; 1 = reset count, 0 = enable counter 
T1CON_P     EQU     0000000000001000B   ; 1 = increment timer when timer 2 reaches maxcount, 0 = increment timer at 1/4 clkout (ignored if ext=1)
T1CON_EXT   EQU     0000000000000100B   ; 1 = use extenal clock, 0 = use internal 
T1CON_ALT   EQU     0000000000000010B   ; 1 = specify dual maxcount mode, 0 = specify single maxcount mode 
T1CON_CONT  EQU     0000000000000001B   ; 1 = continuous running, 0 = display counter after each counting sequence 


; Timer 2 control register 

T2CON_EN    EQU     1000000000000000B   ; enable timer 
T2CON_INH   EQU     0100000000000000B   ; set to enable writes to EN bit, clear to ignore writes 
T2CON_INT   EQU     0010000000000000B   ; set to generate interrupt request when max count is reached 

T2CON_MC    EQU     0000000000100000B   ; set when counter reaches max count 

T2CON_CONT  EQU     0000000000000001B   ; 1 = continuous running, 0 = display counter after each counting sequence 


; Timer Count Registers (we do not set these ourselves) 

T0CNT       EQU     0000000000000000B   ; contains current timer count for timer 0
T1CNT       EQU     0000000000000000B   ; contains current timer count for timer 1
T2CNT       EQU     0000000000000000B   ; contains current timer count for timer 2


; Timer MaxCount Compare Registers 

T0CMPA      EQU     0000000000000000B   ; contains max timer count value for Timer 0
T0CMPB      EQU     0000000000000000B   ; contains max timer count value for Timer 0

T1CMPA      EQU     0000000000000000B   ; contains max timer count value for Timer 1
T1CMPB      EQU     0000000000000000B   ; contains max timer count value for Timer 1

T2CMPA      EQU     0000000000000000B   ; contains max timer count value for Timer 2


