# https://mindfruit.co.uk/posts/2012/02/avx-matrix-mult-maybe/
# 4x4 matrix multiplication using ymm registers
# Todo: print the product of the 4x4 matrix multiplication
# [  1,  3,  5,  7 ]   [  2,  4,  6,  8 ]     [  304,   336,   368,   400 ]
# [  9, 11, 13, 15 ] x [ 10, 12, 14, 16 ]  =  [  752,   848,   944,  1040 ]
# [ 17, 19, 21, 23 ]   [ 18, 20, 22, 24 ]     [ 1200,  1360,  1520,  1680 ]
# [ 25, 27, 29, 31 ]   [ 26, 28, 30, 32 ]     [ 1648,  1872,  2096,  2320 ]


        .data
        .align 5
arr0:
        .double 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31
arr1:
        .double 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32

        .bss
        .align 5
        .lcomm  result, 0x80

        .text
        .globl _main
        .extern _printYMMReg
_main:
        push        %rbp                # aligned on a 16-byte boundary
        mov         %rsp, %rbp

# We align the stack on a 32-byte boundary. If the stack is aligned
# on a 32-byte boundary, it is also aligned on a 16-byte boundary.

        and         $-32, %rsp          # 0xFFFFFFFFFFFFFFE0
        sub         $0x40, %rsp
        leaq        arr0(%rip), %rbx
        leaq        arr1(%rip), %rdi
        leaq        result(%rip), %rdx

        vmovapd      (%rdi), %ymm0                       # load 2, 4, 6, 8

        vbroadcastsd 0x00(%rbx), %ymm1                   # load 1, 1, 1, 1
        vmulpd       %ymm1, %ymm0, %ymm12                # mul  2, 4, 6, 8     = 2, 4, 6, 8

        vbroadcastsd 0x20(%rbx), %ymm1                   # load 9, 9, 9, 9
        vmulpd       %ymm1, %ymm0, %ymm13                # mul  2, 4, 6, 8     = 18, 36, 54, 72

        vbroadcastsd 0x40(%rbx), %ymm1                   # load 17, 17, 17, 17
        vmulpd       %ymm1, %ymm0, %ymm14                # mul   2,  4,  6,  8 = 34, 68, 102, 136

        vbroadcastsd 0x60(%rbx), %ymm1                   # load 25, 25, 25, 25
        vmulpd       %ymm1, %ymm0, %ymm15                # mul   2,  4,  6,  8 = 50, 100, 150, 200
        
        xor          %rax, %rax
        mov          $0x03, %rcx                        # number of passes
.Lstart:
        inc          %rax
        add          $0x20, %rdi
        add          $0x20, %rdx

        vmovapd      (%rdi), %ymm0                       # On pass 1, load 10, 12, 14, 16

        vbroadcastsd 0x00(%rbx, %rax, 0x08), %ymm1       # load  3,  3,  3,  3
        vmulpd       %ymm1, %ymm0, %ymm2                 # mul  10, 12, 14, 16 = 30, 36, 42, 48
        vaddpd       %ymm2, %ymm12, %ymm12               # add   2,  4,  6,  8 = 32, 40, 48, 56

        vbroadcastsd 0x20(%rbx, %rax, 0x08), %ymm1       # load 11, 11, 11, 11
        vmulpd       %ymm1, %ymm0, %ymm2                 # mul  10, 12, 14, 16 = 110, 132, 154, 176
        vaddpd       %ymm2, %ymm13, %ymm13               # add  18, 36, 54, 72 = 128, 168, 208, 248

        vbroadcastsd 0x40(%rbx, %rax, 0x08), %ymm1       # load 19, 19,  19,  19
        vmulpd       %ymm1, %ymm0, %ymm2                 # mul  10, 12,  14,  16 = 190, 228, 266, 304
        vaddpd       %ymm2, %ymm14, %ymm14               # add  34, 68, 102, 136 = 224, 296, 368, 440

        vbroadcastsd 0x60(%rbx, %rax, 0x08), %ymm1       # load 27,  27,  27,  27
        vmulpd       %ymm1, %ymm0, %ymm2                 # mul  10,  12,  14,  16 = 270, 324, 378, 432
        vaddpd       %ymm2, %ymm15, %ymm15               # add  50, 100, 150, 200 = 320, 424, 528, 632

        dec          %rcx
        jnz          .Lstart
        
        vmovapd      %ymm12, 0x00+result(%rip)          # Write the result to memory. Check in GDB using
        vmovapd      %ymm13, 0x20+result(%rip)          # x/16fg &result
        vmovapd      %ymm14, 0x40+result(%rip)
        vmovapd      %ymm15, 0x60+result(%rip)

# Let's assume the function printYMMReg and clib function printf
# will not modify the regs, ymm12 - ymm15
#       vmovapd     0x00+result(%rip), %ymm0
        vmovapd      %ymm12, %ymm0
        call        _printYMMReg
#       vmovapd     0x20+result(%rip), %ymm0
        vmovapd      %ymm13, %ymm0
        call        _printYMMReg
#       vmovapd     0x40+result(%rip), %ymm0
        vmovapd      %ymm14, %ymm0
        call        _printYMMReg
#       vmovapd     0x60+result(%rip), %ymm0
        vmovapd      %ymm15, %ymm0
        call        _printYMMReg

        xor         %rax, %rax              # exit with 0 as error code
        mov         %rbp, %rsp              # restore the prologue's rsp
        pop         %rbp
        ret

