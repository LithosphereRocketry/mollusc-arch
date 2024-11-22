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
        ; each iteration is about 3 clocks = 75 ns at 40 MHz
        ; 0x6800 iters ~= 2 ms
        lui a5, 0x6800 ; 
busyloop:
        subi a5, a5, 1
    ?a5 j zero, busyloop
        jx zero, zero, ra