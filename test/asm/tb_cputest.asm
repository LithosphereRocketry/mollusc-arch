        addi a0, zero, 10
        j ra, triangle
        add s1, a0, zero
        addi a0, zero, array
        j ra, sum_to_z
        add s2, a0, zero
        ldpi a5, zero, array
        addi a5, a5, 16
        stpi a5, zero, array
        stpi a5, zero, arr2
        addi a0, zero, array
        j ra, sum_to_z
        add s3, a0, zero
stop:   j zero, stop

triangle:
        add a1, zero, zero
triangle_loop:
        add a1, a1, a0
        subi a0, a0, 1
    ?x5 j zero, triangle_loop     ; Conditional jump
        add a0, a1, zero
        jxi zero, ra, 0

sum_to_z:
        add a1, zero, zero
sum_to_z_loop:
        ldp a2, a0, zero
        add a1, a1, a2
        addi a0, a0, 4
    ?a2 j zero, sum_to_z_loop
        add a0, a1, zero
        jx zero, ra, zero

array:
        const 1
arr2:
        const 2
        const 3
        const 4
        const 4
        const 4
        const 4
        const 0