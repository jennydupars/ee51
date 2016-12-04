

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   INT2.INC                                 ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; INT2 Interrupt Definitions 

; Interrupt Vectors
INT2Vec         EQU     14               ;interrupt vector for INT2 interrupts 


; Interrupt Controller Definitions

; Addresses
INT2CtrlrCtrl   EQU     0FF3CH          ;address of interrupt controller for INT2 

; Register Values
INT2CtrlrCVal    EQU     00001H         ;set priority for INT2 to 1, set to 
                                        ; edge-triggering, and enable  
                                        ;00000000000-----  reserved
                                        ;-----------0----  set to edge triggering 
                                        ;------------0---  enable INT2 interrupt
                                        ;-------------001  INT2 priority                    
                                        
INT2EOI         EQU     0000EH          ;INT2 EOI command 
