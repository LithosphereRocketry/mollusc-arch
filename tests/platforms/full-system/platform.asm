
init:
    lui a1, 0x01000000
    add a0, zero, zero
    stp a0, a1, zero
    lui sp , 0x800
    jx zero, zero, ra

putc:
    lui a1, 0x01000000
    stpi a0, a1, 8
    jx zero, zero, ra

exit:
    lui a1, 0x01000000
    addi a0, zero, 0xFF
    stp a0, a1, zero
exit_loop:
    j zero, exit_loop