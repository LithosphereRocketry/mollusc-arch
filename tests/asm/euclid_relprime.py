import math
import sys

n = 0x13b0
m = 2

def gcd(a, b):
    if b == 0:
        return a
    while a != b:
        if a > b:
            a -= b
        else:
            b -= a
    return b

while(gcd(n, m) != 1):
    m += 1

sys.stdout.buffer.write(m.to_bytes(1, 'little'))