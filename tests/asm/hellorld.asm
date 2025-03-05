    j ra, init
    lui a0, hellorld
    addi a0, a0, hellorld
    j ra, puts
    add a0, zero, zero
    j ra, exit

puts:
    subi sp, sp, 16
    stpi ra, sp, 0
    stpi s2, sp, 4
    stpi s3, sp, 8
    stpi s4, sp, 12

    add s2, zero, a0

puts_loop:
    addi s4, zero, 4
    ldp s3, s2, zero
puts_shiftloop:
    andi a0, s3, 0xFF
!a0 j zero, puts_done
    j ra, putc
    subi s4, s4, 1
    sri s3, s3, 8
?s4 j zero, puts_shiftloop
    addi s2, s2, 4
    j zero, puts_loop

puts_done:
    ldpi ra, sp, 0
    ldpi s2, sp, 4
    ldpi s3, sp, 8
    ldpi s4, sp, 12
    addi sp, sp, 16
    jx zero, zero, ra

string hellorld "Hellorld!\n"