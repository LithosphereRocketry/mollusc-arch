    j ra, init
    addi a1, zero, 1
    addi a2, zero, 64
    ; in an incorrect implementation, the result of this non-executing addi
    ; will get juggled by the forwarder...
!a1 addi a2, zero, 65
    ; so this addi will receive a forwarded value of 65 and produce 'B' instead
    ; of 'A'
?a1 addi a2, a2, 1
    add a0, zero, a2
    j ra, putc
    addi a0, zero, 0 
    j ra, exit