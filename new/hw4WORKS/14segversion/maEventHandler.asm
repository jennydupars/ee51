; Maitreyi Ashok
; Section 1 – Richard Lee

        NAME    EventHandler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 Event Handler                              ;
;                             Event Handler Routines	                     ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; The functions in this file are the basic functions to allow for event handling
; based on both a regular 1 ms timer interrupt as well as a few of the keypad
; buttons that affect the multiplexing display function.
;
; Table of Contents:
; InitCS - Intializes the chip select logic
; ClrIRQvectors - Sets up the interrupt vector table
; IllegalEventHandler - Handles illegal events (not timer interrupts)
; InstallTimerHandler - Sets the address of the event handler as the address
;		to jump to when handling a timer interrupt
; InitTimer - Initializes the timer with frequency 1 KHz
; DisplayEventHandler - handles the 1 ms interval interrupts, calling the
;		multiplexing function accordingly and checking whether the relevant
;		keypad buttons have been pressed down long enough to make an effect on
;		the display
;
; Revision History:
; 10/24/2016	Maitreyi Ashok	Wrote basic outlines and functional specifications
;								for all functions.		


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK

$INCLUDE(EH.inc)

CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP
        EXTRN   DigitMux:NEAR
        
;; InitCS
;
; Description:       Initialize the Peripheral Chip Selects on the 80188.
;
; Operation:         Write the initial values to the PACS and MPCS registers.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: AX, DX
; Stack Depth:       0 words
;
; Author:            Glen George
; Last Modified:     Oct. 29, 1997

InitCS  PROC    NEAR


        MOV     DX, PACSreg     ;setup to write to PACS register
        MOV     AX, PACSval
        OUT     DX, AL          ;write PACSval to PACS (base at 0, 3 wait states)

        MOV     DX, MPCSreg     ;setup to write to MPCS register
        MOV     AX, MPCSval
        OUT     DX, AL          ;write MPCSval to MPCS (I/O space, 3 wait states)


        RET                     ;done so return

InitCS  ENDP


; ClrIRQVectors
;
; Description:      This functions installs the IllegalEventHandler for all
;                   interrupt vectors in the interrupt vector table.  Note
;                   that all 256 vectors are initialized so the code must be
;                   located above 400H.  The initialization skips  (does not
;                   initialize vectors) from vectors FIRST_RESERVED_VEC to
;                   LAST_RESERVED_VEC.
;
; Arguments:        None.
; Return Value:     None.
;
; Local Variables:  CX    - vector counter.
;                   ES:SI - pointer to vector table.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Registers Used:   flags, AX, CX, SI, ES
; Stack Depth:      1 word
;
; Author:           Glen George
; Last Modified:    Feb. 8, 2002

ClrIRQVectors   PROC    NEAR


InitClrVectorLoop:              ;setup to store the same handler 256 times

        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
        MOV     SI, 0           ;initialize SI to skip RESERVED_VECS (4 bytes each)

        MOV     CX, 256         ;up to 256 vectors to initialize


ClrVectorLoop:                  ;loop clearing each vector
                                ;check if should store the vector
        CMP     SI, 4 * FIRST_RESERVED_VEC
        JB	DoStore		        ;if before start of reserved field - store it
        CMP	SI, 4 * LAST_RESERVED_VEC
        JBE	DoneStore	        ;if in the reserved vectors - don't store it
        ;JA	DoStore		        ;otherwise past them - so do the store

DoStore:                        ;store the vector
        MOV     ES: WORD PTR [SI], OFFSET(IllegalEventHandler)
        MOV     ES: WORD PTR [SI + 2], SEG(IllegalEventHandler)

DoneStore:			            ;done storing the vector
        ADD     SI, 4           ;update pointer to next vector

        LOOP    ClrVectorLoop   ;loop until have cleared all vectors
        ;JMP    EndClrIRQVectors;and all done


EndClrIRQVectors:               ;all done, return
        RET


ClrIRQVectors   ENDP


; IllegalEventHandler
;
; Description:       This procedure is the event handler for illegal
;                    (uninitialized) interrupts.  It does nothing - it just
;                    returns after sending a non-specific EOI.
;
; Operation:         Send a non-specific EOI and return.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: None
; Stack Depth:       2 words
;
; Author:            Glen George
; Last Modified:     Dec. 25, 2000

IllegalEventHandler     PROC    NEAR

        NOP                             ;do nothing (can set breakpoint here)

        PUSH    AX                      ;save the registers
        PUSH    DX

        MOV     DX, INTCtrlrEOI         ;send a non-sepecific EOI to the
        MOV     AX, NonSpecEOI          ;   interrupt controller to clear out
        OUT     DX, AL                  ;   the interrupt that got us here

        POP     DX                      ;restore the registers
        POP     AX

        IRET                            ;and return


IllegalEventHandler     ENDP


; InstallHandler
;
; Description:       Install the event handler for the timer interrupt.
;
; Operation:         Writes the address of the timer event handler to the
;                    appropriate interrupt vector.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, AX, ES
; Stack Depth:       0 words
;
; Author:            Glen George
; Last Modified:     Jan. 28, 2002

InstallHandler  PROC    NEAR


        XOR     AX, AX          ;clear ES (interrupt vectors are in segment 0)
        MOV     ES, AX
                                ;store the vector
        MOV     ES: WORD PTR (4 * Tmr0Vec), OFFSET(TimerEventHandler)
        MOV     ES: WORD PTR (4 * Tmr0Vec + 2), SEG(TimerEventHandler)


        RET                     ;all done, return


InstallHandler  ENDP

; InitTimer
;
; Description:       This function initializes the 80188 timers and the time
;                    keeping variables and flags.
;
; Operation:         The 80188 timers are initialized to generate interrupts
;                    every 1 ms.  The interrupt controller is also initialized
;                    to allow the timer interrupts.  Timer #2 is used to scale
;                    the internal clock from 2 MHz to 1 KHz and generate the
;                    interrupts.  The time keeping counters and flags are also
;                    reset.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            Timer #2 and the Interrupt Controller are initialized.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, AX, DX
; Stack Depth:       1 word
;
; Author:            Glen George
; Last Modified:     October 11, 1998

InitTimer       PROC    NEAR
                PUBLIC  InitTimer


        CALL    ResetSeconds    ;reset the counters


        MOV     DX, Tmr2Count   ;initialize the count register to 0
        XOR     AX, AX
        OUT     DX, AL

        MOV     DX, Tmr2MaxCnt  ;setup max count for 1ms counts
        MOV     AX, ONE_MS_CNT
        OUT     DX, AL

        MOV     DX, Tmr2Ctrl    ;setup the control register
        MOV     AX, Tmr2CtrlVal
        OUT     DX, AL


        MOV     DX, INTCtrlrCtrl;setup the interrupt control register
        MOV     AX, INTCtrlrCVal
        OUT     DX, AL

        MOV     DX, INTCtrlrEOI ;send an EOI to turn off any pending interrupts
        MOV     AX, TimerEOI
        OUT     DX, AL


        RET                     ;done so return


InitTimer       ENDP

; 
; TimerEventHandler		
; Description: 		This procedure handles updating the display once every millisecond.
;					An interrupt will be created at a frequency of 1 KHz, and the
;					interrupt vector table stores the address of this event handler
;					for the timer interrupt. Thus, this function calls the function
;					to multiplex the LEDs every time, since the LEDs are also multiplexed
;					at a frequency of 1 KHz. In addition, if the scroll left/right button  
;					has been pressed for 1 second, then this function will call
;					the multiplexing information to scroll left/right. In addition,
;					if the blinking button is pressed for atleast 1 second, then
;					the multiplexing function will be called with blinking parameters
;					as well.
;
; Operation:  		The counters for pressing the scroll and display buttons from 
;					keypad are updated. If one second has passed, then we call the
;					multiplexing function with these parameters selected. If not,
;					the multiplexing function is called anyway so that the next
;					digit can be displayed for the next millisecond. This allows
;					for blinking, scrolling, and general LED display to be used,
;					with less hardware and more software used to implement the 
;					features, as only one set of LED segments needs to be on at
;					any point in time. Once one second passes, we reset the counters
;					to count back down again. Also, if the key is not pressed, 
;					then the counter is reset anyway, since we do not care how much
;					time has passed when not pressing the key.
;
; Arguments:   		None
; Return Value:		None
;
; Local Variables:	None
; Shared Variables: scrollLeftPress - updated and checked for zero to see if 
;								the scroll left button is pressed for a second
;					scrollRightPress - updated and checked for zero to see if 
;								the scroll right button is pressed for a second
;					blinkPress - updated and checked for zero to see if 
;								the blink button is pressed for a second
; Global Variables: None
;
; Input:			Whether blink/scrolling buttons in keypad are pressed
; Output:			Segments to display
;
; Error Handling:	None
;
; Algorithms:		None
; Data Structures:	None
;
; Registers Changed: 
; Stack Depth:		
;
; Limitations:		This implementation only allows the multiplexing to take place
;					at 1 ms intervals. In addition, the keypad buttons need to be
;					pressed down for 1 second to have any effect.
;
; Author:			Maitreyi Ashok
; Last Modified:	10/24/2016	Maitreyi Ashok		Wrote functional specification
;													and outline
;					
; Operational Notes
; Save registers on stack so they aren't changed
; If any of the keypad buttons are pressed (blink, scroll left/right),
;   update the counters accordingly
; If they have been pressed for 1 second, call DigitMux with those parameters
; 
; 
; Pseudocode
; Save registers on stack
; IF scrollLeft pressed
;		scrollLeftPress --
;		IF scrollLeftPress == 0
;				scrollLeftPress = SECOND_COUNT
;				left = True
;		ENDIF
; ELSE
;		scrollLeftPress = SECOND_COUNT
; ENDIF
; IF scrollRight pressed
;		scrollRightPress --
;		IF scrollRightPress == 0
;				scrollRightPress = SECOND_COUNT
;				right = True
;		ENDIF
; ELSE
;		scrollRightPress = SECOND_COUNT
; ENDIF
; IF blink pressed
;		blinkPress --
;		IF blinkPress == 0
;				blinkPress = SECOND_COUNT
;				blinkButton = True
;		ENDIF
; ELSE
;		blinkPress = SECOND_COUNT
; ENDIF
; 
; CALL	DigitMux(blinkButton, rightButton, leftButton)
; Send timer EOI
; Restore registers

TimerEventHandler		PROC        NEAR
						PUBLIC      TimerEventHandler
SetUp:
		PUSH	AX
		PUSH	DX
MuxDigits:
		CALL	DigitMux
EndEventHandler:
		MOV		DX, INTCtrlrEOI
		MOV		AX, TimerEOI
		OUT		DX, AL
		POP 	DX
		POP		AX
		IRET
TimerEventHandler	ENDP



CODE    ENDS

;the data segment

DATA    SEGMENT PUBLIC  'DATA'

; scrollLeftPress = SECOND_COUNT
; scrollRightPress = SECOND_COUNT
; scrollBlinkPress = SECOND_COUNT

DATA    ENDS




;the stack

STACK   SEGMENT STACK  'STACK'

                

TopOfStack      LABEL   WORD

STACK   ENDS

        END