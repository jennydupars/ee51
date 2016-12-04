   NAME     CONVERTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   CONVERTS                                 ;
;                             Conversion Functions                           ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; This file holds the two convert functions: Dec2String, and Hex2String. 
;
; Revision History:
;     10/10/16    Jennifer Du     initial revision
;     10/13/16    Jennifer Du     writing assembly code 
;     10/16/16    Jennifer Du     touching up comments

$INCLUDE(converts.inc)

CGROUP   GROUP    CODE

CODE     SEGMENT  PUBLIC 'CODE'

         ASSUME   CS:CGROUP

; Dec2String
;
; Description:       This function converts the 16-bit number n to a string 
;                    containing its decimal representation stored at a. The 
;                    function is passed a 16-bit signed value (n) to convert 
;                    to decimal, and store as a string. The string will 
;                    contain the <null> terminated decimal representation of 
;                    the value in ASCII. The resulting string is stored 
;                    starting at the memory location indicated by the passed 
;                    address (a). The number (n) is passed in AX by value. The 
;                    address (a) is passed in SI by value.
;
; Operation:         Divide by successive powers of 10(decimal) to get decimal 
;                    representation. Negative numbers are detected and turned 
;                    into their two's complement first.
;
; Arguments:         AX - binary value to convert to decimal.
;                    SI - address location to store result.
;
; Return Value:      SI - address location to store result.
;
; Local Variables:   AX - binary value to convert to decimal.
;                    SI - string location.
;                    BX - pointer to determine highest power of 10 < AX
;                    CX - powers of ten that AX is divided by
;                    DX - remainder after dividing AX by powers of 10.
;
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        Repeatedly divide by powers of 10 and repeat for 
;                    remainders. Then turn quotients into digits and 
;                    add necessary negative signs.
;
; Data Structures:   None.
;
; Known Bugs:        None.
;
; Registers Changed: AX, BX, SI, CX, DX
; Stack Depth:       0
;


Dec2String     PROC     NEAR
               PUBLIC   Dec2String

Dec2StringInit:
    MOV      BX, 5         ; set counter to 5 (will divide input 5 times) since max is 5 digits 
    MOV      DX, 0            ; make DX 0 initially
   
GetSignOfNumber:

    MOV     DX, AX          ; save AX 
    OR      AX, AX          ; OR to find set bits -> if first bit is set, Sign flag gets set
    JS      IfNegative      ; if sign flag set 
    MOV     AX, DX          ; restore argument 
    JMP     ConvertPart
    ; MOV     DX, AX            ; save AX before you find sign
    ; AND     AX, TEST1STBIT         ; get first bit
   ; CMP AX,TEST1STBIT         ; test if first bit =1 or =0
   ; JZ ifNegative        ; if =1, number is negative
   ; MOV AX,DX            ; move input value back into AX

IfNegative:
   MOV AX,DX            ; move value back into AX
   MOV BYTE PTR[SI],ASCIIdash  ;move the char into string place
   INC SI               ; increment pointer by a byte's space
   NEG AX               ; negate binary of AX
   JMP ConvertPart      ; then just convert it
   
   
; CheckIterationOfDividing: 
    ; PUSH    BX      
; ConvertPart: 
    ; MOV     DX, 0 
    ; MOV     CX, 10 
    ; DIV     CX 
    ; DEC     BX 
    ; CMP     BX, 1
    ; JE      addDigit 
    ; JNE     ConvertPart 
    
   ; convertpart: 
        ; if b = 4, divide by 1000
        ; if b = 3, divide by 100
        ; if b = 2, divide by 10
        ; if b = 1, 
   
ConvertPart:
   MOV DX,0            ; clear DX again so DIV can work
                        
   CMP BX,bFOUR         ; if 2nd iteration (BX=4),
   JZ divide10to3          ; divide AX by 1000
   CMP BX,bTHREE        ; if 3rd iteration (BX=3), 
   JZ divide10to2          ; divide by 100
   CMP BX,bTWO          ; if 4th iteration (BX=2),   
   JZ divide10to1          ; divide by 10
   CMP BX,bONE          ; if 5th iteration (BX=1),
   JZ divide10to0          ; divide by 1

divide10to4:
   MOV CX,TENto4        ; get ready to divide AX by 10000
   DIV CX               ; divide AX by 10000 
   JMP addDigit         ; then add digit to string

divide10to3:
   MOV CX,TENto3        ; get ready to divide by 1000
   DIV CX               ; divide number by 1000 
   JMP addDigit         ; then add digit to string

divide10to2:
   MOV CX,TENto2        ; get ready to divide by 1000
   DIV CX               ; divide number by 100 
   JMP addDigit         ; then add digit to string

divide10to1:
   MOV CX,TENto1        ; get ready to divide by 10
   DIV CX               ; divide number by 10 
   JMP addDigit         ; then add digit to string

divide10to0:
   JMP addDigit         ; (divide by 1) then add digit to string

addDigit:
    ;POP     BX          ; restore counter 
   ADD AX,ASCII0        ; add '0' to get ascii value of quotient AX
   MOV BYTE PTR[SI],AL  ; add ascii(AX) to string
   INC SI               ; increment SI pointer by a word's space
   MOV AX,DX            ; move remainder from previous division into AX
   DEC BX               ; decrement BX (counter)
   CMP BX,0             ; are we at the end? (eval BX == 0)
   JZ dec2StringAddNull ; if (BX==0) then we add null char
   JMP ConvertPart      ; otherwise convert next digit

dec2StringAddNull:
   MOV BYTE PTR[SI],NULL ;end the string with <null>
   RET
Dec2String     ENDP




; Hex2String
;
; Description:       This function converts the 16-bit number n to a string 
;                    containing its hexadecimal representation stored at a. 
;                    The function is passed a 16-bit unsigned value (n) to 
;                    convert to hexadecimal and store as a string. The string 
;                    will contain the <null> terminated hexadecimal 
;                    representation of the value in ASCII. The resulting 
;                    string is stored starting at the memory location 
;                    indicated by the passed address (a). The number (n) is 
;                    passed in AX by value. The address (a) is passed in SI by 
;                    value.
;
; Operation:         The function selects the first, then the second, etc 
;                    groups of 4 digits using the AND operation. Then the 
;                    corresponding ASCII character is found and added to the
;                    string.
;
; Arguments:         AX - binary value to convert to hexadecimal.
;                    SI - address to store result at.
; Return Value:      SI - address to store result at.
;
; Local Variables:   AX - binary value to convert to hexadecimal.
;                    SI - address to store result at.
;                    BX - counter to repeat process 4 times.
;                    CX - temporary storage for AX's bits, removing 4 at a time
;
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        Divide the number into 4 4-bit parts and match them with 
;                    corresponding ASCII value.
; Data Structures:   None.
;
; Registers Changed: AX, BX, SI, CX
; Stack Depth:       0
;


Hex2String     PROC     NEAR
               PUBLIC   Hex2String

hex2StringInit:
   MOV BX,0             ; set counter to 0
   MOV CX,AX            ; save AX

startOver:
   AND AX,FIRST4BITS    ; get first 4 digits, which goes to AX
   SHR AX, 12
   CMP AX,TEN           ; compare digits to ten
   JGE greaterThanTen   ; if >= 10, jump to more than 10

lessThanTen:            ; if four bits is less than 10
   ADD AX,ASCII0        ; add the value to ascii value for 0
   MOV BYTE PTR[SI],AL  ; move the char into string place
   INC SI               ; increment pointer 
   MOV AX,CX            ; move number back into AX
   SHL AX,FOURBITS      ; shift bits left to remove first 4
   MOV CX,AX            ; move lower bits to CX
   INC BX               ; add one to the counter
   CMP BX,bFOUR         ; stop when you've done it 4 times
   JZ hex2StringAddNull     ; If BX=4 you end.
   JMP startOver        ; do this process again if BX != 4

greaterThanTen:         ; if we need an ABCDEF (greater than 10)
   SUB AX,TEN           ; AX = AX - 10
   ADD AX,ASCIIa        ; AX + ASCIIa
   MOV BYTE PTR[SI],AL  ; move AX's character into string
   INC SI               ; increment pointer 
   MOV AX,CX            ; move number back into AX
   SHL AX,FOURBITS      ; shift bits left to remove first 4
   MOV CX,AX            ; save AX in CX
   INC BX               ; increment BX
   CMP BX,bFOUR         ; have we done this 4 times?
   JZ hex2StringAddNull     ; if BX=4 you end.
   JMP startOver        ; do this process again if BX != 4

hex2StringAddNull:
   MOV BYTE PTR[SI],NULL ;end the string with <null>
   RET
Hex2String     ENDP

CODE     ENDS

END