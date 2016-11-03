	NAME		DISPLAY

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;								    DISPLAY                                  ;
;                           	   Homework 4        		                 ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Contains 3 display routines: Display, DisplayNum, and DisplayHex:
;
;
; This file contains the functions for displaying strings on the 14-segment
; displays.  The functions included are:
;   Display   	   - displays a string to the LED display 
;   DisplayNum     - displays a number as a decimal to the LED display
;   DisplayHex     - displays a number in hexadecimal to the LED display
;   InitDisplay    - initialize the display and its variables
;   DisplayMux     - multiplex the LED display



; Revision History:
;     10/24/16  	Jennifer Du      initial revision
; 	  10/26/16		Jennifer Du		 writing assembly code
;


; include files
$INCLUDE(display.inc)
$INCLUDE(common.inc)

CGROUP  GROUP   CODE

CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP
		
;external function declarations
    
        EXTRN   Hex2String:NEAR 	; converts number to hexstring
		EXTRN 	Dec2String:NEAR		; converts number to decstring
		
		
		
; Display 
;
; Description: 		This function converts an ASCII string into the 
;					series of 14-segment codes that, when ported to the LED 
;					display, forms a visual representation of that string. 
;					The function is passed a <null> terminated string (str) to
;					output to the LED display. The string is passed by 
;					reference in ES:SI (i.e. the address of the string is 
;					ES:SI). The maximum length of the string that can be 
;					displayed at any given moment is 8 characters long.
;
; Operation: 		This function will loop through the given string, and look 
;					up the 14 segment code for each character in the 14-segment 
;					code table. Then it will write the value of the 14 segment 
; 					code to the buffer in the order that the characters appear. 
;
; Arguments: 		SI - address of string to be displayed
; Return Value:		None. 
;
; Local Variables:	SI - address of string to be displayed
; Shared Variables: segBuffer - place to store the segment code values  
; Global Variables: None. 
;
; Input: 			None. 
; Output: 			None.
; Error Handling: 	None. 
; Algorithms: 		None. 
; Data Structures: 	The segment buffer is an array of words which holds the 
;					14-segment code values for each character in the string 
;					
; Pseudocode:


	save registers 
	
	for i in numDigits:						; for each digit in the buffer, 
		if (i <= string.length):  			; look up 14-seg code for the ith 
			buffer[i] = segTable(string[i]) ; character in the string and store
											; if we are not at end of string
		else: 								; if string length less than buffer 
			buffer[i] = ASCII_NULL			; pad with null characters 
		
	restore registers 
		
;		
;
; DisplayNum 
;
; Description: 		This function turns a given number into its decimal 
;					representation and gets it ready to be displayed on the 
;					LED display. The function is passed a 16-bit signed value 
;					(n) to output in decimal (at most 5 digits plus sign) to 
;					the LED display. The number (n) is passed in AX by value. 
;
; Operation: 		We will use two previously written functions to 
;					display a number in decimal. First, we will turn the given
;					number into a string in decimal form using Dec2String, and
;					then we will call Display on this string to show it 
;					on the LED display.
;
; Arguments: 		AX - 16-bit signed value to be turned into a decimal string
; Return Value: 	None.
;
; Local Variables: 	AX - number to be displayed
;					SI - address of string to be displayed 
; Shared Variables: segBuffer - place to store the segment code values  
; Global Variables:	None. 
; Input: 			None. 
; Output: 			None.
; Error Handling: 	None.
; Algorithms: 		None.
; Data Structures: 	None.
;

Pseudocode:

	CALL Dec2String				; turns number to decimal string 
	CALL Display 				; calls display on the string 


;
;
; DisplayHex 
;
; Description: 		This function turns a given number into its hex 
;					representation and gets it ready to be displayed. 
;					The function is passed a 16-bit unsigned value (n) to 
;					output in hexadecimal (at most 4 digits) to the LED 
;					display. The number (n) is passed in AX by value. 
;
; Operation:		We will use two previously written functions to 
;					display a number in hex. First, we will turn the given
;					number into a string in hex form using Hex2String, and
;					then we will call Display on this string to show it 
;					on the LED display.
;
; Arguments:		AX - 16-bit unsigned value to be turned into a hex string
;
; Return Value:		None.
;
; Local Variables:	AX - 16-bit unsigned value to be turned into a hex string
;                   SI - address of string to be displayed  
; Shared Variables: segBuffer - place to store the segment code values  
; Global Variables: None. 
; Input:			None. 
; Output:			None. 
; Error Handling:	None. 
; Algorithms:		None. 
; Data Structures: 	None. 
;

Pseudocode:

	CALL Hex2String		; converts number to hex string 
	CALL Display 		; displays string on LED display 
	


	
; InitDisplay 
;
; Description: 		This function initializes the segment buffer, clears 
;					the display (by clearing the seg buffer), and 
;					initializes display multiplexing variables. 
;
; Operation:   		This function blanks the digits and initializes the 
;					display muxing variables. 
;
; Arguments:   		None. 
; Return Value:		None. 		
; Local Variables: 	i - counter for loop 
; Shared Variables: muxCounter - keeps track of next digit for mux 
;					segBuffer  - buffer is filled with DISPLAY_BLANK
; Global Variables: None. 
; Input:			None. 
; Output:			The LED display is blanked.
; Error Handling:	None.
; Algorithms:		None.
; Data Structures: 	None.
;



	i = 0 					; counter for looping through display's digits
	while (i < numDigits)	
		display[i] = LED_BLANK_PATTERN ; clears display
		i += 1 					; move onto next digit 
	endwhile 
	
	muxCounter = 0 			; ready for muxing 

InitDisplay     PROC    NEAR
                PUBLIC  InitDisplay


StartInitDisplay:                       ;start clearing the display
        MOV     CX, numSegs             ;number of segments to clear
        PUSH    DS                      ;setup for storing segments
        POP     ES                      ;ES:DI points to the segments
        MOV     DI, OFFSET(segBuffer)
        CLD                             ;make sure do auto-increment
        MOV     AL, LED_BLANK           ;get the blank segment pattern

        REP  STOSB                      ;blank all the digits

InitMuxVariables:
		MOV     currentSeg, 0			; Initialize current mux segment 
		;JMP    EndInitDisplay          ;all done now
		
EndInitDisplay:                         ;done initializing the display - return
        RET


InitDisplay     ENDP


; DisplayMux 
;
; Description: 		Multiplexer for the display. This procedure multiplexes
;					the LED display under interrupt control. It is meant to 
;					be called at a regular interval of about 1 ms. This 
;					function is going to display 1 digit for 1 instance. 
;	
; Operation: 		The multiplexer remembers which digit was called last,
;					by storing and updating the muxCounter variable. Then it 
;					writes the 14-segment code of the next digit to the
;					display at the current digit. One digit is output each time
;					this function is called.
;
; Arguments:		None.
; Return Value:		None.
; Local Variables:	None.
; Shared Variables: muxCounter - number that keeps track of which digit to
;									display to
;					buffer 	   - segment buffer holding segment code values 
; Global Variables: None. 
; Input:			None. 
; Output:			The next digit is output to the display.  
; Error Handling:	None. 
; Algorithms:		None. 
; Data Structures: 	segment buffer - array of bytes holding segment code values 
;

// glen's code first decrements the muxCounter, and then displays the current 
// segment. does it make a difference if you change muxCnter first or display
// first?


DisplayMux 			PROC	NEAR
					PUBLIC	DisplayMux
	
DisplayMuxInit:					; first get pattern to mux 
	MOV 	BX, muxCounter		; get current digit offset into arrays
	MOV 	AX, segBuffer[BX]	; get the digit pattern
	;JMP	DisplayDigit		; output it to the display 

DisplayDigit: 					; output digit pattern to the display 
	///////////////////////////////////////////
	;JMP	IncrementMuxCounter

IncrementMuxCounter:			; set number to mux next time 
	MOV		AX, muxCounter		; we want (muxCounter + 1) mod (numDigits)
	INC 	AX
	DIV		numSegs
	MOV 	muxCounter, DX		; move modded value back into muxCounter
	;JMP EndDisplayMux
	
	
// should the size of segBuffer match up with number of digits?
	

	
EndDisplayMux:
	RET							; done multiplexing LEDs - return
	
DisplayMux 			ENDP
	save registers
	
	
	display[muxCounter] = buffer[muxCounter]	  ; write digit to display
	muxCounter = (muxCounter + 1) mod (numDigits) ; update muxCounter 
	
	send EOI
	restore registers

; SegTable
;
; should my 14 segment table go here?

PROGRAM ENDS




; the data segment 

DATA	SEGMENT	PUBLIC 	'DATA'

segBuffer	DW	numSegs	DUP	(?)		; buffer holding currently displayed patterns
									; holds words because 14-seg codes are words
currentSeg	DW	?
		
DATA	ENDS

	END