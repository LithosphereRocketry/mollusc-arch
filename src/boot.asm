start:
        lui s2, 0x30004000 ; address of LED controller
        addi s1, zero, 0x40
        stpi s1, s2, 0
        j zero, start