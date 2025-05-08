
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
.global inImage, getInt, getText, getInPos, setInPos, outImage, putInt, putText, putChar, getOutPos, setOutPos, getChar

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
    jmp inImageDone

setNull:
    movb $0x00, (%rsi,%rcx,1)

inImageDone: 
    movq $0, inPos(%rip)

    ret 

getInt:
    # 1. Kontrollera om inPos är utanför bufferten (eller bufferten är tom)
    #    - Om ja: kalla inImage för att fylla inBuffer och nollställ inPos
    call getInPos 
    movq %rax, %r8# r8 = getInPos()

    # kontroll 
    leaq inBuffer(%rip), %rsi 
    movzbq (%rsi,%r8,1), %r9 # r9 = inBuffer[inPos] 
    cmpq $0, %r9 
    je callInImage 

    callInImage:
        call inImage
        movq $0, %r8                # nollställ inPos efter inImage
        leaq inBuffer(%rip), %rsi  # sätt rsi till start av buffer igen


    # 2. Läs inPos och peka %rsi på inBuffer + inPos
    leaq inBuffer(%rip,%r8,1), %rsi 

    # 3. Hoppa över inledande mellanslag (loopa över ' ' och '\t')
    getIntSkipWhiteSpace: 
        movzbq (%rsi), %rax 
        cmpb $' ', %al 
        je skipChar 
        cmpb $'\t', %al 
        je skipChar
        jmp checkSign

    skipChar:
        incq %rsi 
        incq %r8 
        jmp getIntSkipWhiteSpace 


    # 4. Kolla om tecknet är '+' eller '-' 
    #    - Spara tecken för eventuell negation

    xorq %rbx, %rbx # rbx = 0 standard (+)

    checkSign: 
        movzbq (%rsi), %rax 
        cmpb $'+', %al 
        je skipSign 

        cmpb $'-', %al 
        je setNegate

        jmp parseDigits 

    setNegate: 
        movq $1, %rbx # tecken är (-)
        incq %rsi 
        incq %r8 
        jmp parseDigits

    skipSign:
        incq %rsi 
        incq %r8 
        jmp parseDigits 

    # 5. Initiera ett register (t.ex. %rax) till 0 för att bygga upp talet

    parseDigits:
        movq $0, %rax
    # 6. Läs ett tecken i taget så länge det är en siffra ('0'–'9'):
    #    - Omvandla ASCII → siffervärde (subtrahera '0')
    #    - Multiplicera ackumulerat tal med 10
    #    - Lägg till nya siffran
    digitLoop:
        movzbq (%rsi), %rdx # rdx = inBuffer[inPos] 
        cmpb $'0', %dl 
        jb doneDigits # < 0 -> inte en siffra
        cmpb $'9', %dl 
        ja doneDigits # > 9 inte en siffra

        subb $'0', %dl 
        imulq $10, %rax, %rax 
        addq %rdx, %rax # lägg ihop siffrorna till ett tal

        incq %rsi 
        incq %r8 
        jmp digitLoop

    doneDigits:  
    # 7. När icke-siffra hittas:
    #    - Spara nuvarande inPos (pekar på första icke-siffra)
    movq %r8, inPos(%rip)
    # 8. Om talet skulle vara negativt: gör negation
    cmpq $0, %rbx 
    je returnValue
    negq %rax 

    returnValue:
        # 9. Returnera värdet i %rax
        ret


getText:
    # Parameter 1: %rdi = buf (destination)
    # Parameter 2: %rsi = n (max antal tecken att läsa)

    push %rdi        # spara buf
    push %rsi        # spara n

    # 1. Kontrollera om inBuffer[inPos] == 0
    #    - Om ja: anropa inImage
    #    - Ladda om inPos och inBuffer-pekare
    call getInPos 
    movq %rax, %r8# r8 = getInPos()
    leaq inBuffer(%rip), %r10 # r10 = &inBuffer 
    movzbq (%r10,%r8,1), %r9 # r9 = inBuffer[inPos] 

    cmpb $0, %r9b
    jne copyLoop


    call inImage
    movq $0, %r8                # nollställ inPos efter inImage
    leaq inBuffer(%rip), %r10  # sätt rsi till start av buffer igen

    # 2. Initiera:
    #    - %rdx = antal kopierade tecken (räknare)
    #    - %r8 = inPos
    #    - %r9 = pekare till inBuffer + inPos
    movq $0, %rdx 


copyLoop:
    # 3. Läs tecken från (%r11)
    #    - Om nullbyte → gå till finish
    #    - Om %rdx == %rsi → gå till finish (max n tecken kopierade)
    movzbq (%r10,%r8,1), %r11
    cmpb $0, %r11b
    je finish
    cmpq %rdx, %rsi 
    je finish

    # 4. Kopiera tecknet till (%rdi)
    movzbq (%r10,%r8,1), %r11 
    movb %r11b, (%rdi)

    # 5. Öka pekare och räknare:
    #    - %rdi++
    #    - %rdx++
    #    - %r8++
    incq %rdi
    incq %rdx 
    incq %r8

    # 6. Repetera
    jmp copyLoop

finish:
    # 7. Sätt nullbyte på slutet av buf
    # 8. Spara uppdaterad inPos från %r8
    # 9. Returnera antal kopierade tecken i %rax
    movb $0, (%rdi)
    movq %r8, %rdi 
    call setInPos
    movq %rdx, %rax 
    ret 


getInPos:
    # 1. Ladda värdet i inPos (som är en variabel i .bss) till ett register
    #    - inPos innehåller indexet i inBuffer (typ som ett int*)
    movq inPos(%rip), %rax

    # 2. Returnera värdet i %rax (standard enligt calling convention)
    ret

setInPos:
    # 1. Jämför om n < 0  (n ligger i %rdi)
    #    - Om ja: sätt %rdi = 0
    cmpq $0, %rdi 
    jl setToZero
    
     # 2. Jämför om n > MAXPOS (t.ex. 127)
    cmpq $127, %rdi 
    ja setToMax

    jmp setInPosFinish

    setToZero: 
    movq $0, %rdi 
    jmp setInPosFinish

    setToMax:   
    #    - Om ja: sätt %rdi = 127
    movq $127, %rdi 
    jmp setInPosFinish


    
    setInPosFinish:
    # 3. Spara %rdi i inPos (%rdi är det validerade indexet)
    movq %rdi, inPos(%rip)
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
    incq %rcx 
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
    movq $10, %r9
    divq %r9 
    movq %rax, %r8 # uppdatera r8
    #    - Resten (rdx) + '0' → ASCII-tecken
    addb $'0', %dl  
    #    - Spara i intBuffer[rcx]
    movb %dl, (%rsi,%rcx,1)
    #    - Öka %rcx
    incq %rcx
    #    - Fortsätt tills talet är 0
    cmpq $0, %r8
    jne putIntLoop 

    # 5. Skriv ut siffrorna i omvänd ordning:
    #    - Minska %rcx tills 0
    #    - Läs intBuffer[rcx - 1]
    #    - Lägg i %dil och anropa putChar
    printLoop:
    cmpq $0, %rcx
    je putIntDone
    
    decq %rcx 
    movb (%rsi,%rcx,1), %dil 
    call putChar
    jmp printLoop
    
    # 6. ret
    putIntDone:
        ret




putText:
    # 1. %rdi = pekare till sträng (buf)

    
    # 2. Starta loop:
putTextLoop:
        # a) Läs ett tecken från (%rdi)
        # b) Om tecknet är null (0) → klar
        # c) Annars:
            # - Flytta tecknet till %dil
            # - Anropa putChar
            # - Öka %rdi
            # - Gå tillbaks till loopen
        movzbq (%rdi), %rax 
        cmpb $0, %al 
        je donePutText
        movb %al, %dil
        call putChar 
        incq %rdi 
        jmp putTextLoop

donePutText:
    # 3. ret
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
jl putCharDone # hoppa om rax !=> 127
call outImage 

# 6. Efter outImage, nollställ outPos
movq $0, outPos(%rip)

# 7. Avsluta funktionen
jmp putCharDone

putCharDone: 
    ret 

getOutPos:
    movq outPos(%rip), %rax
    ret 

setOutPos:
    # 1. Jämför om n < 0
    cmpq $0, %rdi 
    
    jl setZero
    cmpq $127, %rdi 
    ja greaterThanMax
    # 2. Jämför om n > 127
    

    setZero: 
    #    - Om ja: sätt rdi = 0
        movq $0, %rdi 
        jmp store

    greaterThanMax:
    #    - Om ja: sätt rdi = 127
        movq $127, %rdi 

    store:
    # 3. Spara rdi i outPos
    movq %rdi, outPos(%rip)
    # 4. ret
    ret 

getChar:
    # 1. Hämta aktuell position från inPos
    call getInPos 
    movq %rax, %r8# r8 = getInPos()

    # 2. Ladda basadressen till inBuffer
    leaq inBuffer(%rip), %r9 

    # 3. Läs tecknet vid inBuffer[inPos]
    #    - Om tecknet är null (0): anropa inImage och nollställ inPos

    movzbq (%r9,%r8,1), %r10 # r10 = inBuffer[inPos]
    cmpb $0, %r10b              
    jne readChar 

    # callInImage:
    call inImage
    movq $0, %r8                # nollställ inPos efter inImage
    leaq inBuffer(%rip), %r9  # sätt rsi till start av buffer igen


    readChar:
    # 4. Läs tecknet vid inBuffer[inPos] igen (efter eventuell refill)
        movzbq (%r9,%r8,1), %rax  # r10 = inBuffer[inPos]

  

    # 5. Öka inPos med 1 och uppdatera via setInPos
        incq %r8
        movq %r8, %rdi 
        call setInPos

    # 7. ret
        ret 

