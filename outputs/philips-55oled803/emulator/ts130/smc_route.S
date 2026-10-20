.syntax unified
.arch armv7ve
.arch_extension sec
.arm
.global _start
.section .text
_start:
    ldr sp, =0x400ff000
    mrs r0, cpsr
    and r0, r0, #31
    cmp r0, #0x1a
    bne svc_mode
    adr r0, svc_mode
    msr ELR_hyp, r0
    mov r0, #0xd3
    msr SPSR_cxsf, r0
    eret
svc_mode:
    ldr r8, =0x40020000
    ldr r9, =0x40030000
    mov r0, #123
    str r0, [r9]
    ldr r0, =0x545a3330
    ldr r1, =0x4010
    mov r2, r9
    mov r3, #64
    smc #0
    str r0, [r8], #4
    ldr r0, =0x545a3330
    ldr r1, =0x400d
    mov r2, #0
    mov r3, #0
    smc #0
    str r0, [r8], #4
    ldr r0, =0x545a3330
    ldr r1, =0x400f
    mov r2, r9
    mov r3, #64
    smc #0
    str r0, [r8], #4
    ldr r0, =0x545a3330
    ldr r1, =0x4010
    mov r2, r9
    mov r3, #64
    smc #0
    str r0, [r8], #4
    ldr r0, =0x545a3330
    ldr r1, =0x400f
    ldr r2, =0xf0000000
    mov r3, #64
    smc #0
    str r0, [r8], #4
    ldr r0, =0x545a3330
    ldr r1, =0x400e
    mov r2, r9
    mov r3, #64
    smc #0
    str r0, [r8], #4
    ldr r0, =0x84000000
    mov r1, #0
    mov r2, #0
    mov r3, #0
    smc #0
    str r0, [r8], #4
    ldr r0, =0x53544350
    str r0, [r8]
1:  wfi
    b 1b
