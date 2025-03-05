
init:
    lui sp , 0x8000
    jx zero, zero, ra

putc:
    lui a1, 0x01000000
    stp a0, a1, zero
    jx zero, zero, ra

exit:
    lui a1, 0x01001000
    stp a0, a1, zero
exit_loop:
    j zero, exit_loop