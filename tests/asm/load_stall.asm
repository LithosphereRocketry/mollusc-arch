    j ra, init
    lui a2, number
    addi a2, a2, number
    ldp a1, zero, a2
    andi a0, a1, 0xFF
    j ra, putc
    add a0, zero, zero
    j ra, exit


number:
    const 65