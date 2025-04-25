
// Symbolic constants
.equ LEDS_BASE, 0xff200000
.equ SWITCHES_BASE, 0xff200040
.equ PUSH_BUTTONS_BASE, 0xff200050
.equ DISPLAYS_BASE_1, 0xff200020
.equ DISPLAYS_BASE_2, 0xff200030


.data
digits:
.byte 0b00111111 //0
.byte 0b00000110 //1
.byte 0b01011011 //2
.byte 0b01001111 //3
.byte 0b01100110 // 4
.byte 0b01101101 // 5
.byte 0b01111101 // 6
.byte 0b00000111 // 7
.byte 0b01111111 // 8
.byte 0b01101111 // 9
.byte 0b01110111  // A
.byte 0b01111100 // b
.byte 0b00111001 // C
.byte 0b01011110 // d
.byte 0b01111001 // E
.byte 0b01110001 // F

.text
.global _start
_start:
    LDR sp, =0x20000    // initialize stack pointer
    LDR r1, =DISPLAYS_BASE_1    // Base address for display 0-3
    LDR r2, =digits    // r1 points to start of array
    MOV r3, #0     // r3 = index = 0 
    B main_loop

main_loop:
    BL read_uart           // blocks until a character is received
    BL handle_input   
    BL display_digit 
    B main_loop            // if not w or s, just loop again

read_arr:
    
    LDRB r0, [r3, r2]  // r0 = digits[r3]
    BX lr
    
read_uart:
    LDR r4, =0xff201000       // UART_DATA address
wait_char:
    LDR r5, [r4]
    TST r5, #0x8000           // is bit 15 set? (RVALID)
    BEQ wait_char             // no? loop until a char is received
    AND r0, r5, #0x00FF       // keep only the character byte
    BX lr                     // return to main_loop

handle_input: 

    PUSH {lr}
    // if r0 == 'w'
    CMP r0, #'w'
    BLEQ increase_index
    // if r0 == 's'
    CMP r0, #'s'
    BLEQ decrease_index
    POP {pc}
   

increase_index: 
 //btn 'w'
 PUSH {r10, lr}    
 ADD r3, r3, #1
 CMP r3, #16
 MOVEQ r3, #0              // wrap around if r3 == 16
 POP {r10, pc}   
 
decrease_index: 
 // btn 's'
 PUSH {r10, lr}    
 SUBS r3, r3, #1
 CMP r3, #-1
 MOVEQ r3, #15             // wrap around if r3 < 0
 POP {r10, pc}    


display_digit: 
    // multi-branch nytta sp 

    PUSH {r10, lr}    
    BL read_arr
    STR r0, [r1]                // Send to display 
    POP {r10, pc}     
    



