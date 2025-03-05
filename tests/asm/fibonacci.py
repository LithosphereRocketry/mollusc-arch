import sys

a = 0
b = 1
for i in range(47):
    c = a + b
    a = b
    b = c

sys.stdout.buffer.write(a.to_bytes(4, 'little'))