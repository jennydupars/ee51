;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                       Event handlers for remote unit                       ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



MAX_DISPLAY_STR_SIZE        EQU         64          ; maximum length of display buffer
MAX_COMMAND_STR_SIZE        EQU         8           ; maximum length of command string

NO_EVENT_VAL 				EQU 		0FFFFH 		; unique identifier for no-event 
													; events 