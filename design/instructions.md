# MOLLUSC Instruction Listing

## Jumps

`j <dest>, <target>`

Jumps execution to the address given. Stores the following instruction in the
destination register. `j` may jump by 2^22 bytes backward or 2^22-1 bytes
forward.

`jx <dest>, <reg1>, <reg2>`

Jumps execution to the address formed by the sum of reg1 and reg2. Stores the
following instruction in the destination register.

`jxi <dest>, <reg>, <offs>`

Jumps execution to the address formed by the sum of reg and offs. Stores the
following instruction in the destination register.

## Register value loads

`lui <dest>, <value>`

Loads the upper 21 bits of the value into the upper 21 bits of the destination
register, and sets the remaining bits to 0.

`auipc <dest>, <value>`

Loads the upper 21 bits of the value into the upper 21 bits of the destination
register, sets the remaining bits to 0, and adds the current program counter.

