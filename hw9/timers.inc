

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 TIMERS.INC                                 ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Timer Definitions

; Addresses
Tmr0Ctrl        EQU     0FF56H          ;address of Timer 0 Control Register
Tmr0MaxCntA     EQU     0FF52H          ;address of Timer 0 Max Count A Register
Tmr0Count       EQU     0FF50H          ;address of Timer 0 Count Register

; Control Register Values
Tmr0CtrlVal     EQU     0E001H          ;value to write to Timer 0 Control Register
                                        ;1---------------  enable timer
                                        ;-1--------------  write to control
                                        ;--1-------------  enable interrupts
                                        ;----000000------  reserved
                                        ;---0------0-----  read only
                                        ;-----------0----  TMRIN0 is an enable
                                        ;------------00--  count timer 2 outs
                                        ;--------------0-  single counter mode
                                        ;---------------1  continuous mode


; Interrupt Vectors
Tmr0Vec         EQU     8               ;interrupt vector for Timer 0


; Interrupt Controller Definitions

; Addresses
INTCtrlrCtrl    EQU     0FF32H          ;address of interrupt controller for timer

; Register Values
TmrINTCtrlrCVal    EQU     00001H       ;set priority for timers to 1 and enable
                                        ;000000000000----  reserved
                                        ;------------0---  enable timer interrupt
                                        ;-------------001  timer priority
TimerEOI        EQU     00008H          ;Timer EOI command (same for all timers)



; Timing Definitions

COUNTS_PER_MS   EQU     2304            ;number of timer counts per 1 ms (assumes 18.432 MHz clock)


