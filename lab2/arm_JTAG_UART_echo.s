        .equ UART_DATA,   0xff201000
        .equ UART_CTRL,   0xff201004

        .text
        .global _start
_start:
        LDR r6, =UART_DATA      // r6 = pointer to data
        LDR r5, =UART_CTRL      // r5 = pointer to control

echo_loop:
        // 1. Wait for a character to arrive (bit 15 == 1)
        LDR r3, [r6]
        TST r3, #0x8000         
        BEQ wait_char //Loop if the result is 0
wait_char:
        LDR r3, [r6]
        TST r3, #0x8000         // is RVALID set?
        BEQ wait_char

        // 2. Extract the character (bits 7–0)
        AND r0, r3, #0x00FF

        // 3. Wait for space in transmit FIFO (WSPACE > 0)
wait_space:
        LDR r4, [r5]
        LSRS r4, r4, #16        // shift right to get WSPACE
        BEQ wait_space

        // 4. Send the character back
        STRB r0, [r6]

        // 5. Repeat
        B echo_loop
