// Constants
.equ UART_BASE, 0xff201000     // UART base address
.equ UART_CONTROL_REG_OFFSET, 4 // UART control register
.equ STACK_BASE, 0x10000000		// stack beginning

.equ NEW_LINE, 0x0A

.data
n_arr:
	.word 1
	.word 2
	.word 3
	.word 4
	.word 5
	.word 6
	.word 7
	.word 8
	.word 9
	.word 10
    .word 0

.global _start
.text

print_string:
/*
-------------------------------------------------------
Prints a null terminated string.
-------------------------------------------------------
Parameters:
  r0 - address of string 
Uses: No registers altered by the function
-------------------------------------------------------
*/
    PUSH {r0-r4, lr}
    LDR r2, =UART_BASE
    _ps_loop:
        LDRB r1, [r0], #1   // load a single byte from the string
        CMP  r1, #0
        BEQ  _print_string   // stop when the null character is found

        _ps_busy_wait: // Wait for space in the write FIFO
            LDR r4, [r2, #UART_CONTROL_REG_OFFSET] // Read WSPACE for available space
            LDR r3, =0xFFFF0000 // Mask for WSPACE control bits
            ANDS r4, r4, r3
            BEQ _ps_busy_wait // Wait if no space in the write FIFO
 
 		    STR  r1, [r2]       // copy the character to the UART DATA field
        B    _ps_loop
    _print_string:
	      POP {r0-r4, pc} 
	

idiv:
/*
-------------------------------------------------------
Performs integer division
-------------------------------------------------------
Parameters:
  r0 - numerator 
  r1 - denominator
Returns:
  r0 - quotient r0/r1
  r1 - modulus r0%r1          
-------------------------------------------------------
*/
    MOV r2, r1
    MOV r1, r0
    MOV r0, #0
    B _loop_check
    _loop:
        ADD r0, r0, #1
        SUB r1, r1, r2
    _loop_check:
        CMP r1, r2
        BHS _loop
    BX lr
	

print_number: 
/*
-------------------------------------------------------
Prints a decimal number followed by newline.
-------------------------------------------------------
Parameters:
  r0 - number
Uses: No registers altered by the function
-------------------------------------------------------
*/
    PUSH {r0-r5, lr}
    MOV r5, #0	//digit counter
    _div_loop:
        ADD r5, r5, #1   // increment digit counter
        MOV r1, #10  //denominator
        BL idiv
        PUSH {r1}
        CMP r0, #0
        BHI _div_loop
        
    _print_loop:
        POP {r0}
        LDR r2, =#UART_BASE
        ADD r0, r0, #0x30   // add ASCII offset for number

        _print_busy_wait: // Wait for space in the write FIFO
            LDR r4, [r2, #UART_CONTROL_REG_OFFSET] // Read WSPACE for available space
            LDR r3, =0xFFFF0000 // Mask for WSPACE control bits
            ANDS r4, r4, r3
            BEQ _print_busy_wait // Wait if no space in the write FIFO
        
        STR r0, [r2]  // print digit
        SUB r5, r5, #1
        CMP r5, #0
        BNE _print_loop

    MOV r0, #NEW_LINE
    STR r0, [r2]   // print newline
    POP {r0-r5, pc}
	
	

/*******************************************************************
  Function for recursive factorial caclulation

Parameter: a number
Returns: factorial for that nummber
*******************************************************************/
// Write your function code here

factorial_function:
    PUSH    {lr} @ save return address
    
    @(if number > 1) 
    CMP r0, #1 
    BGT recursive @hoppa om r0 > 1
    B done @hoppa då ro <= 1, (B = hoppa alltid)

recursive:
    @Goal: return(number * factorial(number - 1));
    PUSH {r0} @ spara arg på stacken

    sub r0, r0, #1     @ r0 = r0 - 1
    // Detta är safe för jag sparade föregående värde på stacken!

    BL factorial_function @ kallar med (r0-1)
    @ Detta leder till basfallet då r0 <= 1

    MOV r2,r0 @ spara resultatet av rec. anropet

    POP {r0} @ load the original number from stack to r0
    
    @ number * factorial(u), 
    mul r0,r0, r2 @ r0 = r0, r2  
    B done
    
done: 
       
        POP {pc} @ return to caller


/*******************************************************************
 Main program
*******************************************************************/
// Write code for your main program here

_start:
    //förväntat resultat in 5 ut 120 

    LDR	r1, =n_arr 

loop_next:

    LDR r0, [r1]           @ Läs nuvarande värde från arrayen
    CMP r0, #0             @ Är det nollterminerat?
    BEQ _end 

    BL factorial_function      
    BL print_number

    ADD r1, r1, #4    @increment med 4
    B loop_next      
        
_end:
    B _end

.end