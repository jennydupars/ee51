	NAME 	QUIZ5

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;  			     	      Extra Credit Quiz Functions                        ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains miscellaneous functions, as specified by the functions listed
; on the extra credit quiz. Included functions are: 
; 	AbsoluteValue - returns absolute value of a signed 16-bit number 
; 	SgnFunction - returns the sgn function of a signed 16-bit number 
; 	PowerOf2 - determines if an unsigned 16-bit number is a power of 2 
;  	Sine - computes the sine of an angle given an integer number representing degrees
;

; Revision History:
;    11/29/2016         Jennifer Du     initial revision
;

CGROUP	GROUP	CODE
DGROUP	GROUP	DATA

CODE SEGMENT PUBLIC 'CODE'

		ASSUME	CS:CGROUP, DS:DGROUP
	
	

;
;
; AbsoluteValue 
;
;
; Description:  	This function computes the absolute value of the given argument,
; 					as passed in AX.
; 
; Operation:    	First we use the instruction CWD, which gives us -1 in DX if the
; 					passed value is negative, and 0 in DX if the passed value is 
; 					nonnegative. Then, we OR this with the value of 1, to convert 
; 					-1 to -1 and 0 to 1. Then, we multiply the updated multipliers 
; 					by the original argument. If AX is negative, we would be 
; 					multiplying by a negative value, and if AX is positive, we would
; 					be multiplying by a positive value. This results in the absolute
; 					value of AX. 
; 
; Arguments:        AX - 16-bit signed value. 
; Return Value:     AX - 16-bit absolute value of argument.
;
; Local Variables:  None. 
; Shared Variables: None.
; Global Variables:	None.
; 
; Input:            None.
; Output:           None.
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  None.


AbsoluteValue 		PROC 	NEAR 
								; if high bit is set: AX negative, else: AX positive
	CWD								; if AX is negative, DX = 1111111111111111 = -1D
									; if AX nonnegative, DX = 0000000000000000 = 0D
	
								; set the low bit no matter what 			
	OR	 	DX, 0000000000000001	; if AX is negative, DX = 1111111111111111 = -1D
									; if AX nonnegative, DX = 0000000000000001 = 1D

	IMUL 	AX, AX, DX  		; either multiply original number by -1 or 1 
									; if AX negative, multiply by DX = -1 -> abs(AX)
									; if AX positive, multiply by DX = 1 -> abs(AX)
	
AbsoluteValue 		ENDP 




;
;
; SgnFunction
;
;
; Description:  	This function computes the sgn function of a 16-bit signed value
; 					as passed in AX. The sgn function returns -1 if AX is less than 
; 					0, 0 if AX is 0, and 1 if AX is greater than 0. 
; 			
; 
; Operation:    	
; 
; Arguments:        AX - 16-bit signed value. 
; Return Value:     DX - 16-bit sgn function of argument.
;
; Local Variables:  None. 
; Shared Variables: None.
; Global Variables:	None.
; 
; Input:            None.
; Output:           None.
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  None.


SgnFunction 		PROC 	NEAR 
								; if high bit is set: AX negative, else: AX positive
	CWD									; if AX is negative, DX = 1111 1111 1111 1111
										; if AX nonnegative, DX = 0000 0000 0000 0000
	
								; set the low bit no matter what 			
	OR	 	DX, 0000 0000 0000 0001		; if AX is negative, DX = 1111 1111 1111 1111
										; if AX nonnegative, DX = 0000 0000 0000 0001

								; separate into the 3 cases 
	AND 	DX, AX 						; if AX is negative, 
	
	
SgnFunction 		ENDP 

if AX is -1: 			DX = 1111 1111 1111 1111 
if AX is positive or 0: DX = 0000 0000 0000 0000 
	; -1 is 1111 1111 1111 1111 
	;  0 is 0000 0000 0000 0000 
	;  1 is 0000 0000 0000 0001
	
	
;
;
; PowerOf2
;
;
; Description:  	This function determines whether the 16-bit unsigned value
; 					passed in through AX is a power of 2, and sets the zero flag
; 					accordingly. 
; 
; Operation:    	If a number is a power of 2, then exactly 1 bit is set in its
; 					binary representation. 
; 
; Arguments:        AX - 16-bit unsigned value. 
; Return Value:     ZF - set if AX is a power of 2, reset if not.
;
; Local Variables:  None. 
; Shared Variables: None.
; Global Variables:	None.
; 
; Input:            None.
; Output:           None.
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  None.


PowerOf2 		PROC 	NEAR 
	

	MOV 	CX, AX
	SUB 	CX, 1
	AND 	CX, AX 
	
	MOV 	CX, AX 		; save input value 
	AND 	AX, AX - 1	; AND with one less than it: powers of 2 and also zero will
						; become zero, (since zeros become ones between AX and AX-1
						; if AX is a power of 2 or zero) ex. 0000 -> 1111, and AND 
						; will result in 0000. 0100 -> 0011, and AND will result in 
						; 0000. However, 0110 -> 0100, and AND will result in 0100, 
						; a non-zero value. 
	NOT 	AX 			; NOT AX will result in 1111 for all powers of two and zero, 
						; and the bitwise opposite for all other numbers. 
	AND 	AX, CX 		; using AND with the original value of AX will differentiate 
						; 0 from the group of powers of 2. All numbers other than 0 
						; or the power of two will become 0000 after this, because 
						; for those numbers, AX has become the bitwise complement of 
						; the original AX. AND for 0 will also result in 0000. But 
						; for powers of 2, AND will result in a non-zero value. 
						; 
	
	
	
	
	
	
	
	
		1000 0000 
		1111 1111 
		0111 1111 
		
		0000 0000 
		1111 1111
		1111 1111 
		AND 	1000 0000 
				0111 1111
		AND	 	1000 0000 
				0111 1111 
		AND 	0000 0000 
				1111 1111 
PowerOf2 		ENDP 
	
	
	
	
;
;
; Sine
;
;
; Description:  	This function computes the sine of the given argument,
; 					as passed in AX.
; 
; Operation:    	
; 
; Arguments:        AX - integer angle to compute sine of.
; Return Value:     BX - the sine of AX in Q0.15.
;
; Local Variables:  None. 
; Shared Variables: None.
; Global Variables:	None.
; 
; Input:            None.
; Output:           None.
;
; Error Handling: 	None. 
;
; Algorithms: 		None. 
; Data Structures:  None.

; Since the sine of any angle between 0 and 180 is going to be positive, it is the same as the sine of its complement.
; Similarly, the sine of angles under the x-axis is going to be negative, like the the value minus 180, to get it 
; between 180 and 0. Then you take the complement or it to get it between 0 and 90, so you can get teh sine value.
; and then make it negative for values 180-359.


Sine 		PROC 	NEAR 
	

Sine 		ENDP 

CODE 	ENDS
	
END