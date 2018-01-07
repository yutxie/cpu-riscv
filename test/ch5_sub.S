.org 0x0
 	.global _start
_start:
    ori x1,x0,0x1 # x1 = h1
    ori x2,x0,0x2 # x2 = h2
    sub x3,x2,x1  # x3 = x2 - x1 = h1
    sub x4,x1,x2  # x4 = x1 - x2 = hffffffff

    ; 93601000
    ; 13612000
    ; b3011140
    ; 33822040
