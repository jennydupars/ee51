

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 INITPP.INC                                 ; 
;                           Initialize Parallel Ports                        ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ParallelPortCtrlReg  EQU  0183H		 ; parallel port control register 
ParallelPortVal      EQU  10000000B  ; control word for chip
                                     ; 1------- mode set active 
                                     ; -0000--- group A settings (port A and upper port C)
                                     ; -----0-- set mode 0 
                                     ; ------0- Port B: set as output 
                                     ; -------0 port C lower (irrelevant for us) 