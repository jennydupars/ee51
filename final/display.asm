	NAME		DISPLAY

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;									DISPLAY                     			 ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;
; This file contains the functions for displaying strings on the 14-segment
; displays. The functions included are:
;   Display   	   - displays a string to the LED display 
;   DisplayNum     - displays a number as a decimal to the LED display
;   DisplayHex     - displays a number in hexadecimal to the LED display
;   InitDisplay    - initialize the display and its variables
;   DisplayMux     - multiplex the LED display
; All are public functions. 
; Scrolling display has been implemented, so now strings longer than 8 digits may 
; be displayed on the LED display. The code below operates a scrolling, 14-segment 
; LED display. 

; Revision History:
;     10/24/16  	Jennifer Du      initial revision
; 	  10/26/16		Jennifer Du		 writing assembly code
;	  10/29/16 		Jennifer Du 	 commenting 
; 	  12/02/16 		Jennifer Du 	 implementing scrolling 

		

; include files
$INCLUDE(common.inc)		; commonly used constants 
$INCLUDE(converts.inc)		; variables used for hex->string or dec-> conversions
$INCLUDE(display.inc)		; display constants, like ASCII strings and lengths of 
							; shared variables and display 


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP


;external function declarations
    
        EXTRN   Hex2String:NEAR 	; converts number to hexstring
		EXTRN 	Dec2String:NEAR		; converts number to decstring
        EXTRN   ASCIISegTable:BYTE  ; 14-segment codes for segment buffer 
		
		
; Display 
;
; Description: 		This function converts an ASCII string into a 
;					series of 14-segment codes that, when ported to the LED 
;					display, forms a visual representation of that string. 
;					The function is passed a <null> terminated string (str) to
;					output to the LED display. The string is passed by 
;					reference in ES:SI (i.e. the address of the string is 
;					ES:SI). 
;
;					The maximum length of the string that can be displayed at any 
; 					given moment is 8 characters long, the length of the physical 
; 					row of LEDs. The maximum length of a string that can be displayed
; 					is defined to be 64 characters. The 8-character display will be 
; 					able to scroll through the string, displaying 8 characters at a 
; 					time.
; 
; 					Strings shorter than the display will be padded with 
; 					blank spaces. 
;
; Operation: 		This function will loop through the given string, and look 
;					up the 14 segment code for each character in the 14-segment 
;					code table, moving it byte by byte, since 14-segment display 
; 					codes are word-sized. Then it will write the value of the 14
; 					segment code to the buffer in the order that the characters 
; 					appear in the string passed into this function.
; 
;                   If the string is shorter than the length of the segment 
;                   buffer, the buffer will be padded with blank spaces. If the 
;                   string is longer than the length of the segment buffer, it 
;                   will be cut off at the maximum length, 64 characters.
; 
; 					To implement possible scrolling for the string passed in SI, 
; 					we also count the length of the string currently getting ready
; 					to be displayed, so that when DisplayMux is called, we will be 
; 					able to tell whether or not scrolling should be done. We will 
; 					also initialize the scrollCnt shared variable, which holds the 
; 					max count of the scroll position change.   	
;
; Arguments: 		SI - address of string to be displayed
; Return Value:		None. 
;
; Local Variables:	SI - address of string to be displayed
; Shared Variables: charDispBuffer (w) - place to store the segment code values 
;                   scrollCnt (w) - max count of scroll position change 
;                   stringLength (w) - 	variable storing length of string
;                   scrollPos (w) - position in string to start scrolling display at 
; Global Variables: None. 
;
; Input: 			None. 
; Output: 			None.
; Error Handling: 	None. 
; Algorithms: 		None. 
; Data Structures: 	The segment buffer is an array of words which holds the 
;					14-segment code values for each character in the string.
;					
                                        
                                        
Display         PROC    NEAR
                PUBLIC  Display
                
StartDisplay:
    PUSHA
    
    MOV     CX, 0           ; initialize counter for the charDispBuffer
    MOV     DX, 0           ; count the length of string 
    
CheckEndOfString:
    XOR     AX, AX					    ; clear AX so AH does not affect lookup index
    MOV     AL, ES:[SI]                 ; get value of the 1st character in string
	INC     SI                          ; move to next character in string
    INC     DX                          ; use DX to count length of string; increment
										; alongside SI 
    CMP     AL, ASCII_NULL              ; see if the string has ended (see if the
                                        ; current character is equal to ASCII_NULL)                        
    JE      EndOfString					; if =, we are at the end of the string 
    ;JMP    StoreSegTableValue
    
StoreSegTableValue:

    SHL     AX, 1                       ; multiply ascii character value by wordsize 
                                        ; (since each display code is 1 word long, 
                                        ; we want to go to wordSize*ASCII_VAL to get to
                                        ; the right character in the table) 
    MOV     BX, AX                      ; move the ascii value (index in the table) 
                                        ; to BX to be accessed soon
    
    MOV     AL, CS:ASCIISegTable[BX]    ; move the code values into AX byte by byte
    MOV     AH, CS:ASCIISegTable[BX+1]  
    
    MOV     BX, CX                  	; move index in charDispBuffer here
    MOV     charDispBuffer[BX], AX      ; move display code value into segBuffer 
    
    ADD     CX, WORDSIZE                ; increment index in charDispBuffer - CX is 
                                        ; always the location we insert display codes
                                        ; into
    CMP     CX, DISPLAY_BUFFER_LENGTH   ; if we have reached capacity of the segment 
                                        ; buffer, index in display buffer will be 
                                        ; equal to length of display buffer 
    JL      CheckEndOfString          	; not equal! -> store more segment table values
    JGE     EndDisplay                  ; >= end this function, buffer can't fit more

    ;JMP     CheckEndOfString           ; after every increment in the string pointer, 
                                        ; check if we have reached the end of string.
EndOfString:
    
    MOV     BX, CX                      ; move index in character display buffer into 
                                        ; index register 
    
    MOV     charDispBuffer[BX], ASCII_NULL ; store null pattern in each entry in 
                                        ; segment buffer after end of string reached
    ADD     CX, WORDSIZE                ; increment index in charDispBuffer
    ;JMP     CheckEndOfBufferAfterString
    
CheckEndOfBufferAfterString:            ; string is done and we are checking if buffer
                                        ; capacity has been reached
    CMP     CX, DISPLAY_BUFFER_LENGTH
    JL      EndOfString                 ; buffer capacity not reached: add more spaces
    ;JGE     EndDisplay                 ; buffer capacity reached: move on 
    
EndDisplay:                     ; change variables to be used in next scroll position
    DEC     DX                      ; decrement stringLength counter to reverse 
                                    ; extra increment after string ended 
    MOV     stringLength, DX        ; store string length counted by DX into 
                                    ; string length
    MOV     scrollPos, 0            ; set initial scrolling position for new string 
                                    ; is at 0 
    MOV     scrollCnt, 0            ; set scrolling count for new string at 0 
    POPA                    ; restore registers 
    RET                     ; we are done, return
    
Display ENDP

    
;		
;
; DisplayNum 
;
; Description: 		This function turns a given number into its decimal 
;					representation and gets it ready to be displayed on the 
;					LED display. The function is passed a 16-bit signed value 
;					(n) to output in decimal (5 digits plus sign) to 
;					the LED display, reading left to right. The argument is 
; 					passed in AX by value. 
;
; Operation: 		We will use two previously written functions to 
;					display a number in decimal. First, we will turn the given
;					number into a string in decimal form using Dec2String, and
;					then we will call Display on this string to store each of 
; 					the string's characters as a segment pattern code in the 
; 					character display buffer. 
;
; Arguments: 		AX - 16-bit signed value to be turned into a decimal string
; Return Value: 	None.
; Local Variables: 	AX - number to be displayed
;					SI - address of string to be displayed 
; Shared Variables: stringBuffer (r) - place Dec2String function writes decimal string
; Global Variables:	None. 
; Input: 			None. 
; Output: 			None.
; Error Handling: 	None.
; Algorithms: 		None.
; Data Structures: 	None.
;

DisplayNum      PROC    NEAR
                PUBLIC  DisplayNum
    PUSHA
    MOV     SI, OFFSET(stringBuffer) ; DS:SI should point to stringBuffer, set this 
                                        ; up so Dec2String can write string there.
    MOV     BX, DS					; Dec2String expects a string in the 
    MOV     ES, BX					; ES segment
	CALL    Dec2String				; turns number to decimal string 
    
	MOV 	SI, OFFSET(stringBuffer); load SI with address of string buffer 
	CALL    Display 				; calls display on the string  
    POPA
    RET
DisplayNum      ENDP          

;
;
; DisplayHex 
;
; Description: 		This function turns a given number into its hex 
;					representation and gets it ready to be displayed. 
;					The function is passed a 16-bit unsigned value (n) to 
;					output in hexadecimal (4 digits) to the LED 
;					display. The number (n) is passed in AX by value. 
;
; Operation:		We will use two previously written functions to 
;					display a number in hex. First, we will turn the given
;					number into a string stored at SI in hex form using 
; 					Hex2String, and then we will call Display on this string 
; 					to show it on the LED display.
;
; Arguments:		AX - 16-bit unsigned value to be turned into a hex string
;
; Return Value:		None.
;
; Local Variables:	AX - 16-bit unsigned value to be turned into a hex string
;                   SI - address of string to be displayed  
; Shared Variables: stringBuffer (r) - place to store the ASCII characters to turn
;						into segment codes 
; Global Variables: None. 
; Input:			None. 
; Output:			None. 
; Error Handling:	None. 
; Algorithms:		None. 
; Data Structures: 	None. 
;
DisplayHex      PROC    NEAR
                PUBLIC  DisplayHex

    MOV     SI, OFFSET(stringBuffer)    ; set address of SI up so that Hex2String
                                            ; can write the string here
    MOV     BX, DS					; Hex2String expects a string at ES, so 
    MOV     ES, BX					; set ES equal to DS 
	CALL    Hex2String				; converts number to hex string 
        
	MOV 	SI, OFFSET(stringBuffer); load SI with address of string buffer 
    CALL    Display 				; calls Display on the string
	RET
DisplayHex      ENDP


	
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
; Local Variables: 	BX - counter for looping through segment buffer
; Shared Variables: currentDispChar (w) - keeps track of next digit for mux 
;					charDispBuffer  (w) - buffer is filled with DISPLAY_BLANK
; Global Variables: None. 
; Input:			None. 
; Output:			The LED display is blanked.
; Error Handling:	None.
; Algorithms:		None.
; Data Structures: 	The segment buffer is an array of words which holds the 
;					14-segment code values for each character in the string.
;


InitDisplay     PROC    NEAR
                PUBLIC  InitDisplay

StartInitDisplay:                   
    MOV     BX, 0                   ; start counter at 0 (this counter loops 
                                    ; segment buffer and clears each entry)
   
ClearDisplay:                       ; start clearing the display
    MOV     CX, NUM_DIGITS          ; number of digits on display to clear
    MOV     charDispBuffer[BX], LED_BLANK   ; move blank character into each 
                                            ; charDispBuffer entry
    INC     BX                      ; increment counter
    CMP     BX,NUM_DIGITS           ; compare counter to number of segments
    JNE     ClearDisplay            ; if the counter hasn't reached end, then 
                                    ; repeat: clear next entry in segment buffer
    ;JE      InitMuxVariables
    
InitMuxVariables:
    MOV     currentDispChar, 0		; Initialize current muxed digit  
    
EndInitDisplay:                     ; done initializing the display 
    RET                             ; return
InitDisplay     ENDP


;
; DisplayMux 
;
; Description: 		Multiplexer for the display. This procedure multiplexes
;					the LED display under interrupt control. It is meant to 
;					be called at a regular interval of about 1 ms. This  
;					function is going to display 1 digit for 1 instance. 
;	
; Operation: 		The multiplexer remembers which digit was called last,
;					by storing and updating the currentDispChar variable. Then it
;					writes the 14-segment code of the next digit to the
;					display at the current digit. One digit is output each time
;					this function is called. Here we assume that the LED display 
; 					base address is 00H. 
;
; Arguments:		None.
; Return Value:		None.
; Local Variables:	None.
; Shared Variables: currentDispChar (r/w) - number that keeps track of which digit 
;									is currently being displayed
;					charDispBuffer (r) - buffer holding 14-segment display code values
; 					scrollCnt (r/w) - counter that serves as a "max count" for 
; 						updating the scroll position
; 					stringLength (r) - length of string being displayed; determines 
; 						whether we need to scroll or not
; 					scrollPos (r/w) - current index in string that we start displaying 
; 						from (left side of display)
; Global Variables: None. 
; Input:			None. 
; Output:			The next digit is output to the display.  
; Error Handling:	None. 
; Algorithms:		None. 
; Data Structures: 	segment code buffer - array of bytes holding segment code values 
;

DisplayMux 			PROC	NEAR            
					PUBLIC	DisplayMux
	
StartDisplayMux:					 
    PUSHA                       		; save registers   
   
    CMP     stringLength, NUM_DIGITS    ; if string is longer than display,
                                        ; we need to scroll.
    JLE     ContinueAsRegular           ; otherwise, continue to display as usual.
    
    ;JG CheckUpdateScrollPos
CheckUpdateScrollPos: 	
    INC     scrollCnt                   ; update scroll count - number of muxes it 
                                        ; takes before we change scroll position
    CMP     scrollCnt, SCROLL_POS_MAX_COUNT             
										; determine if we've reached the designated 
										; scroll time (measured in function iterations)
    JE      UpdateScrollPos             ; update scroll position if reached max count
    JNE     ContinueAsRegular           ; if not, continue to display the string
                                        ; from current scroll position
    
UpdateScrollPos:                        ; reached scroll max count: update scroll 
										; position - character in string we start 
										; display from 
    MOV     scrollCnt, 0                ; reset scroll max count for counting in 
										; next scroll position
    INC     scrollPos                   ; increment scroll position to display 
										; next char in string as the first one 
    MOV    AX, stringLength             ; compare scroll position to string length 
    CMP    scrollPos, AX                ; if scroll position does not exceed string
										; length, display from current scroll position
    JLE    ContinueAsRegular			
     
    ; if greater scroll position > string length: 
										; that doesn't make sense -> wrap scroll
	MOV    	scrollPos, 0        		; position around to front (1st char in string)
             
    
ContinueAsRegular:    
    
    MOV     BX, currentDispChar			; move currently displayed character index 
										; into index register 
    ADD     BX, scrollPos   			; add index in the string to the scroll pos ->
										; index in the string (BX) is between 0 and 7, 
										; and is like an "offset" to the "base" index,
										; scrollPos. 
    SHL     BX, 1           			; multiply index by word size since each code
										; in charDispBuffer is 2 bytes = 1 word 
    MOV     AX, WORD PTR charDispBuffer[BX]
										; move segment code into AX 
    
    XCHG    AH, AL          			; AH becomes the AL, want to move upper code 
										; into higher port location 
    MOV     DX, HIGH_SEG_CODE_ADDRESS					
    OUT     DX, AL                      ; display character segment code, high byte 
    
    XCHG    AH, AL                      ; AL is restored, now we put the lower byte 
                                        ; into the lower address
    
    MOV     DX, currentDispChar         ; move address (index of character to display
                                        ; in the LED display row) into DX
    OUT     DX, AL                      ; output this segment pattern code into the
                                        ; lower byte address, also writes the high 
                                        ; byte segment pattern to same digit.
    
IncrementMuxCounter:			        ; set character index position at which the 
                                        ; next character will be muxed next time 
    MOV     BX, currentDispChar         ; increment currently displayed index 
    INC     BX                          
                ; we want to increment the currently displayed character variable 
                ; and then account for wraparound by the number of LED display digits:
    MOV     AX, BX                      ; move new index for next time to AX for 
                                        ; dividing 
    MOV 	DX, 0                       ; clear DX before division 
    MOV     CX, NUM_DIGITS              ; get (currentDispChar + 1) mod (number of segments)
	DIV     CX                  		; to account for mux counter wraparound
    MOV     currentDispChar, DX			; store next character to be displayed into var 
	
EndDisplayMux:
    POPA                        ; restore registers
	RET							; done multiplexing LEDs - return
	
DisplayMux 			ENDP



CODE    ENDS                                                                   





; the data segment 

DATA	SEGMENT	PUBLIC 	'DATA'


charDispBuffer		DW	 	DISPLAY_BUFFER_LENGTH 	DUP 	(?)	
	; buffer holding currently displayed pattern
	; holds words because 14-seg codes are words
currentDispChar		DW		?                   
	; current digit in display that will be muxed next

stringBuffer 		DB  	DISPLAY_BUFFER_LENGTH 	DUP 	(?)   
	; character array storing ASCII string that will soon be displayed 

; Scrolling variables

stringLength 	DW     	?       
	; length of string that is currently being displayed

scrollPos   	DW  	?    
	; position of current display (index in the string being displayed)

scrollCnt   	DW  	?     
	; counter keeping track of how many iterations of multiplexer to go through
	; before changing scroll position 
		
DATA	ENDS



END