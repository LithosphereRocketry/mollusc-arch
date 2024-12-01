        lui s2, 0x01000000 ; address of IO segment
        ldpi a0, s2, 8          ; need to wait for here for some reason, otherwise USB CDC fails
        lui a0, 0x12345800
        addi a0, a0, 0x6EF      ; load value 0x123456ef
        j ra, putx              ; print value
        lui a0, 0x00008000      ; base ROM address
        addi a0, a0, hellorld   ; offset to location of hellorld string
        j ra, puts              ; print string
loop:   j zero, loop            ; halt

        ; Put string to TTY
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

        string hellorld "Hellorld!\r\n"

        ; Put hexadecimal word to TTY
putx:
        lui a4, 0x01000000      ; preload address of TTY
        addi a3, zero, 8               ; i = 8
putx_loop:
        sri a1, a0, 28          ; nibble = word >> 28
        ltui a2, a1, 10          ; isnum = (nibble < 10)
    !a2 addi a1, a1, 87         ; if(isnum) nibble += 'a' - 10
    ?a2 addi a1, a1, 48         ; else nibble += '0'
        stpi a1, a4, 8          ; putchar(nibble)
        subi a3, a3, 1          ; i--
        sli a0, a0, 4           ; word <<= 4
    ?a3 j zero, putx_loop       ; if(i != 0) goto putx_loop
        jx zero, zero, ra       ; return