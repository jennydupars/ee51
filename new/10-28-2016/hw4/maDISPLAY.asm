; Maitreyi Ashok
; Section 1 – Richard Lee

        NAME    DISPLAY

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   DISPLAY                                  ;
;                               DISPLAY Routines	                         ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 
; This file contains the display routines to convert from either numbers or strings
; to various segments being lit up on digits of the LED display accordingly. Supports
; blinking of the digits on the display as well as scrolling horizontally on the
; display, and multiplexes the digits of the 14 segment display at a rate of 1 KHz.
;
; Table of Contents:
; Display - Takes NULL terminated ASCII string and writes segment patterns to buffer
; DisplayNum - displays a 16 bit signed value in decimal representation
; DisplayHex - displays a 16 bit unsigned value in hexadecimal representation
; DigitMux - multiplexes, blinks, and scrolls the display
; InitDigitMux - initializes the necessary counters and buffers for display and
;				multiplexing
;
; Revision History:
; 10/24/2016	Maitreyi Ashok	Wrote basic outlines and functional specifications
;								for all functions.		  

$INCLUDE(DISPLAY.inc)

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA, STACK


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP, DS:DGROUP


        EXTRN   Dec2String:NEAR
        EXTRN   Hex2String:NEAR
        EXTRN   ASCIISegTable:NEAR
; Data Structures		
;		SegTable - This is a lookup table containing the 2 word segment bit
;				patterns for each of the ASCII characters in a 14 segment display. 
;				The characters that	can not be represented well are stored as
;				a blank LED pattern. This table can be accessed for quick conversion
;				from ASCII character to 2 byte segment pattern.
;		buffer - This buffer is an array of size bufferSize (48 bytes) that stores
;				the segment patterns that are found from the lookup table for each
;				digit. If this buffer is updated by the display functions, the 
;				multiplexing function can run through these segments in the buffer
;				to display each of the digits of the LED display.
;
; Display		
; Description: 		This function takes a null terminated ASCII format string 
;					and displays it to a 14 segment LED display. Thus, this 
;					string takes each character of the string and finds the 14 
;					segment	pattern from a table. Then the bit patterns for each 
;					of the segments that should be displayed for the digit are 
;					stored in a buffer. Thus, there is no actual output to the 
;					LED display but the buffer is updated so that the DigitMux 
;					routine will output the segments from the buffer periodically. 
;					If the string is not null terminated, this function will add
;					to the buffer until the buffer is full, so the segment patterns
;					in the buffer might be for characters that were not intended
;					to be in the string.
;					
; Operation:  		The function gets a null terminated string. It goes through
;					the string and looks at each of the ASCII characters until
;					it reaches a NULL character, which signifies the end of the
;					string, or the buffer is full, which means bufferSize/2 digits
;					have been displayed. The string contains output for status 
;					updates, error codes, or other messages for the RoboTrike) 
;					For each of the characters, the function converts it to a word
;					size bit pattern for a 14 segment pattern using a table of 14 
;					segment display options. This pattern is kept as an	active high 
;					signal, and is then	stored in the buffer of digits. Then, the 
;					new size of the buffer is stored, and the function adds the 
;					next digit to the buffer.
;
; Arguments:   		str [ES:SI] - null terminated string to output to display
; Return Value:		None
;
; Local Variables:	DoneFlag[CF]- stores whether we have reached the Null character
;					char[SI]- The current character from the string
;					segPattern[DX]- the segment pattern corresponding to the current char
;					bufferPtr[BP]- the pointer to the buffer of segment patterns
;					SegTable[BX] - pointer to the segment pattern table
;					digitCount[CX] - stores the position in the string we are at
; Shared Variables: buffer - the buffer with the segment patterns of all digits in
;								in the string
; Global Variables: None
;
; Input:			None
; Output:			The digits in the string passed in is output to a LED display
;								(by DigitMux)
;
; Error Handling:	None
;
; Algorithms:		None
; Data Structures:	The function uses a buffer, which is an array. It also uses
;					a look up table of segment patterns.
;
; Registers Changed: 
; Stack Depth:		
;
; Limitations:		This function fails and runs until the buffer is full if a
;					null termination character is not included. Thus, if the null
;					termination is omitted, garbage characters may be displayed. 
;					Also, if the string is longer than the size of the buffer (has
;					more characters than bufferSize/2), then the entire string 
;					will not be displayed, and the parts that will not fit will
;					be truncated. In addition, not all characters can be displayed 
;					using a 14 digit display. For example, an exclamation mark can 
;					not be used with a 14 digit display. 
;
; Author:			Maitreyi Ashok
; Last Modified:	10/24/16  Maitreyi Ashok	Wrote functional specification
;												and pseudocode for function
;					
; Operational Notes
; Go through each character of the string until reach NULL
; Look up segment pattern for the character
; Add the segment pattern to the buffer
; Increment buffer and move to next digit
; 
; Pseudocode
; Display(str)
;		bufferPtr = 0
;		Clear DoneFlag
;		WHILE NOT DoneFlag AND bufferPtr < bufferSize
;				char = byte at str[digitCount]
;				digitCount ++
;				IF char == NULL
;						Set DoneFlag
;				ELSE
;						segPattern = word at SegTable[char]
;						value at bufferPtr = segPattern
;						bufferPtr += 2   (each digit pattern is 2 bytes)
;						Clear DoneFlag
;				ENDIF
;		WHILE bufferPtr < bufferSize
;				value at bufferPtr = word at SegTable[Null]
;				bufferPtr += 2
;		ENDWHILE

Display	        PROC        NEAR
                PUBLIC      Display

SetUpDisplay:
		MOV		BP, 0			; Start buffer pointer from start of buffer
		MOV		CX, 0
		MOV     BX, OFFSET(ASCIISegTable)
		CLC						; Clear the carry flag when starting for checks
CheckDoneWithBuffer:
		JC		DoneWithString
		CMP		BP, bufferSize
		JGE		DoneWithString
		;JL		FindCharacter
		
FindCharacter:
		MOV		SI, [ES:SI+CX]
		INC		CX
		CMP		CX, NULLChar
		JNE		GetSegmentPattern
		;JE		ReachedNullTermination
ReachedNullTermination:
		STC
		JMP		MoveToNextCharacter
		
GetSegmentPattern:
		MOV		DX, [BX+SI]
		MOV		buffer[BP], DX
		ADD		BP, bufferElemSize
		CLC
MoveToNextCharacter:
		JMP 	CheckDoneWithBuffer
		
DoneWithString:
		CMP		BP, bufferSize
		JGE		BufferComplete
		;JL		AddNullPatterns
AddNullPatterns:
		MOV 	buffer[BP], SegmentsNull
		ADD		BP, bufferElemSize
		JMP		DoneWithString
		
BufferComplete:				
		RET
Display		ENDP

; DisplayNum	
; Description: 		This function gets a 16 bit signed value that it then converts
;					to the decimal ASCII representation with Null termination. The 
;					maximum number of digits in the ASCII string is 5 digits, plus 1 
;					digit for the negative sign if the high bit of the value is 1. 
;					Leading zeroes are included so that there at 5 numerical digits for
;					each 16 bit value. The ASCII sring is then displayed on the 14 
;					segment LED display, by writing the segment patterns for each
;					digit to a buffer. The segment patterns in this buffer will 
;					later be written to the display using multiplexing of the LEDs
;					for the digits. 					
;
; Operation:  		The 16 bit signed value is converted to a 5 digit ASCII string
;					(with sign if needed), using the Dec2String routine. This 
;					function divides by successive powers of 10 to get each 
;					individual digit. This is then converted to an ASCII character
;					and stored in a string buffer. When the 16 bit value has been
;					completely converted, the string buffer is passed to the 
;					Display function which finds the segment patterns for each
;					of the characters of the null terminated string representation
;					of the decimal value. Each segment pattern is 2 words, since
;					it has to include the bits for 14 segments of the display.
;					The segment patterns are then added in a buffer for each digit
;					to be displayed by the MuxDigit function.
;
; Arguments:   		num [AX] - 16 bit signed value to be output in decimal format
; Return Value:		None
;
; Local Variables:	None
; Shared Variables: stringAddr - The address of the buffer to store the ASCII string at 
; Global Variables: None
;
; Input:			None
; Output:			None
;
; Error Handling:	None
;
; Algorithms:		Uses algorithm in Dec2String to divide the number by 
;					successive powers of 10 to get each of the decimal digits
; Data Structures:	None
;
; Registers Changed: 
; Stack Depth:		
;
; Limitations:		This function can only display 16 bit signed values.
;
; Author:			Maitreyi Ashok
; Last Modified:	10/24/2016	Maitreyi Ashok		Wrote functional specification
;													and outline
;					
; Operational Notes
; Convert value to decimal string representation
; Add segment patterns of string to buffer
;
; Pseudocode
;
; DisplayNum(num)
;		addr = Dec2String(num, addr)
;		Display(addr)
; 

DisplayNum      PROC        NEAR
                PUBLIC      DisplayNum
GetASCIIStringOfNum:
        MOV     SI, OFFSET(stringAddr)
        CALL    Dec2String
        MOV     ES:SI, DS:SI
        CALL    Display
		RET
DisplayNum	ENDP

; DisplayHex		
; Description: 		This function gets a 16 bit unsigned value that it then converts
;					to the hexadecimal ASCII representation with Null termination. The 
;					maximum number of digits in the ASCII string is 5 digits. Leading
;					zeroes are included so that there at 5 numerical digits for
;					each 16 bit value. The ASCII sring is then displayed on the 14 
;					segment LED display, by writing the segment patterns for each
;					digit/letter to a buffer. The segment patterns in this buffer will 
;					later be written to the display using multiplexing of the LEDs
;					for the digits. 						
;
; Operation:  		The 16 bit unsigned value is converted to a 5 digit hexadecimal 
;					representation ASCII string, using the Hex2String routine. This 
;					function divides by successive powers of 16 to get each 
;					individual digit. This is then converted to an ASCII character
;					and stored in a string buffer. When the 16 bit value has been
;					completely converted, the string buffer is passed to the 
;					Display function which finds the segment patterns for each
;					of the characters of the null terminated string representation
;					of the hexadecimal value. Each segment pattern is 2 words, since
;					it has to include the bits for 14 segments of the display.
;					The segment patterns are then added in a buffer for each digit/
;					letter to be displayed by the MuxDigit function.
;
; Arguments:   		num - 16 bit unsigned value to be output in hexadecimal format
; Return Value:		None
;
; Local Variables:	addr - The address of the buffer to store the ASCII string at
; Shared Variables: None
; Global Variables: None
;
; Input:			None
; Output:			None
;
; Error Handling:	None
;
; Algorithms:		Uses algorithm in Hex2String to divide the number by 
;					successive powers of 16 to get each of the decimal digits
; Data Structures:	None
;
; Registers Changed: 
; Stack Depth:		
;
; Limitations:		This function can only display 16 bit unsigned values.
;
; Author:			Maitreyi Ashok
; Last Modified:	10/24/2016	Maitreyi Ashok		Wrote functional specification
;													and outline
;					
; Operational Notes
; Convert value to hexadecimal string representation
; Add segment patterns of string to buffer
;
; Pseudocode
;
; DisplayHex(n)
;		addr = Hex2String(n, addr)
;		Display(addr)
; 

DisplayHex      PROC        NEAR
                PUBLIC      DisplayHex
		MOV     SI, OFFSET(stringAddr)
        CALL    Hex2String
        ;MOV     ES:SI, SI
        CALL    Display
		RET		
		RET
DisplayHex	ENDP



; DigitMux		
; Description: 		This routine takes care of multiplexing the digits of the
;					LED display, and is called at a regular interval of once every
;					1 millisecond. At each interval, all the 14 segments of 
;					one of the 8 digits of the LED display are displayed. Then,
;					when the next timer interrupt occurs, the function starts
;					displaying the next digit to the right in the same manner.
;					When the rightmost digit is displayed, the multiplexing wraps
;					around and starts displaying the leftmost digit next. In 
;					addition, if the user decides that the display should blink,
;					then that argument is passed in, and all the digits of the 
;					display blink at a regular interval. In addition, if the scroll
;					left or right button is pressed on the keypad, those parameters
;					are passed in, and the display moves one digit to the left or
;					right, respectively. If the end of the display is reached in
;					either direction, and cannot be scrolled in that direction any
;					further, then the scrolling is ignored. Also, if both scrollLeft
;					and scrollRight are selected, then there will be know effect
;					unless scrolling in one direction is not possible (at end of
;					display), in which case we scroll in the direction that we
;					can scroll in.
;
; Operation:  		This function mainly multiplexes the digits, showing all the
;					14 segments of each digit simultaneously, and alternating
;					between the 8 possible digits at a high frequency (~1 KHz) so 
;					that the difference in display is not obvious. To do this, a
;					count of the current digit being displayed is kept. Every time
;					a timer event occurs and this function is called, the current
;					digit is displayed and then this digit counter is incremented
;					to show the next digit at the next timer interrupt. If the end of
;					the display is reached, then the  The current
;					digit is displaying by storing each byte of the segment pattern
;					at the I/O memory addresses corresponding to the LED display 
;					peripheral. In addition, if blinking is enabled, the multiplexed
;					LEDs are displayed for a portion of a total time interval, and for
;					the other portion of the time interval, the display is turned 
;					off. Also, if the scrolling buttons are pressed on the keypad,
;					that is specified as part of the arguments. Whatever is the scrolled
;					position is so far, characters in the buffer will be displayed
;					from that position. If we scroll left, one character extra at
;					the left and one less from the right will be displayed. If
;					we scroll right, one character extra at the right and one less
;					from the left will be displayed. This is done by incrementing
;					or decrementing the offset from the currentMuxDigit of the
;					digits that we display (by 2, because we require a word
;					for the segment patterns of digit in 14 segment displays).
;
; Arguments:   		blink - Whether we want the display to blink
;					scrollRight - whether we are scrolling right
;					scrollLeft - whether we are scrolling left
; Return Value:		None
;
; Local Variables:	pattern [AX] - The segment pattern from the buffer for a digit
;                   currDigit [SI] - store the current digit we are muxing
; Shared Variables: buffer - contains segment patterns of digits to display
;					scrollPos - the position from the first set of digits to
;								scroll to
;					blinkCount - how much time has passed since started displaying
;								digits in a blinking cycle
;					currMuxDigit - to determine which buffer digit to output
;								and then update to display the next digit after 1 ms
; Global Variables: None
;
; Input:			The user can click a button on the keypad to scroll left and
;								right on the LED display.							
; Output:			The next digit is output to the memory mapped LED display, or
;								scrolled as expected by the user
;							
; Error Handling:	None
;
; Algorithms:		None
; Data Structures:	A buffer array is used to store segment patterns
;
; Registers Changed: 
; Stack Depth:		
;
; Limitations:		The function does not allow for the user to adjust the frequency
;					of multiplexing the digits, or of how fast to blink	the digits. 
;					In addition, can only scroll from left to right and not up
;					and down.
;								
; Author:			Maitreyi Ashok
; Last Modified:	10/24/2016	Maitreyi Ashok		Wrote functional specification
;													and outline
;					
; Operational Notes
; Check if it is time to show things as part of blink cycle
; If it is, display the current digit of the multiplexed digits, scrolling
;	left or right from the current as needed. (each byte separately)
; Update the current muxing digits, wrapping as needed
; If it is not time to show things in the blink cycle, don't display
; Update the blinking count
; If scroll left or right is pressed, update the scroll position
;
; Pseudocode
;
; DigitMux(blink, scrollRight, scrollLeft)
;		IF blink == FALSE
;				blinkCount = 0
;		ENDIF
;		IF blinkCount < ShowDigitsTime
;				pattern = word at buffer[currMuxDigit + scrollPos]
;				LEDDisplay[currMuxDigit] = pattern low byte
;				LEDDisplay[currMuxDigit + extraSegOffset] = pattern high byte
;				currMuxDigit += 2
;				IF currMuxDigit == displaySize
;						currMuxDigit = 0
;				ENDIF
;		ELSE
;				LEDDisplay = off (for all digits)
;		ENDIF
;		blinkCount ++
;		blinkCount = blinkCount mod (ShowDigitsTime + DontShowDigitsTime)
;		IF scrollRight and scrollPos < bufferSize - 2
;				scrollPos += 2
;		ELSE IF scrollLeft and scrollPos >= 2
;				scrollPos -= 2
;		ENDIF
;			

DigitMux	    PROC        NEAR
                PUBLIC      DigitMux

MuxDigits:
        MOV     SI, currMuxDigit
		MOV		AX, buffer[2*SI]
		MOV		LEDDisplay[SI], AL
		MOV		LEDDisplay[SI + extraSegOffset], AH
SetUpForNextMux:
		ADD		currMuxDigit, bufferElemSize
		CMP		currMuxDigit, displaySize
		JNE		DoneMuxing
		;JE		WrapAroundMuxDigit
WrapAroundMuxDigit:
		MOV		currMuxDigit, 0
		;JMP	DoneMuxing
DoneMuxing:				
		RET
DigitMux	ENDP


; InitDigitMux		
; Description: 		This function sets up the multiplexing operations of the
;					LED display, namely what digit to show at each timer interval,
;					where to scroll to, and how long it has been in our blinking
;					operation so we know when to turn off the display in the
;					second phase of the blinking. Also, the buffer that holds 
;					segment patterns to display is cleared, so that no digits are
;					displayed initially.
;
; Operation:  		The multiplexing functionalities are set up by resetting all
;					the values of the counters involved with multiplexing. Majorly,
;					this is the counter that stores which of the 8 digits we are 
;					currently displaying in the LED display for the 1 ms time
;					interval. This counter is set to 0, so that we start out
;					displaying the leftmost digit. In addition, the scroll position
;					is reset to 0 so that we start out with the leftmost character
;					to display, but we can scroll right and left as needed. Also,
;					the blink count is reset to zero, so that we start out displaying
;					the digits, and after a fixed interval, we can stop displaying
;					the digits to implement a blinking feature. Also, the function
;					goes through every word of the buffer and sets it to the segment
;					pattern for the NULL character.
;
; Arguments:   		None
; Return Value:		None
;
; Local Variables:	bufferCount[CX] - position in buffer when setting all segment
;								patterns to zero initially
; Shared Variables: scrollPos - the position from the first set of digits to
;								scroll to
;					blinkCount - how much time has passed since started displaying
;								digits in a blinking cycle
;					currMuxDigit - to determine which buffer digit to output
;								and then update to display the next digit after 1 ms
;					buffer - contains segment patterns of digits to display. 
; Global Variables: None
;
; Input:			None
; Output:			None
;
; Error Handling:	None
;
; Algorithms:		None
; Data Structures:	Clears the array buffer for future use. It also uses
;					a look up table of segment patterns.
;
; Registers Changed: 
; Stack Depth:		
;
; Limitations:		This way of initializing does not allow for any LED pattern to
;					be displayed when setting up the display system.
;
; Author:			Maitreyi Ashok
; Last Modified:	10/24/2016	Maitreyi Ashok		Wrote functional specification
;													and outline
;					
; Operational Notes
; Set all shared variables to zero
; Clear each word of buffer
;
; Pseudocode
;
; InitDigitMux()
;		currMuxDigits = 0
;		blinkCount = 0
;		scrollPos = 0
;		FOR each word of buffer
;			word = SegmentsNull[NULL]
; 

InitDigitMux    PROC        NEAR
                PUBLIC      InitDigitMux
StartWithFirstLED:
		MOV		currMuxDigit, 0
		MOV		CX, 0
CheckPositionInBuffer:
		CMP		CX, bufferSize
		JGE		DoneInitializing
		;JL		SetBufferZero
SetBufferZero:
		MOV		WORD PTR [buffer].CX, SegmentsNull
		ADD		CX, bufferElemSize
DoneInitializing:
		RET
InitDigitMux	ENDP




CODE    ENDS




;the data segment

DATA    SEGMENT PUBLIC  'DATA'

currMuxDigit   DB    ?                  ;which digit of the 8 we are displaying
; blinkCount = ?, how far we are from start of blink cycle
; scrollPos = ?, how far we have scrolled from the start so far
buffer         DW    bufferSize DUP (?) ;array of bufferSize bytes to store segment 
                                        ;patterns of digits to display
stringAddr     DB    ConvertsSize   DUP (?)

DATA    ENDS




;the stack

STACK   SEGMENT STACK  'STACK'

                DB      80 DUP ('Stack ')       ;240 words

TopOfStack      LABEL   WORD

STACK   ENDS

        END