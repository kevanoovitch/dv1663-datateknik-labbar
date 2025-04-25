.global _start
_start:
    LDR r0, =0xff200000  // LEDs address
	
	
	
blink: 
	MOV r1, #4           // Bit 0 will turn on the rightmost LED
    STR r1, [r0]         // Write to LEDs data register   

    MOV r1, #0
    STR r1, [r0]        
	
	BL blink

_halt:
    B _halt
	