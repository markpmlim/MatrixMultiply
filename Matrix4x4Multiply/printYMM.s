# GAS
    .data

# Format string for printf (4 doubles)
# (lldb) p &fmt
fmt:
    .asciz "%lf %lf %lf %lf\n"

    .text
    .extern _printf
    .global _printYMMReg

# Called with the ymm0 register
# The xmm0-xmm3 registers are volatile
_printYMMReg:
# The prologue consists of 2 instructions.
    push    %rbp                # align stack on a 16-byte boundary
    mov     %rsp, %rbp          # save the contents of rsp in rbp

# We need a memory buffer to store the ymm0 contents
# We align the stack on a 32-byte boundary
    and     $-32, %rsp          # -32 = 0xFFFFFFFFFFFFFFE0
    sub     $0x20, %rsp         # Allocate 32 bytes (256 bits) on the stack for the YMM data
    vmovapd %ymm0, (%rsp)       # Move the aligned YMM register content to the stack memory

# Prepare arguments for printf
# The x86-64 ABI passes floating-point arguments in XMM registers
# We need to extract each double from the YMM reg in memory to separate XMM registers

# Load each double into the appropriate argument register (xmm0, xmm1, xmm2, xmm3)
# Note: xmmi regs are the lower 128 bits of the ymmi regs which are 256 bits
    movsd   24(%rsp), %xmm3     # 4th double (last part of the buffer)
    movsd   16(%rsp), %xmm2     # 3rd double
    movsd   8(%rsp), %xmm1      # 2nd double
    movsd   (%rsp), %xmm0       # 1st double (first part of the buffer)

# Set the first argument (format string) in the RDI register
    lea     fmt(%rip), %rdi

# Set AL to the number of vector arguments passed in XMM registers
# The C function printf does not work for single precision float points.
    mov     $4, %al             # # of doubles to be printed
    call    _printf

# The epilogue is consists of 2 instructions
    mov     %rbp, %rsp          # restore the prologue's rsp
    pop     %rbp
    ret
