        addi x5, x0, 10
        add x3, x0, x0

        # This is the loop
loop:   add x3, x3, x5
    ?x5 jxi x6, x0, 8     # Conditional jump
        subi x5, x5, 1
