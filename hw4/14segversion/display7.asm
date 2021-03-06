	NAME		DISPLAY

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;								    DISPLAY                                  ;
;                           	   Homework 4        		                 ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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



;external function declarations
    
        EXTRN   Hex2String:NEAR 	; converts number to hexstring
		EXTRN 	Dec2String:NEAR		; converts number to decstring
        
        EXTRN   ASCIISegTable:BYTE  ; 14-segment codes for segment buffer 
		
		

; include files
$INCLUDE(display.inc)
$INCLUDE(common.inc)
$INCLUDE(converts.inc)



CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP, SS:STACK

		
; Display 
;
; Description: 		This function converts an ASCII string into the 
;					series of 14-segment codes that, when ported to the LED 
;					display, forms a visual representation of that string. 
;					The function is passed a <null> terminated string (str) to
;					output to the LED display. The string is passed by 
;					reference in ES:SI (i.e. the address of the string is 
;					ES:SI). The maximum length of the string that can be 
;					displayed at any given moment is 8 characters long. The 
;                   maximum length of a string that can be displayed is 64 
;                   characters. The 8-character display will be able to scroll
;                   through the string, 8 characters at a time.
;
; Operation: 		This function will loop through the given string, and look 
;					up the 14 segment code for each character in the 14-segment 
;					code table. Then it will write the value of the 14 segment 
; 					code to the buffer in the order that the characters appear. 
;                   If the string is shorter than the length of the segment 
;                   buffer, the buffer will be padded with blank spaces. If the 
;                   string is longer than the length of the segment buffer, it 
;                   will be cut off at the maximum length, 64 characters.  
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
                                        
                                        
Display         PROC    NEAR
                PUBLIC  Display
                
StartDisplay:
    PUSHA
    
    PUSH    ES              ; get the string from ES:SI to DS:SI
    POP     DS                          
    
    MOV     CX, 0           ; initialize counter for the segbuffer
    
CheckEndOfString:
    XOR     AX,AX					; clear AX
    MOV     AL, DS:[SI]            ; get value of the first character in the string 
	INC     SI                          ; move to next character in string
    CMP     AL, ASCII_NULL            ; see if the string has ended (see if the current character is euqal to ASCII_NULL)                        
    JE      EndOfString					; if =, jump to end of the string 
    ;JMP     CheckEndOfBuffer           ; then see if buffer capacity has been reached
    ;JMP    StoreSegTableValue
    
StoreSegTableValue:
            
    
    MOV     BX, OFFSET(ASCIISegTable)
	XLAT	
	
    ADD     CX,BYTESIZE
    CMP     CX, numSegs                 ; if we have reached capacity of the segment buffer, they'd be equal
    JL      CheckEndOfString          ; not equal! -> store more segment table values
    JGE     EndDisplay                  ; >= means we end this function, buffer can't fit more
    
    
    ;JMP     CheckEndOfString           ; after every increment in the string pointer, see
                                        ; if we have reached the end of the string.

CheckEndOfBuffer:
    
    

EndOfString:
    
    MOV     BX, CX      
    
    MOV     segBuffer[BX], ASCII_NULL   ; store null string in each entry in 
                                        ; segment buffer
    ADD     CX, BYTESIZE
    ;JMP     CheckEndOfBufferAfterString
    
CheckEndOfBufferAfterString:            ; string is done and we are checking if buffer
                                        ; capacity has been reached
    CMP     CX, numSegs
    JL      EndOfString                 ; buffer capacity not reached: add more spaces
    ;JGE     EndDisplay
    
EndDisplay:
    POPA
    RET                     ; we are done, return
    
    
Display ENDP
    
;		
;
; DisplayNum 
;
; Description: 		This function turns a given number into its decimal 
;					representation and gets it ready to be displayed on the 
;					LED display. The function is passed a 16-bit signed value 
;					(n) to output in decimal (at most 5 digits plus sign) to 
;					the LED display. The number (n) is passed in AX by value. 
;                   The resulting string is written to DS:SI.
;
; Operation: 		We will use two previously written functions to 
;					display a number in decimal. First, we will turn the given
;					number into a string in decimal form using Dec2String, and
;					then we will call Display on this string to show it 
;					on the LED display.
;
; Arguments: 		AX - 16-bit signed value to be turned into a decimal string
; Return Value: 	None.
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

DisplayNum      PROC    NEAR
                PUBLIC  DisplayNum
    PUSHA
    MOV     SI, OFFSET(stringBuffer) ; DS:SI should point to stringBuffer, set this 
                                        ; up so Dec2String can write string there.
    PUSH    DS
    POP     ES
	CALL    Dec2String				; turns number to decimal string 
    
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
;					output in hexadecimal (at most 4 digits) to the LED 
;					display. The number (n) is passed in AX by value. 
;                   The resulting string is written to DS:SI.
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
DisplayHex      PROC    NEAR
                PUBLIC  DisplayHex

    MOV     SI, OFFSET(stringBuffer)    ; set address of SI up so that Hex2String
                                            ; can write the string here
	PUSH    DS
    POP     ES
    CALL    Hex2String		; converts number to hex string 
    CALL    Display 		; displays string on LED display 
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
; Shared Variables: currentSeg - keeps track of next digit for mux 
;					segBuffer  - buffer is filled with DISPLAY_BLANK
; Global Variables: None. 
; Input:			None. 
; Output:			The LED display is blanked.
; Error Handling:	None.
; Algorithms:		None.
; Data Structures: 	None.
;


InitMDisplay     PROC    NEAR
                PUBLIC  InitMDisplay


StartInitDisplay:                   
    PUSHA                           ; save registers
    
    MOV     BX, 0                   ; start counter at 0 (this counter loops 
                                    ; segment buffer and clears each entry)
                                    
    MOV     DX, IO_LED_LOC          ; get I/O location of LED display 
    MOV     AL, IO_LED_VAL          ; get I/O value to write to IO_LED_LOC 
    OUT     DX, AL                  ; write 0 to I/O location 0FFA4H for display chip select logic

ClearDisplay:                       ;start clearing the display
    MOV     CX, numSegs             ;number of segments to clear
    MOV     segBuffer[BX], LED_BLANK   ; move blank character into each 
                                            ; segBuffer entry
    INC     BX                      ; increment counter
    CMP     BX,numSegs              ; compare counter to 8 (number of segments)
    JNE     ClearDisplay            ; if the counter hasn't reached 8, then 
                                    ; clear next entry in segment buffer
    ;JE      InitMuxVariables
    
InitMuxVariables:
    MOV     currentSeg, 0			; Initialize current mux segment 
   ; MOV     scrollPos, 0            ; Initialize scroll position (starts off 
                                    ; with very first character in string)
    ;JMP    EndInitDisplay          ;all done now
    
EndInitDisplay:                         ;done initializing the display 
    POPA                            ; restore registers and
    RET                             ; return


InitMDisplay     ENDP


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
; Shared Variables: currentSeg - number that keeps track of which digit is
;									being displayed
;					buffer 	   - segment buffer holding segment code values 
; Global Variables: None. 
; Input:			None. 
; Output:			The next digit is output to the display.  
; Error Handling:	None. 
; Algorithms:		None. 
; Data Structures: 	segment buffer - array of bytes holding segment code values 
;



DisplayMux 			PROC	NEAR            
					PUBLIC	DisplayMux
	
StartDisplayMux:					 
    PUSHA                       ; store registers   
   
    ; we want to see if currentSeg is even or odd
    
    MOV     BX, currentSeg
    MOV     AL, BYTE PTR segBuffer[BX]
    
	MOV 	DX, currentSeg 	; find address to port to 
	OUT 	DX, AL 
    
IncrementMuxCounter:			; set number to mux next time 
    INC     BX
    CMP     BX, 0008H
    JL      EndDisplayMux
   
   ; else
    SUB     BX, 0008H
    MOV     currentSeg, BX
	
EndDisplayMux:
    POPA                        ; restore registers
	RET							; done multiplexing LEDs - return
	

DisplayMux 			ENDP



CODE    ENDS                                                                   





; the data segment 

DATA	SEGMENT	PUBLIC 	'DATA'

segBuffer	DB	 numSegs DUP (?)	; buffer holding currently displayed pattern
									; holds words because 14-seg codes are words
currentSeg	DW	?                   ; current segment of digit to be muxed next

stringBuffer DB  numSegsBytes DUP (?)   ; character array 
		
DATA	ENDS



;the stack

STACK   SEGMENT STACK  'STACK'

        DB      80 DUP ('Stack ')       ;240 words

        TopOfStack      LABEL   WORD

STACK   ENDS

END