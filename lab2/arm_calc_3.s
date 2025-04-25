
/******************************************************************************
    Define symbols
******************************************************************************/
// Proposed stack base addresses
.equ SVC_MODE_STACK_BASE, 0x3FFFFFFF - 3 // set SVC stack to top of DDR3 memory
.equ IRQ_MODE_STACK_BASE, 0xFFFFFFFF - 3 // set IRQ stack to A9 onchip memory

// GIC Base addresses
.equ GIC_CPU_INTERFACE_BASE, 0xFFFEC100
.equ GIC_DISTRIBUTOR_BASE, 0xFFFED000

// Other I/O device base addresses
.equ LED_BASE, 0xff200000
.equ SW_BASE, 0xff200040
.equ BTN_BASE, 0xff200050
.equ DISPLAYS_BASE, 0xff200020
.equ UART_BASE, 0xff201000
.equ UART_DATA_REGISTER, 0xff201000
.equ UART_CONTROL_REGISTER, 0xff201004


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

.org 0x00  // Address of interrupt vector
    B _start    // reset vector
    B SERVICE_UND // undefined instruction vector
    B SERVICE_SVC // software interrrupt (supervisor call) vector
    B SERVICE_ABT_INST // aborted prefetch vector
    B SERVICE_ABT_DATA // aborted data vector
    .word 0 // unused vector
    B SERVICE_IRQ // IRQ interrupt vector
    B SERVICE_FIQ // FIQ interrupt vector


.global _start
_start:
    LDR r8, =DISPLAYS_BASE    // Base address for display 0-3
    LDR r9, =digits    // r1 points to start of array
    MOV r10, #0     // r10 = index = 0 
    

    // Initieringar för att kunna nyttja interrupts

    /* 1. Set up stack pointers for IRQ and SVC processor modes */
    MSR CPSR_c, #0b11010010 // change to IRQ mode with interrupts disabled
    LDR SP, =IRQ_MODE_STACK_BASE // initiate IRQ mode stack

    MSR CPSR, #0b11010011 // change to supervisor mode, interrupts disabled
    LDR SP, =SVC_MODE_STACK_BASE // initiate supervisor mode stack


    // config av GIC
    MOV R0, #73  // UART Interrupt ID = 73 for buttons
    BL CONFIG_GIC // configure the ARM GIC


    //LDR R0, =UART_CONTROL_REGISTER
    //MOV R1, #0x1 // enable REceive interrupts
    //STR R1, [R0]

    // tillåt avbrott
    MSR CPSR_c, #0b01010011  // IRQ unmasked, MODE = SVC

    // tillåt avbrott baserat på push-btns

    LDR R0, =0xFF200058       // Interruptmask register
    MOV R1, #0xF              // Aktivera interrupt för alla 4 knappar (bit 0–3) 
    STR R1, [R0]

    //

B main_loop

    // För att hantera interupts
SERVICE_IRQ:
    PUSH {R0-R7, LR}
    /* 1. Read and acknowledge the interrupt at the GIC.The GIC returns the interrupt ID. */
    /* Read and acknowledge the interrupt at the GIC: Read the ICCIAR from the CPU Interface */
    LDR R4, =GIC_CPU_INTERFACE_BASE  // 0xFFFEC100
    LDR R5, [R4, #0x0C] // read current Interrupt ID from ICCIAR


    CHECK_BTN_INTERRUPT:
    // Kolla om det är BTN (ID 73)
    CMP R5, #73
    BEQ BTN_INTERRUPT_HANDLER
  


BTN_INTERRUPT_HANDLER:
    PUSH {LR}
    BL handle_btn_logic
    POP {PC}



handle_btn_logic:
    // Läs Edgecapture och spara original
    LDR R0, =0xFF20005C
    LDR R1, [R0]         
    MOV R4, R1            // spara originalvärde

    MOV R2, #0            // counter = 0
    MOV R3, #4            // antal knappar

count_loop:
    TST R1, #1
    ADDNE R2, R2, #1
    LSR R1, R1, #1
    SUBS R3, R3, #1
    BNE count_loop

    CMP R2, #2
    BLEQ increase_index

    CMP R2, #1
    BLEQ decrease_index

    // Nollställ Edgecapture
    LDR R0, =0xFF20005C
    STR R4, [R0]

    BX LR


    SERVICE_IRQ_DONE: 
    //allt är hanterat, returnera detta till GIC:en
    STR R5, [R4, #0x10]   // ICCEOIR ← skriv tillbaka interrupt ID
    
    /* 6. Return from interrupt */
    POP {R0-R7, LR}
    SUBS PC, LR, #4

    B SERVICE_IRQ_DONE // inget vi hanterar? bara returnera

    


main_loop:
    BL read_uart           // blocks until a character is received
    BL handle_input   
    BL display_digit 
    B main_loop            // if not w or s, just loop again

read_arr:
    
    LDRB r0, [r10, r9]  // r0 = digits[r10]
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
 PUSH {lr}    
 ADD r10, r10, #1
 CMP r10, #16
 MOVEQ r10, #0              // wrap around if r3 == 16
 POP {pc}   
 
decrease_index: 
 // btn 's'
 PUSH {lr}    
 SUBS r10, r10, #1
 CMP r10, #-1
 MOVEQ r10, #15             // wrap around if r3 < 0
 POP {pc}    


display_digit: 
    // multi-branch nytta sp 

    PUSH {lr}    
    BL read_arr
    STRB r0, [r8]                // Send to display 
    POP {pc}     
    


       /* Undefined instructions */
SERVICE_UND:
    B SERVICE_UND
    /* Software interrupts */
SERVICE_SVC:
    B SERVICE_SVC
    /* Aborted data reads */
SERVICE_ABT_DATA:
    B SERVICE_ABT_DATA
    /* Aborted instruction fetch */
SERVICE_ABT_INST:
    B SERVICE_ABT_INST
    /* FIQ */
SERVICE_FIQ:
    B SERVICE_FIQ

    
/*******************************************************************
    HELP FUNCTION!
    --------------
Configures the Generic Interrupt Controller (GIC)

Arguments:
    R0: Interrupt ID
*******************************************************************/
CONFIG_GIC:
    PUSH {LR}
    /* To configure a specific interrupt ID:
    * 1. set the target to cpu0 in the ICDIPTRn register
    * 2. enable the interrupt in the ICDISERn register */
    /* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
    MOV R1, #1 // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT
    /* configure the GIC CPU Interface */
    LDR R0, =GIC_CPU_INTERFACE_BASE // base address of CPU Interface, 0xFFFEC100
    /* Set Interrupt Priority Mask Register (ICCPMR) */
    LDR R1, =0xFFFF // enable interrupts of all priorities levels
    STR R1, [R0, #0x04]
    /* Set the enable bit in the CPU Interface Control Register (ICCICR).
    * This allows interrupts to be forwarded to the CPU(s) */
    MOV R1, #1
    STR R1, [R0]
    /* Set the enable bit in the Distributor Control Register (ICDDCR).
    * This enables forwarding of interrupts to the CPU Interface(s) */
    LDR R0, =GIC_DISTRIBUTOR_BASE   // 0xFFFED000
    STR R1, [R0]
    POP {PC}


/*********************************************************************
    HELP FUNCTION!
    --------------
Configure registers in the GIC for an individual Interrupt ID.

We configure only the Interrupt Set Enable Registers (ICDISERn) and
Interrupt Processor Target Registers (ICDIPTRn). The default (reset)
values are used for other registers in the GIC.

Arguments:
    R0 = Interrupt ID, N
    R1 = CPU target
*********************************************************************/
CONFIG_INTERRUPT:
    PUSH {R4-R5, LR}
    /* Configure Interrupt Set-Enable Registers (ICDISERn).
     * reg_offset = (integer_div(N / 32) * 4
     * value = 1 << (N mod 32) */
    LSR R4, R0, #3 // calculate reg_offset
    BIC R4, R4, #3 // R4 = reg_offset
    LDR R2, =0xFFFED100 // Base address of ICDISERn
    ADD R4, R2, R4 // R4 = address of ICDISER
    AND R2, R0, #0x1F // N mod 32
    MOV R5, #1 // enable
    LSL R2, R5, R2 // R2 = value
    /* Using the register address in R4 and the value in R2 set the
     * correct bit in the GIC register */
    LDR R3, [R4] // read current register value
    ORR R3, R3, R2 // set the enable bit
    STR R3, [R4] // store the new register value
    /* Configure Interrupt Processor Targets Register (ICDIPTRn)
     * reg_offset = integer_div(N / 4) * 4
     * index = N mod 4 */
    BIC R4, R0, #3 // R4 = reg_offset
    LDR R2, =0xFFFED800 // Base address of ICDIPTRn
    ADD R4, R2, R4 // R4 = word address of ICDIPTR
    AND R2, R0, #0x3 // N mod 4
    ADD R4, R2, R4 // R4 = byte address in ICDIPTR
    /* Using register address in R4 and the value in R2 write to
     * (only) the appropriate byte */
    STRB R1, [R4]
    POP {R4-R5, PC}


