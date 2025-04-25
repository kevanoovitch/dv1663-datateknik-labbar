// Symbolic constants
.equ LEDS_BASE, 0xff200000
.equ SWITCHES_BASE, 0xff200040

.global _start
_start:
    LDR r0, =SWITCHES_BASE   // Base address
    LDR r1, [r0]             // Read switches value

    // Do something more...

    //Försök utöka programmet så att det  kan visa switcharnas lägen med hjälp av lysdioderna.
    
    LDR r2, =LEDS_BASE
    STR r1, [r2] // skriv över värdet på switcherna till lysdioderna 

    
    //Lägg gärna till en "loop" så att swicharnas lägen visas hela tiden, 
    //istället för att bara avsluta programmet direkt!

refresh_loop:
    LDR r0, =SWITCHES_BASE   // Base address
    LDR r1, [r0]             // Read switches value

    LDR r2, =LEDS_BASE
    STR r1, [r2] // skriv över värdet på switcherna till lysdioderna 

    b refresh_loop // loopa tillbaka till början av refresh_loop

    // Prologue (end it)
    //b _halt
    
    

    

_halt:
    B _halt