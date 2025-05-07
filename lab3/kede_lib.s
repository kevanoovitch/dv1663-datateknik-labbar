
.bss 
inBuffer:
    .space 128
outBuffer:
    .space 128
inPos:
    .quad 0 
outPos: 
    .quad 0    
intBuffer:
    .space 20 # helper buffer for putInt


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
    # 1. Spara n (från %rdi) i t.ex. %rax eller %r8

    movq %rdi, %r8

    # 2. Kolla om talet är 0
    #    - Om ja: skriv tecknet '0' via putChar
    #    - Hoppa till slut

    cmpq $0, %r8
    jne putIntLoop
    
    movb $'0', %dil
    call putChar

    # 3. Initiera:
    #    - %rsi = pekare till intBuffer
    #    - %rcx = räknare (antal siffror)
    leaq intBuffer(%rip), %rsi
    movq $0, %rcx 

    putIntLoop:  
    # 4. Starta loop:
    #    - Dela talet med 10 (divq)
    movq %r8, %rax 
    xorq %rdx, %rdx
    movq $10, r9
    divq r9 
    movq %rax, %r8 # uppdatera r8
    #    - Resten (rdx) + '0' → ASCII-tecken
    addb $'0', %dl  
    #    - Spara i intBuffer[rcx]
    movb %dl, (%rsi,%rcx,1)
    #    - Öka %rcx
    incq %rcx
    #    - Fortsätt tills talet är 0
    cmpq $0,r8
    jne putIntLoop 

    # 5. Skriv ut siffrorna i omvänd ordning:
    #    - Minska %rcx tills 0
    #    - Läs intBuffer[rcx - 1]
    #    - Lägg i %dil och anropa putChar
    cmpq $0, %rcx
    je putIntDone
    
    decq %rcx 
    movb (%rsi,%rcx,1), %dil 
    call putChar
    jmp putIntLoop
    
    # 6. ret
    putIntdone:
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


