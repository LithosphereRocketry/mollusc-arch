    j ra, init

    addi a0, zero, 47
    addi a1, zero, 0
    addi a2, zero, 1

loop:
    subi a0, a0, 1
    add a3, a2, a1
    add a1, zero, a2
    add a2, zero, a3
?a0 j zero, loop

    addi s2, zero, 4
    add s3, zero, a1
print_loop:
    andi a0, s3, 0xFF
    j ra, putc
    sri s3, s3, 8
    subi s2, s2, 1
?s2 j zero, print_loop

    add a0, zero, zero
    j ra, exit