	NAME	KEYPAD
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;	                                 KEYPAD                                  ;
;                                  Homework 5                                ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This file contains the functions for keypad input reading. The functions included are:
;   InitKeypad - initializes variables used to scan and debounce keypad. 
; 	KeypadMux - keypad scanning and debouncing function


; Revision History:
;     10/31/16  	Jennifer Du      initial revision
; 	  11/02/16 		Jennifer Du 	 writing in assembly 


; External function declarations
	EXTRN 	EnqueueEvent:NEAR 		; function that adds key event and value to 
									; the EventBuf buffer 


; Include files 
$INCLUDE(keypad.inc)
$INCLUDE(common.inc)


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP

;
;
;
; KeypadMux  
;
; Description:  This function is the keypad scanning and debouncing function for 
;	            the RoboTrike. This function is called by the timer event handler, 
;	            and every time it is called, it either checks for a new key being 
;	            pressed if none is currently pressed, or debounces the currently 
;	            pressed key. Once it has a debounced key, this function will call 
;	            the supplied EnqueueEvent function with the key event in AH and the 
;	            key value in AL. Each key value will be represented by the value in 
; 				the row's location, that way multiple key presses in the same row 
;				will be able to be detected. If no key is pressed in a certain row, 
;				the value stored will be 0FH. If key 0 in that row is pressed, then 
;				the value stored will be 0EH, or 0FH - 0001b. If key 1 in that row is 
;				pressed, then the value stored will be 0DH, or 0FH - 0010b, and so on. 
; 				Each key corresponds to a bit, and the value of reading the row will 
;				be the difference between 0FH and the sum of the keys pressed. 
;
;	            This function will be able to handle at most 2 keys pressed at the
;	            same time, in the same row. 
;
; Operation:    This function keeps track of what keys have been pressed and for how 
;	            long in two shared variables. First, it reads from the 
;	            input location, and from the value given, we will be able to tell which
;	            keys have been pressed. From this, we store the key values in the 
;               variables key1val and key2val, and the duration of their pressed 
;               status in key1status and key2status. 
;
;				We scan one row per function call, and store any pressed keys if their 
;				duration of being pressed (how many function calls have they been 
;				pressed) is greater than 500 iterations. Then, we update the row to scan 
;				at the next interrupt, and add one to the number of iterations a key 
;				has been pressed. 
;
; Arguments:        None. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: debounceCount - how long (in function calls) current key press has lasted 
;					currentRow - current row of keys being scanned 
;					currentKey - value of current key being pressed 
; Global Variables:	None.
; 
; Input:            User input to the keypad. 
; Output:           None.
;
; Error Handling: 	None. 
; Registers Used: 	AX, DX 
;
; Algorithms: 		None. 
; Data Structures:  None.
;	          

KeypadMux 		PROC	NEAR
				PUBLIC	KeypadMux
				
StartKeypadMux: 
	
	XOR 	AX, AX 
	MOV 	DX, KEYPAD_LOC
	ADD 	DX, currentRow 					; move location of currentRow into DX
	IN 		AX, DX 							; get lower bits at DX (any key?)
	AND 	AX, KEY_MASK
	CMP 	AL, currentKey 					
	JNE 	NewKey
	JE		SameKey
	
NewKey: 
	
	MOV 	currentKey, AL 					; if new key, store the new key 
	MOV 	debounceCount, PRESS_TIME
	CMP 	AL, UNPRESSED_KEY				; is the new key actually no key?
	JE 		NoKeyPressed	
	JNE 	EndKeypadMux

NoKeyPressed: 
	
	JMP 	UpdateRow

SameKey: 
	
	CMP 	currentKey, UNPRESSED_KEY
	JE 		UpdateRow 
	
	DEC 	debounceCount
	CMP 	debounceCount, 0 
	JE 		EnqueueKeyEvent 
	JNE 	EndKeypadMux
	
EnqueueKeyEvent:

	XOR 	AX, AX
	MOV 	AH, KEY_PRESS_EVENT
	MOV 	CX, currentRow 
	SHL 	CX, 4
	MOV 	AL, CL
	ADD 	AL, currentKey 
	CALL 	EnqueueEvent
	MOV 	debounceCount, REPEAT_TIME
	JMP 	EndKeypadMux
	
UpdateRow:  

	MOV 	DX, 0 					; clear DX before dividing 
	MOV  	AX, currentRow
	INC 	AX  
	MOV 	CX, NUM_ROWS
	DIV 	CX
	MOV 	currentRow, DX

EndKeypadMux:
	
	RET

KeypadMux 	ENDP								 



	

;
; InitKeypad  
;
; Description:  This function initializes the variables used in keeping track of what 
;               keys are being pressed on the keypad. 
;
; Operation:    Set vars key1 and key2 to the unpressed value, set vars key1count 
;               and key2count to 0.
;
; Arguments:        None. 
; Return Value:     None.
;
; Local Variables:  None. 
; Shared Variables: debounceCount - how long (in function calls) current key press has lasted 
;					currentRow - current row of keys being scanned 
;					currentKey - value of current key being pressed 
; Global Variables:	None.
; 
; Input:            None. 
; Output:           None.
; Error Handling:   None.
; Registers used:   None. 
; Algorithms:       None.
; Data Structures:  None. 

InitKeypad 		PROC	NEAR
				PUBLIC	InitKeypad
    
StartInitKeypad: 
	

	MOV 	debounceCount, PRESS_TIME 	; initialize debounceCount to amount of iterations needed to register key press 
	MOV 	currentKey, UNPRESSED_KEY		; initialize value of current key to unpressed 
	MOV 	currentRow, 0000H 						; initial row to start scanning will be the first one 
				 
	RET
InitKeypad 	ENDP

CODE 	ENDS 


;
; the data segment 
DATA	SEGMENT	PUBLIC 'DATA'

; debounceCount tells us how long the current key has been pressed in terms
; of number of function calls
    debounceCount		DW 		?

; currentKey stores the value of the key currently being pressed 	
	currentKey			DB 		?
	
; currentRow stores the row number that is 	currently being scanned 
	currentRow			DW 		?
	
DATA	ENDS

END 