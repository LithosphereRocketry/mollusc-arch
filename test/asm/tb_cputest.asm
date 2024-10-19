        addi a0, zero, 10
        jxi ra, zero, triangle
stop:   jxi zero, zero, stop

triangle:
        add a1, zero, zero
triangle_loop:
        add a1, a1, a0
        subi a0, a0, 1
    ?a0 jxi zero, zero, triangle_loop     # Conditional jump
        add a0, a1, zero
        jxi zero, ra, 0

