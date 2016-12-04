

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 INTRPVEC.INC                               ;
;                                 Include File                               ;
;                        Interrupt Vector Setup Constants                    ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Interrupt Controller Definitions

; Addresses
INTCtrlrEOI     EQU     0FF22H          ;address of interrupt controller EOI register

NonSpecEOI      EQU     08000H          ;Non-specific EOI command


; General Definitions

FIRST_RESERVED_VEC      EQU     1       ;reserve vectors 1-3
LAST_RESERVED_VEC       EQU     3
NUM_IRQ_VECTORS         EQU     256     ;number of interrupt vectors
