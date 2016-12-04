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
; 	  11/04/16 		Jennifer Du		 commenting 


; External function declarations
	EXTRN 	EnqueueEvent:NEAR 		; function that adds key event and value to 
									; the EventBuf buffer 


; Include files 
$INCLUDE(keypad.inc)				; defines constants used for keypad 


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
;	            key value in AL. 
;				
;				Each key value will be represented by the value in 
; 				the row's location, that way multiple key presses in the same row 
;				will be able to be detected. The upper 4 bits in AL will store the row 
; 				number (0 to 3) and the lower 4 bits will store the keypad value of 
; 				the row when a key is pressed. This is the grid of keys and the AL 
; 				results that will be enqueued when the corresponding key is pressed: 
;
; 							key 1 	key 2	key 3 	key 4
;					row 0	 0e 	 0d 	 0b 	 07 
;					row 1    1e 	 1d 	 1b 	 17
;					row 2    2e 	 2d 	 2b 	 27
; 					row 3  	 3e 	 3d 	 3b 	 37
;
;				Since each row will be scanned at once in one function call, we can 
;				handle multiple key presses in one row. This function can also work 
; 				with long presses by enqueuing a key press multiple times. 
;
; Operation:    This function keeps track of what key has been pressed and for how 
;	            long. It uses this information to determine which key presses to enqueue.
; 				First, it reads from the input location, and store the key values in the 
;               variable currentKey, and a counter of how many function calls they are 
; 				pressed for in debounceCount. 
;
;				We scan one row per function call, and store any pressed keys if their 
;				duration of being pressed (how many function calls have they been 
;				pressed) is greater than 80 iterations. (about 80 ms) Then, we continue
; 				to scan that row until the pressed key changes, and then update the 
; 				row pointer to scan the next row at the next interrupt.
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
; Registers Used: 	AX, DX, CX 
;
; Algorithms: 		None. 
; Data Structures:  None.
;	          

KeypadMux 		PROC	NEAR
				PUBLIC	KeypadMux
				
StartKeypadMux: 					; here we get the currently pressed key in scanned row
	
	XOR 	AX, AX 					; first, clear AX 
	MOV 	DX, KEYPAD_LOC			; stores base location into DX for keypad reading port 
	ADD 	DX, currentRow 			; add offset to get the specific row we want 
	IN 		AX, DX 					; get keypad value at loc DX--do we have any keys pressed?
	AND 	AX, KEY_MASK			; use key mask to get the lowest 4 bits of keypad value 
	CMP 	AL, currentKey 			; compare this key to the current key (last pressed key)
	JNE 	NewKey						; if they're not equal, there's a new key in this row 
	JE		SameKey						; if they are the same, keep track of currentKey 
	
NewKey: 
	
	MOV 	currentKey, AL 				; if new key, store the new key 
	MOV 	debounceCount, PRESS_TIME	; reset the debounceCount to original value 
	CMP 	AL, UNPRESSED_KEY			; is the new key actually no key?
	JE 		NoKeyPressed				; if the new key's value matches 0fH, it's no key 
	JNE 	EndKeypadMux				; if new key is a press, end function and wait til next time

NoKeyPressed: 						; if no key pressed, 
	
	JMP 	UpdateRow					; don't mess with variables and move to next row 

SameKey: 							; if same key was pressed, 
	
	CMP 	currentKey, UNPRESSED_KEY	; see if we are continuing to sense nothing 
	JE 		UpdateRow 					; if that's the case, just update row and leave 
	
	DEC 	debounceCount				; otherwise, we decrement debouncecount 
	CMP 	debounceCount, 0 			; if we have logged enough time for this key press,
	JE 		EnqueueKeyEvent 				; enqueue event 
	JNE 	EndKeypadMux					; but if not, we end function (NOTE: without 
											; updating row so we continue to scan this row 
											; for this key's input until input ends)
	
EnqueueKeyEvent:					; if a key has been pressed for sufficiently long: 

	XOR 	AX, AX						; clear AX 
	MOV 	AH, KEY_PRESS_EVENT			; upper byte will hold key press event (01 for now)
	MOV 	CX, currentRow 				; start processing CX to be stored in AL 
	SHL 	CX, 4						; shift up 4 bits to express row # in upper nibble of AL
	MOV 	AL, CL						; move row number to upper nibble of AL (second dig = 0)
	ADD 	AL, currentKey 				; add current key's value (in lower nibble of AL)
	CALL 	EnqueueEvent				; then call EnqueueEvent with stored AX 
	MOV 	debounceCount, REPEAT_TIME	; start possibility of autorepeat 
	JMP 	EndKeypadMux				; then finish function, again without updating row 
	
UpdateRow:  						; move currentRow to next row to scan a new row 

	MOV 	DX, 0 					; clear DX before dividing 
	MOV  	AX, currentRow			; want to update currentRow 
	INC 	AX  					; by incrementing 
	MOV 	CX, NUM_ROWS			; and then 
	DIV 	CX						; dividing by number of rows,
	MOV 	currentRow, DX			; storing remainder to account for wraparound 

EndKeypadMux:
	
	RET

KeypadMux 	ENDP								 



	

;
; InitKeypad  
;
; Description:  This function initializes the variables used in keeping track of what 
;               keys are being pressed on the keypad. 
;
; Operation:    Set currentKey to the value of an unpressed key, currentRow to the first 
;				row, and the debounceCount to the PRESS_TIME as defined in the include file.
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
	MOV 	currentKey, UNPRESSED_KEY	; initialize value of current key to unpressed (0fH)
	MOV 	currentRow, 0000H 			; initial row to start scanning will be the first one 
				 
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
	
; currentRow stores the row number that is currently being scanned 
	currentRow			DW 		?
	
DATA	ENDS

END 