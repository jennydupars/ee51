;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 DISPLAY.INC                                ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the symbolic constants for the DISPLAY.ASM and EventHandler.asm 
; programs.
;
; Table of Contents
; 	
;
; Revision History:
;    10/26/2016     Maitreyi Ashok      Added constants for display and event handler


bufferSize      EQU         48      ; number of bytes buffer can store (24 digits)
extraSegOffset  EQU         10H
;ShowDigitsTime = constant, not sure, how long we show digits in blinking
;DontShowDigitsTime = constant, not sure, how long we don't show digits in blinking
displaySize     EQU         8       ; number of digits in display
bufferElemSize  EQU         2       ; size of each segment pattern in buffer
SegmentsNull    EQU         0000000000000000B
                                    ;segment pattern for no LEDs to be displayed
ConvertsSize    EQU         7       ; buffer to hold string for converts functions
NULLChar        EQU         00H
