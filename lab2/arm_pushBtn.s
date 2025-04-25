// Symbolic constants
.equ LEDS_BASE, 0xff200000
.equ SWITCHES_BASE, 0xff200040
.equ PUSH_BUTTONS_BASE, 0xff200050

.global _start
_start:
    LDR r0, =PUSH_BUTTONS_BASE   // Base address
    LDR r1, [r0]                 // Read push buttons value
    // Do something more...

    LDR r2, =LEDS_BASE
    STR r1, [r2] 
    b _start // loopa tillbaka till början av refresh_loop

_halt:
    B _halt