$NOLIST 				////////////////////////////////////////////////////////////// is this right 

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

%*DEFINE(SETBIT(reg, bit))   (
	OR %reg, 1 SHL %bit 
)



; CLRBIT 
;
; Description:      This macro generates code to clear a bit in a register.
;
; Operation:        
;
; Arguments:        bit - the bit number that we are trying to clear. 
;                   reg - register containing bit we are setting. 
;
; Registers Used:    
; Stack Depth:      0 words
;

%*DEFINE(CLRBIT(reg, bit))   (
	XOR (OR %reg, 1 SHL %bit)		; tentative: we set the specified bit in the register, and XOR that with the set bit. 
)

; if i can call a similar macro ////////////////////////
%*DEFINE(CLRBIT(reg, bit)) LOCAL SETBIT 	(
	XOR SETBIT(%reg, %bit), 1 SHL %bit 
)



; COMBIT 
;
; Description:      This macro generates code to complement a bit in a register.
;
; Operation:        
;
; Arguments:        bit - the bit number that we are trying to get the complement of. 
;                   reg - register containing bit we are setting. 
;
; Registers Used:    
; Stack Depth:      0 words
;

%*DEFINE(COMBIT(reg, bit))   (
	
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
; Description:      This macro generates code to . //////////////////////////////////
;
; Operation:        
;
; Arguments:        None.
;
; Registers Used:    
; Stack Depth:      0 words
;

%*DEFINE(XLATW())   (
   
)


; READPCB  
;
; Description:      
;
; Operation:        
;
; Arguments:        addr - address of PCB register to read and return value of
;                   
; Registers Used:    
; Stack Depth:      0 words
;

%*DEFINE(READPCB(addr))   (


   
)


; WRITEPCB 
;
; Description:      Writes the 16-bit value val to the PCB register at address addr.
;
; Operation:        
;
; Arguments:        addr - address of PCB register to write to 
; 					val - value to write 
;
; Registers Used:    
; Stack Depth:      0 words
;

%*DEFINE(WRITEPCB(addr, val))   (
   
)

$LIST