    j ra, init
    ; return relprime(0x13b0);
    lui a0, 0x13b0
    addi a0, a0, 0x13b0
    j ra, relprime
    j ra, putc
    addi a0, zero, 0
    j ra, exit

relprime: ; int relprime(int n) {
    subi sp, sp, 12
    stpi ra, sp, 0
    stpi s2, sp, 4
    stpi s3, sp, 8
    add s2, zero, a0
    addi s3, zero, 2 ;   int m = 2;

relprime_loop:
;   while(
    add a0, zero, s2
    add a1, zero, s3
    j ra, gcd    ; gcd(n, m)
    subi a0, a0, 1    ; != 1) {
?a0 addi s3, s3, 1   ;     m++;
?a0 j zero, relprime_loop ;   }
    add a0, zero, s3
    ldpi ra, sp, 0
    ldpi s2, sp, 4
    ldpi s3, sp, 8
    jx zero, zero, ra ;   return m; }

gcd: ; int gcd(int a, int b) {
!a1 jx zero, zero, ra  ;   if(b == 0) return a; 

gcd_loop: ;   while(
    sub a2, a0, a1 ; a != b
!a2 j zero, gcd_done ;) {
    lt a2, a1, a0 ;     if(a > b)
?a2 sub a0, a0, a1 ;     { a -= b; } 
!a2 sub a1, a1, a0 ;     else { b -= a; }
    j zero, gcd_loop ;   }
gcd_done:
    add a0, zero, a1    ;   return b;
    jx zero, zero, ra ; }