
.bss 
inBuffer:
    .space 128
outBuffer:
    .space 128
inPos:
    .quad 0 
outPos: 
    .quad 0    


.data
//inBuffer:
//    .space 128
//outBuffer:
//    .space 128 //Ger mig 128 bytes eller 127 tecken.

.text 
.global inImage, getInt, getText, getInPos, setInPos, outImage, putInt, putText, putChar, getOutPos, setOutPos

inImage:

    //Läs up till 128 bytes mha syscall:et 'read'
    movq $0, %rax 
    movq $0, %rdi 
    leaq inBuffer(%rip), %rsi # rsi ptr till inBuffer
    movq $128, %rdx
    syscall 

    //Överskriver '\n' med 0 som nullterminator
    leaq inBuffer(%rip), %rsi 
    movq $0, %rcx # sätt index för loopen

replaceNewline:
    cmpb $0x0A, (%rsi,%rcx,1) # CMP \n inBuffer[rcx]
    je setNull
    incq %rcx
    cmpq $128, %rcx 
    jl replaceNewline
    jmp done

setNull:
    movb $0x00, (%rsi,%rcx,1)

done: 
    movq $0, inPos(%rip)

    ret 

getInt:
// TODO inplementera mer än ret 0
    movq $0, %rax
    ret

getText:
// TODO inplementera mer än ret 0
    movq $0, %rax
    ret

getInPos:
// TODO inplementera mer än ret 0
    movq $0, %rax
    ret

setInPos:
// TODO inplementera mer än return void
    ret

outImage:
    # 1. Get pointer to outBuffer
    leaq outBuffer(%rip), %rsi 

    # 2. Use a loop or helper to calculate length (up to null terminator)
    
    movq $0, %rcx # sätt index för loopen start 0

    loopNull: 
    cmpb $0, (%rsi,%rcx,1) # outBuffer[index] == 0?
    je writeOut

    # inte null -> continue
    incq $rcx 
    cmpq $128, %rcx  
    jl loopNull 

    writeOut:
    # 3. Skriv mha syscall write(stdout, buffern, lenght)
    # Dessa 4 operationer blir som intieringen och argumenten till write
    movq $1, %rax # syscall:write (initiering)
    movq $1, %rdi # stdout
    leaq outBuffer(%rip), %rsi # buffern
    movq %rcx, %rdx  # lenght (bytes)
    syscall # 'anropet'

    ret 

putInt:
    # Hämta talet (n) från %rdi
    movq %rdi, %r8 # (arg) rdi = rdx
    
    # Kolla om talet är 0
    #    - Om ja: skriv tecknet '0' med putChar och hoppa till slut

    cmpq $0, %r8 
    jne buildDigits

    buildDigits:
    loop: 
        moq %r8, %rax 
        xorq %rdx, %rdx 
        movq $10, %r9 
        divq %r9 # rax = kvoten, rdx = rest, r9 = nämnare
        addq $'0', %dl 
        pushq %rdx 
        movq %rax,%r8 
        cmpq $0, %r8 
        jne loop 
    
    printLoop
        popq %rdi # arg för putChar
        call putChar 
        cmpq %rsp, %rbp 
        jne printLoop

    ret


putText:
// TODO inplementera mer än return void
    ret

putChar:
# 1. Läs aktuell position från outPos

movq outPos(%rip), %rax 

# 2. Lägg tecknet (från %dil) i outBuffer på den positionen

leaq outBuffer(%rip), %rsi # Etablerar en outBufferPtr  
movb %dil, (%rsi,%rax,1) 

# 3. Öka positionen med 1
incq %rax 

# 4. Uppdatera outPos med den nya positionen
movq %rax, outPos(%rip) # outPos = rax;

# 5. Om positionen är större än eller lika med 127, anropa outImage
cmpq $127, %rax 
jl done # hoppa om rax !=> 127
call outImage 

# 6. Efter outImage, nollställ outPos
movq $0, outPos(%rip)

# 7. Avsluta funktionen
jmp done

done: 
    ret 

getOutPos:
// TODO inplementera mer än ret 0
    movq $0, %rax
    ret

setOutPos:
// TODO inplementera mer än return void
    ret


