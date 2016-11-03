	NAME		KEYPAD

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;								     KEYPAD                                  ;
;                           	   Homework 5         		                 ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;
; This file contains the functions for keypad input reading. The functions included are:
;   InitKeypad - initializes variables used to scan and debounce keypad. 
; 	KeypadMux - keypad scanning and debouncing function


; Revision History:
;     10/31/16  	Jennifer Du      initial revision


		
; KeypadScanner 
;
; Description: 		This function is the keypad scanning and debouncing function for 
;					the RoboTrike. This function is called by the timer event handler, 
;			 		and every time it is called, it either checks for a new key being 
;					pressed if none is currently pressed, or debounces the currently 
;					pressed key. Once it has a debounced key, this function will call 
;					the supplied EnqueueEvent function with the key event in AH and the 
;					key value in AL. The EnqueueEvent stores the events and key values 
;					passed to it in a 256 byte buffer called EventBuf. 
;
;					This function will be able to handle at most 2 keys pressed at the
;					same time. 
;
; Operation: 		This function keeps track of what keys have been pressed and for how 
;					long in a 16-element array called keyStatus. First, it reads from the 
;					input location, and from the value given, we will be able to tell which
;					keys have been pressed. From this, we will keep track of the changes to 
;					make to the keyStatus array by storing the key values in the 
;
; Arguments: 		None. 
; Return Value:		None. 
;
; Local Variables:	
; Shared Variables:  
; Global Variables: None. 
;
; Input: 			User input to the keypad. 
; Output: 			None.
;
; Error Handling: 	None. 
; Registers Used: 	
;
; Algorithms: 		None. 
; Data Structures: 	 
;					
                                        
                                        
Pseudocode: 

	save registers 
	
	IN AX, KeypadPortLoc 		; store 
	
	if key is pressed :
		debounce key 
		AH -> key event (pressed??)
		AL -> value 
	if key is not pressed : 
		check for a key being pressed 
	restore registers 
            
;		
;
; InitKeypad  
;
; Description: 		
;
; Operation: 		
;
; Arguments: 		
; Return Value: 	None.
; Local Variables: 	
; Shared Variables: 
; Global Variables:	None. 
; Input: 			None. 
; Output: 			None.
; Error Handling: 	None.
; Registers used: 	
; Algorithms: 		None.
; Data Structures: 	
;


; the data segment 

DATA	SEGMENT	PUBLIC 	'DATA'
		
DATA	ENDS


