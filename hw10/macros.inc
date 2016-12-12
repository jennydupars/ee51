
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  MACROS.INC                                ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains generally useful macros for the 80186/80188.  The macros
; included are:
;   CLR(reg) - clears a register reg 
; 	SETBIT(reg, bit) - sets a bit #bit in the register reg 
;	CLRBIT(reg, bit) - clears a bit #bit in the register reg 
; 	COMBIT(reg, bit) - complements the #bit bit in the reg register  
; 	TESTBIT(reg, bit) - sets the zero flag based on bit #bit in register reg 
; 	XLATW - the XLAT command can be used on word-tables 
; 	READPCB(addr) - read the PCB register at address addr and return value in AX
; 	WRITEPCB(addr, val) - writes the 16-bit value val to PCB register at address addr

; Revision History
;    11/18/2016  Jennifer Du         initial revision


; CLR                                                                                       
;
; Description:      This macro generates code to clear a register, which is
; 					passed in as reg. 
;
; Operation:        The macro argument, a register value, is XORed with itself
;                   to clear all bits 
;
; Arguments:        reg - register to be cleared. 
;
; Registers Used:   AX
; Stack Depth:      0 words
;


%*DEFINE(CLR(reg))   (
	XOR 	%reg, %reg		; clear by resetting all bits  
)



; SETBIT                                                                             
;
; Description:      This macro generates code to set a bit in a register.
;
; Operation:        We shift a single set bit left by the passed number of bits 
; 					to create a set bit at the #bit position. Then we OR this 
; 					with the register, to set that bit. 
;
; Arguments:        bit - the bit number that we are trying to set. 
;                   reg - register containing bit we are setting. 
;
; Registers Used:   None.
; Stack Depth:      0 words
;

%*DEFINE(SETBIT(reg, bit))   ( 
	OR  %reg, 1 SHL %bit 
)



; CLRBIT 
;
; Description:      This macro generates code to clear a bit in a register.
;
; Operation:        First, we set the specified bit in the register, and thsen
; 					invert it. Finally, ANDing this with the register value will 
;                   cause all bits to be preserved, except for the specified one.
;
; Arguments:        bit - the bit number that we are trying to clear. 
;                   reg - register containing bit we are resetting. 
;
; Registers Used:   None. 
; Stack Depth:      0 words
;

%*DEFINE(CLRBIT(reg, bit))   (
    AND     %reg, NOT(1 SHL %bit)
	
)




; COMBIT 
;
; Description:      This macro generates code to complement a bit in a register.
;
; Operation:        The XOR instruction preserves a bit if the main bit is XOR'ed 
; 					with a 1, and flips the bit if the main bit is XOR'ed with 0. 
; 					Thus, to complement a bit in the given register, we will XOR 
; 					the register value with a value with all bits set except 
; 					the specified one. 
;
; Arguments:        bit - the bit number that we are trying to get the complement of. 
;                   reg - register containing bit we are setting. 
;
; Registers Used:    
; Stack Depth:      0 words
;

%*DEFINE(COMBIT(reg, bit))   (
	XOR     %reg, NOT (1 SHL %bit)
)



; TESTBIT 
;
; Description:      This macro generates code to test a bit in a register.
;
; Operation:        We shift a single set bit left by the passed number of bits 
; 					to create a set bit at the #bit position. Then we TEST this 
; 					with the register, to see if that bit is set or not. If the
; 					bit is zero, the zero flag will be set. If the bit is not set, 
; 					then the zero flag will be reset. 
;
; Arguments:        bit - the bit number that we are trying to test. 
;                   reg - register containing bit we are setting. 
;
; Registers Used:   None.
; Stack Depth:      0 words
;

%*DEFINE(TESTBIT(reg, bit))   (
   TEST     %reg, 1 SHL %bit 
)


; XLATW
;
; Description:      This macro's function is the XLAT instruction, but for looking 
; 					up values in tables whose elements are words. 
;
; Operation:        This function first takes the offset of the table, given by BX.
; 					Then we will move the value at address AX into AX. 
;
; Arguments:        AX - index of desired element in table 
; 					BX - address of table (with CS offset)
; 					
;
; Registers Used:   AX, BX, CX, DX, flags 
; Stack Depth:      0 words
;

%*DEFINE(XLATW())   (

    SHL 	AX, 1 		; multiply index by 2 (bytes) since each entry is word-sized
    ADD     BX, AX
    MOV     AL, CS:[BX]
    INC     BX
    MOV     AH, CS:[BX]
	
)


; READPCB  
;
; Description:      This macro reads the PCB register at value addr, and writes
; 					the value of that register to AX. 
;
; Operation:        We output the register's value to AX. 
;
; Arguments:        addr - address of PCB register to read and return value of
;                   
; Registers Used:   AX - value of desired PCB register 
; 					DX - address of PCB register (PCB base + register offset)
; Stack Depth:      0 words
;

%*DEFINE(READPCB(addr))   (
	MOV 	DX, %addr 
	IN 		AX, DX 		; get value in AX    
)


; WRITEPCB 
;
; Description:      Writes the 16-bit value val to the PCB register at address addr.
;
; Operation:        We move the value val to the AX register and the address addr to
; 					the DX register. Then, we can use the OUT instruction to write 
; 					the specificed value to that PCB register. 
;
; Arguments:        addr - address of PCB register to write to 
; 					val - value to write 
;
; Registers Used:   AX - holds the 16-bit value to be written to the PCB register 
; 					DX - holds the address of the PCB register 
; Stack Depth:      0 words
;

%*DEFINE(WRITEPCB(addr, val))   (
	MOV 	DX, %addr
	MOV 	AX, %val 
	OUT 	DX, AX 
   
)
