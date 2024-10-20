        lui s2, 0x00004000 ; address of LED controller
        addi s1, zero, 255
        stpi s1, s2, 0

stop:   j zero, stop