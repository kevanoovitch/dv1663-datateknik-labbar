
// Symbolic constants
.equ LEDS_BASE, 0xff200000
.equ SWITCHES_BASE, 0xff200040
.equ PUSH_BUTTONS_BASE, 0xff200050
.equ DISPLAYS_BASE_1, 0xff200020
.equ DISPLAYS_BASE_2, 0xff200030

.global _start
_start:
    LDR r0, =DISPLAYS_BASE_1    // Base address for display 0-3
    MOV r1, #0b0001001         // Binary value to write
    STR r1, [r0]                // Write to the display

    LDR r0, =DISPLAYS_BASE_2    // Base address for display 4-5
    MOV r1, #0x7f               // Hexadecimal value to write
    LSL r1, r1, #8              // Shift left 8 bits
    STR r1, [r0]                // Write to the display
    // Do something more...
zero_display:
    LDR r0, =DISPLAYS_BASE_1    // Base address for display 0-3
    MOV r1, #0x00         // Binary value to write
    STR r1, [r0]                // Write to the display

    // nolla display nr 5 den längst till vänster
    LDR r0, =DISPLAYS_BASE_2    // Base address for display 4-5
    MOV r1, #0x00               // Hexadecimal value to write
    LSL r1, r1, #8              // Shift left 8 bits
    STR r1, [r0]                // Write to the display

    


    // Försök skriva siffrorna 0-9
        //skriv 0-6
    
    // skriv 1 och 2
    LDR r0, =DISPLAYS_BASE_2    // Base address for display 4-5
    MOV r2, #0b00000110      
    LSL r2, r2, #8
    MOV r3, #0b01011011  
    ADD r1, r2, r3              
    STR r1, [r0]                

    // skriv 3-5 (Nästa display base)
    LDR r0, =DISPLAYS_BASE_1    // Base address for display 0-3

    MOV r1, #0b01001111         // Binary rep. of 3
    LSL r1, r1, #24              // Shift left 

    MOV r2, #0b01100110 // rep. of 4
    LSL r2, r2, #16
    ADD r1, r1,r2

    MOV r3, #0b01101101 // rep. of 5
    LSL r3, r3, #8
    ADD r1, r1,r3  

    MOV r4, #0b01111101 // rep. of 6
    LSL r4, r4, #0
    ADD r1, r1,r4  

    STR r1, [r0]                // Write to the display



    // skriv 7 och 8
    LDR r0, =DISPLAYS_BASE_2    // Base address for display 4-5
    MOV r2, #0b00000111      
    LSL r2, r2, #8
    MOV r3, #0b01111111  
    ADD r1, r2, r3              
    STR r1, [r0]     

    // skriv 9 (Nästa display base)
    LDR r0, =DISPLAYS_BASE_1    // Base address for display 0-3

    MOV r1, #0b01101111         // Binary rep. of 9
    LSL r1, r1, #24              // Shift left 
    STR r1, [r0]    
    B _halt

_halt:
    B _halt

