

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 INITPP.INC                                 ; 
;                           Initialize Parallel Ports                        ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ParallelPortCtrlReg  EQU  0183H
ParallelPortVal      EQU  10000000B  ; control word for chip
                                     ; 0------- mode set inactive 
                                     ; -0000--- group A settings (port A and upper port C)
                                     ; -----0-- set mode 0 
                                     ; ------0- Port B: set as output 
                                     ; -------0 port C lower (irrelevant for us) 