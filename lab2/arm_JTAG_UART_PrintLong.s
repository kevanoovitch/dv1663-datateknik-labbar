

// Symbolic constants
.equ UART_BASE, 0xff201000
.equ UART_DATA_REGISTER_ADDRESS, 0xff201000
.equ UART_CONTROL_REGISTER_ADDRESS, 0xff201004

.data
sample_text: .asciz "Hello, world!\n"
long_text: .asciz "This is a long text, more than 64 characters, that will be stored in the data section of the program.\n"

.text
.global _start
_start:
    // UART - write long text
    LDR r6, =UART_DATA_REGISTER_ADDRESS   @ fixed FIFO pointer
    LDR r1, = UART_CONTROL_REGISTER_ADDRESS
    LDR r2, =long_text    // Load the address of the long text
uart_loop:
    LDRB r3, [r2], #1     // Load a character from the text and increment the address in r2 afterwards
    CMP r3, #0            // Check if the byte is null
    BEQ uart_loop_end     // If end of text, done
    
    check_space:
    LDR     r4, [r1]          @ read UART control register
    LDR     r5, =0xFFFF0000   @ mask for WSPACE (bits 31‑16)
    ANDS    r4, r4, r5
    BEQ     check_space       @ zero? no room yet → loop

    @ --- send the character in r3 ---
    MOV     r0, r3            @ r0 must hold the byte for uart_write
    STRB    r0, [r6]      @ send one byte



    b uart_loop            // Next character
uart_loop_end:
    
    // Do something more...

_halt:
    B _halt

