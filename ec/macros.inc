$NOLIST 				

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
; Operation:        The macro argument, a register value, is set to 0 to reset 
; 					all bits. 
;
; Arguments:        reg - register to be cleared. 
;
; Registers Used:   AX
; Stack Depth:      0 words
;


%*DEFINE(CLR(reg))   (
	MOV 	%reg, 0000H 		; clear by resetting all bits  
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

%*DEFINE(SETBIT(reg, bit))   ( //////////////////////////////////////////////////////////// CMP %reg, SHL(1,%bit)
	OR %reg, 1 SHL %bit 
)



; CLRBIT 
;
; Description:      This macro generates code to clear a bit in a register.
;
; Operation:        First, we set the specified bit in the register, and then
; 					XOR that with the set bit to clear just the specified bit.
;
; Arguments:        bit - the bit number that we are trying to clear. 
;                   reg - register containing bit we are resetting. 
;
; Registers Used:   None. 
; Stack Depth:      0 words
;

%*DEFINE(CLRBIT(reg, bit))   (
	XOR (OR %reg, 1 SHL %bit), SHL(1,%bit)		; we set the specified bit in the
											; register, and XOR that with the set bit
)

%*DEFINE(CLRBIT(reg, bit)) LOCAL SETBIT 	(
	XOR SETBIT(%reg, %bit), 1 SHL %bit 
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
	XOR (%reg, NOT SHL(1, %bit))
)



; TESTBIT 
;
; Description:      This macro generates code to test a bit in a register.
;
; Operation:        We shift a single set bit left by the passed number of bits 
; 					to create a set bit at the #bit position. Then we TEST this 
; 					with the register, to see if that bit is set or not. If the
; 					bit is zero, the zero flag will be reset. If the bit is set, 
; 					then the zero flag will be set. 
;
; Arguments:        bit - the bit number that we are trying to test. 
;                   reg - register containing bit we are setting. 
;
; Registers Used:   None.
; Stack Depth:      0 words
;

%*DEFINE(TESTBIT(reg, bit))   (
   TEST %reg, 1 SHL %bit 
)


; XLATW
;
; Description:      This macro's function is the XLAT instruction, but for looking 
; 					up values in tables whose elements are words. 
;
; Operation:        This function first sees if there is a segment override attemped
; 					here. If it is, then we will go to the specified segment, as 
; 					passed by DX, and then to the offset of the table, given by BX.
; 					Then we will move the value into AX byte by byte, incrementing 
; 					the index of the desired element in between, so that we can 
; 					access the two different bytes that comprise the word-sized 
; 					entry. If no segment override is attempted, then the register CX
; 					will be cleared and we will proceed with this procedure in the 
; 					data segment. 
;
; Arguments:        AX - index of desired element in table 
; 					BX - address of table (with DS offset)
; 					CX - toggles segment override (0 means no segment override
; 						 and 1 means segment override address is stored in DX)
;	 				DX - (optional) the address of the segment override 
;
; Registers Used:   AX, BX, CX, DX, flags 
; Stack Depth:      0 words
;

%*DEFINE(XLATW())   (
	CMP 	CX, 1 
	JE 		SegmentOverride
	JNE 	DefaultSegment
	
	MOV 	CX, BX 		; store table address in CX  
	MOV 	BX, AX 		; store index in BX
	SHL 	BX, 1 		; multiply index by 2 (bytes) since each entry is word-sized
	
SegmentOverride: 
	
	MOV 	AH, DX:CX[BX]	; move value in byte by byte 
	INC 	BX 
	MOV 	AL, DX:CX[BX]
	
DefaultSegment: 
	
	MOV 	AH, DS:CX[BX]	; move value in byte by byte 
	INC 	BX 
	MOV 	AL, DS:CX[BX]
   
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
	XOR 	AX, AX 		; clear register 
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

$LIST