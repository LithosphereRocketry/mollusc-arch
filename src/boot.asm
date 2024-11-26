        lui s2, 0x01000000 ; address of IO segment
        ldpi a0, s2, 8
        lui a0, 0x00008000 ; base ROM address
        addi a0, a0, hellorld ; offset to location of hellorld string
        j ra, puts
loop:   j zero, loop

puts:                           ; void puts(word* p)
        lui a4, 0x01000000      ; preload address of TTY
puts_loop:                      
        addi a2, zero, 4        ; i = 4
        ldpi a1, a0, 0          ; v = *p
puts_shiftloop:
        andi a3, a1, 0xFF       ; c = v & 0xFF
    !a3 jx zero, zero, ra       ; if(c == 0) return
        stpi a3, a4, 8          ; putchar(c)
        subi a2, a2, 1          ; i--
        sri a1, a1, 8           ; v >>= 8
    ?a2 j zero, puts_shiftloop  ; if(i != 0) goto puts_shiftloop
        addi a0, a0, 4          ; p += 4
        j zero, puts_loop       ; goto puts_loop

hellorld:
        const 0x6C6C6548
        const 0x646C726F
        const 0x000a0d21