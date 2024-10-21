        ; for some reason the first cache fetch is garbage on real hardware
        ; need to fix
        add zero, zero, zero
        add zero, zero, zero
        add zero, zero, zero
        add zero, zero, zero
        lui s2, 0x00004000 ; address of LED controller
        add s3, zero, zero
loop:   
l_up:
        addi s3, s3, 1
        stpi s3, s2, 0
        j ra, busywait
        xori a0, s3, 0xFF
    ?a0 j zero, l_up
l_down:
        subi s3, s3, 1
        stpi s3, s2, 0
        j ra, busywait
    ?s3 j zero, l_down

        j zero, loop

busywait:
        lui a5, 0xA000 ; approx. 1ms when cached
busyloop:
        subi a5, a5, 1
    ?a5 j zero, busyloop
        jx zero, zero, ra