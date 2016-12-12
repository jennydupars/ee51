;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                       Event Handlers and User Interface                    ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



    MAX_DISPLAY_STR_SIZE        EQU         64    ; maximum length of display buffer
    MAX_COMMAND_STR_SIZE        EQU         8     ; maximum length of command string

; Event values for use in event queue 

    NO_EVENT_VAL 			EQU 		0FFFFH 		; unique identifier for no-event 
                                                        ; events 
    KEY_PRESS_EVENT 		EQU 		0002H 		; identifier indicating key press
													
; event type values to be enqueued to EventQueue 
	
	DATA_AVAIL_EVENT	EQU 	0004H		; data is received event value 
	LINE_STATUS_EVENT	EQU 	0000H		; LSR events count as error events 
    TRANSMIT_QUEUE_FULL_ERROR   EQU     0000H ; Tx queue full error has value 08
    ERROR_VAL           EQU     0000H       ; AH event type number for errors                                                     