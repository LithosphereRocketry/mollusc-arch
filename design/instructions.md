# MOLLUSC Instruction Listing

## Arithmetic

`add <dest>, <reg1>, <reg2>`

Adds the values of reg1 and reg2 and places the result in dest.

`sub <dest>, <reg1>, <reg2>`

Subtracts the value of reg2 from that of reg1 and places the result in dest.

`xor <dest>, <reg1>, <reg2>`

Computes the bitwise-xor of the values of reg1 and reg2 and places it in dest.

## Jumps

`j <dest>, <target>`

Jumps execution to the address given. Stores the following instruction in the
destination register. `j` may jump by 2^22 bytes backward or 2^22-1 bytes
forward.

`jx <dest>, <reg1>, <reg2>`

Jumps execution to the address formed by the sum of reg1 and reg2. Stores the
address of the following instruction in the destination register.

`jxi <dest>, <reg>, <offs>`

Jumps execution to the address formed by the sum of reg and offs. Stores the
address of the following instruction in the destination register.

## Register value loads

`lui <dest>, <value>`

Loads the upper 21 bits of the value into the upper 21 bits of the destination
register, and sets the remaining bits to 0.

`auipc <dest>, <value>`

Loads the upper 21 bits of the value into the upper 21 bits of the destination
register, sets the remaining bits to 0, and adds the current program counter.

