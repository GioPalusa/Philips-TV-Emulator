
work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

0059fa24 <IMamb_Eng_Create>:
  59fa24:	e1a0c00d 	mov	ip, sp
  59fa28:	e59f127c 	ldr	r1, [pc, #636]	@ 59fcac <IMamb_Eng_Create+0x288>
  59fa2c:	e92ddff0 	push	{r4, r5, r6, r7, r8, r9, sl, fp, ip, lr, pc}
  59fa30:	e24cb004 	sub	fp, ip, #4
  59fa34:	e59f4274 	ldr	r4, [pc, #628]	@ 59fcb0 <IMamb_Eng_Create+0x28c>
  59fa38:	e24dd00c 	sub	sp, sp, #12
  59fa3c:	e1a02001 	mov	r2, r1
  59fa40:	e59f026c 	ldr	r0, [pc, #620]	@ 59fcb4 <IMamb_Eng_Create+0x290>
  59fa44:	ebfffffe 	bl	0 <printk>
			59fa44: R_ARM_CALL	printk
  59fa48:	e3a01000 	mov	r1, #0
  59fa4c:	e284200e 	add	r2, r4, #14
  59fa50:	e3a03002 	mov	r3, #2
  59fa54:	e3000464 	movw	r0, #1124	@ 0x464
  59fa58:	ebfffffe 	bl	1a8c <MGlueAmbR_NVMRead>
			59fa58: R_ARM_CALL	MGlueAmbR_NVMRead
  59fa5c:	e3a03001 	mov	r3, #1
  59fa60:	e3a01000 	mov	r1, #0
  59fa64:	e284201a 	add	r2, r4, #26
  59fa68:	e3000466 	movw	r0, #1126	@ 0x466
  59fa6c:	ebfffffe 	bl	1a8c <MGlueAmbR_NVMRead>
			59fa6c: R_ARM_CALL	MGlueAmbR_NVMRead
  59fa70:	e5d4200f 	ldrb	r2, [r4, #15]
  59fa74:	e59f1230 	ldr	r1, [pc, #560]	@ 59fcac <IMamb_Eng_Create+0x288>
  59fa78:	e59f0238 	ldr	r0, [pc, #568]	@ 59fcb8 <IMamb_Eng_Create+0x294>
  59fa7c:	e1a022a2 	lsr	r2, r2, #5
  59fa80:	ebfffffe 	bl	0 <printk>
			59fa80: R_ARM_CALL	printk
  59fa84:	ebfffffe 	bl	5a7768 <IMamb_Frc_StopFrcCmdSending>
			59fa84: R_ARM_CALL	IMamb_Frc_StopFrcCmdSending
  59fa88:	ebfffffe 	bl	5a22ec <IMamb_App_Init>
			59fa88: R_ARM_CALL	IMamb_App_Init
  59fa8c:	e5d4300e 	ldrb	r3, [r4, #14]
  59fa90:	e3530000 	cmp	r3, #0
  59fa94:	059f0220 	ldreq	r0, [pc, #544]	@ 59fcbc <IMamb_Eng_Create+0x298>
  59fa98:	0a00007d 	beq	59fc94 <IMamb_Eng_Create+0x270>
  59fa9c:	e24b0030 	sub	r0, fp, #48	@ 0x30
  59faa0:	ebfffffe 	bl	5a3764 <IMamb_Fms_GetMode>
			59faa0: R_ARM_CALL	IMamb_Fms_GetMode
  59faa4:	e51b5030 	ldr	r5, [fp, #-48]	@ 0xffffffd0
  59faa8:	e3550000 	cmp	r5, #0
  59faac:	159f020c 	ldrne	r0, [pc, #524]	@ 59fcc0 <IMamb_Eng_Create+0x29c>
  59fab0:	1a000077 	bne	59fc94 <IMamb_Eng_Create+0x270>
  59fab4:	e59f3208 	ldr	r3, [pc, #520]	@ 59fcc4 <IMamb_Eng_Create+0x2a0>
  59fab8:	e30f2fff 	movw	r2, #65535	@ 0xffff
  59fabc:	e5832004 	str	r2, [r3, #4]
  59fac0:	ebfffffe 	bl	59ee28 <IMamb_Eng_SetSunsetFinished>
			59fac0: R_ARM_CALL	IMamb_Eng_SetSunsetFinished
  59fac4:	e5c4500c 	strb	r5, [r4, #12]
  59fac8:	ebfffffe 	bl	5a2e58 <IMamb_Fms_Create>
			59fac8: R_ARM_CALL	IMamb_Fms_Create
  59facc:	e2842018 	add	r2, r4, #24
  59fad0:	e3a01000 	mov	r1, #0
  59fad4:	e3a03001 	mov	r3, #1
  59fad8:	e3000461 	movw	r0, #1121	@ 0x461
  59fadc:	ebfffffe 	bl	1a8c <MGlueAmbR_NVMRead>
			59fadc: R_ARM_CALL	MGlueAmbR_NVMRead
  59fae0:	e284201b 	add	r2, r4, #27
  59fae4:	e3a01000 	mov	r1, #0
  59fae8:	e3a03002 	mov	r3, #2
  59faec:	e3000462 	movw	r0, #1122	@ 0x462
  59faf0:	e5d4a018 	ldrb	sl, [r4, #24]
  59faf4:	ebfffffe 	bl	1a8c <MGlueAmbR_NVMRead>
			59faf4: R_ARM_CALL	MGlueAmbR_NVMRead
  59faf8:	e5d4301c 	ldrb	r3, [r4, #28]
  59fafc:	e1a02004 	mov	r2, r4
  59fb00:	e5e2501d 	strb	r5, [r2, #29]!
  59fb04:	e3a01000 	mov	r1, #0
  59fb08:	e3a00c3f 	mov	r0, #16128	@ 0x3f00
  59fb0c:	e1a0a2aa 	lsr	sl, sl, #5
  59fb10:	e7e130d3 	ubfx	r3, r3, #1, #2
  59fb14:	e5843014 	str	r3, [r4, #20]
  59fb18:	e3a03001 	mov	r3, #1
  59fb1c:	ebfffffe 	bl	1aac <MGlueAmbR_NVMWrite>
			59fb1c: R_ARM_CALL	MGlueAmbR_NVMWrite
  59fb20:	e284201e 	add	r2, r4, #30
  59fb24:	e3a01000 	mov	r1, #0
  59fb28:	e3a03001 	mov	r3, #1
  59fb2c:	e3000466 	movw	r0, #1126	@ 0x466
  59fb30:	ebfffffe 	bl	1a8c <MGlueAmbR_NVMRead>
			59fb30: R_ARM_CALL	MGlueAmbR_NVMRead
  59fb34:	e5d4300e 	ldrb	r3, [r4, #14]
  59fb38:	e5d4600f 	ldrb	r6, [r4, #15]
  59fb3c:	e5d4701e 	ldrb	r7, [r4, #30]
  59fb40:	e2030007 	and	r0, r3, #7
  59fb44:	e7e311d3 	ubfx	r1, r3, #3, #4
  59fb48:	e1a033a3 	lsr	r3, r3, #7
  59fb4c:	e2062007 	and	r2, r6, #7
  59fb50:	e7e191d6 	ubfx	r9, r6, #3, #2
  59fb54:	e5c41021 	strb	r1, [r4, #33]	@ 0x21
  59fb58:	e1832082 	orr	r2, r3, r2, lsl #1
  59fb5c:	e1a03009 	mov	r3, r9
  59fb60:	e5c40022 	strb	r0, [r4, #34]	@ 0x22
  59fb64:	e1a062a6 	lsr	r6, r6, #5
  59fb68:	e5c42023 	strb	r2, [r4, #35]	@ 0x23
  59fb6c:	e1a07327 	lsr	r7, r7, #6
  59fb70:	e5c40020 	strb	r0, [r4, #32]
  59fb74:	ebfffffe 	bl	5a1d24 <IMamb_App_GetArchIndex>
			59fb74: R_ARM_CALL	IMamb_App_GetArchIndex
  59fb78:	e5d42020 	ldrb	r2, [r4, #32]
  59fb7c:	e1a08000 	mov	r8, r0
  59fb80:	e59f1124 	ldr	r1, [pc, #292]	@ 59fcac <IMamb_Eng_Create+0x288>
  59fb84:	e59f013c 	ldr	r0, [pc, #316]	@ 59fcc8 <IMamb_Eng_Create+0x2a4>
  59fb88:	e5845008 	str	r5, [r4, #8]
  59fb8c:	ebfffffe 	bl	0 <printk>
			59fb8c: R_ARM_CALL	printk
  59fb90:	e5d42021 	ldrb	r2, [r4, #33]	@ 0x21
  59fb94:	e59f1110 	ldr	r1, [pc, #272]	@ 59fcac <IMamb_Eng_Create+0x288>
  59fb98:	e59f012c 	ldr	r0, [pc, #300]	@ 59fccc <IMamb_Eng_Create+0x2a8>
  59fb9c:	ebfffffe 	bl	0 <printk>
			59fb9c: R_ARM_CALL	printk
  59fba0:	e5d42023 	ldrb	r2, [r4, #35]	@ 0x23
  59fba4:	e59f1100 	ldr	r1, [pc, #256]	@ 59fcac <IMamb_Eng_Create+0x288>
  59fba8:	e59f0120 	ldr	r0, [pc, #288]	@ 59fcd0 <IMamb_Eng_Create+0x2ac>
  59fbac:	ebfffffe 	bl	0 <printk>
			59fbac: R_ARM_CALL	printk
  59fbb0:	e59f10f4 	ldr	r1, [pc, #244]	@ 59fcac <IMamb_Eng_Create+0x288>
  59fbb4:	e1a02009 	mov	r2, r9
  59fbb8:	e59f0114 	ldr	r0, [pc, #276]	@ 59fcd4 <IMamb_Eng_Create+0x2b0>
  59fbbc:	ebfffffe 	bl	0 <printk>
			59fbbc: R_ARM_CALL	printk
  59fbc0:	e59f10e4 	ldr	r1, [pc, #228]	@ 59fcac <IMamb_Eng_Create+0x288>
  59fbc4:	e1a02006 	mov	r2, r6
  59fbc8:	e59f00e8 	ldr	r0, [pc, #232]	@ 59fcb8 <IMamb_Eng_Create+0x294>
  59fbcc:	ebfffffe 	bl	0 <printk>
			59fbcc: R_ARM_CALL	printk
  59fbd0:	e1a0200a 	mov	r2, sl
  59fbd4:	e59f10d0 	ldr	r1, [pc, #208]	@ 59fcac <IMamb_Eng_Create+0x288>
  59fbd8:	e59f00f8 	ldr	r0, [pc, #248]	@ 59fcd8 <IMamb_Eng_Create+0x2b4>
  59fbdc:	e284a09e 	add	sl, r4, #158	@ 0x9e
  59fbe0:	e2844026 	add	r4, r4, #38	@ 0x26
  59fbe4:	ebfffffe 	bl	0 <printk>
			59fbe4: R_ARM_CALL	printk
  59fbe8:	e59f00ec 	ldr	r0, [pc, #236]	@ 59fcdc <IMamb_Eng_Create+0x2b8>
  59fbec:	e1a02007 	mov	r2, r7
  59fbf0:	e59f10b4 	ldr	r1, [pc, #180]	@ 59fcac <IMamb_Eng_Create+0x288>
  59fbf4:	ebfffffe 	bl	0 <printk>
			59fbf4: R_ARM_CALL	printk
  59fbf8:	e6ef9075 	uxtb	r9, r5
  59fbfc:	e08a2005 	add	r2, sl, r5
  59fc00:	e1a00008 	mov	r0, r8
  59fc04:	e1a01009 	mov	r1, r9
  59fc08:	ebfffffe 	bl	5a1dd8 <IMamb_App_GetBoardMapVal>
			59fc08: R_ARM_CALL	IMamb_App_GetBoardMapVal
  59fc0c:	e0842085 	add	r2, r4, r5, lsl #1
  59fc10:	e1a00008 	mov	r0, r8
  59fc14:	e1a01009 	mov	r1, r9
  59fc18:	e2855001 	add	r5, r5, #1
  59fc1c:	ebfffffe 	bl	5a1df8 <IMamb_App_GetPixelMapVal>
			59fc1c: R_ARM_CALL	IMamb_App_GetPixelMapVal
  59fc20:	e355003c 	cmp	r5, #60	@ 0x3c
  59fc24:	1afffff3 	bne	59fbf8 <IMamb_Eng_Create+0x1d4>
  59fc28:	ebfffffe 	bl	5a0318 <IMamb_App_SetDefaultAlignment>
			59fc28: R_ARM_CALL	IMamb_App_SetDefaultAlignment
  59fc2c:	e59f00ac 	ldr	r0, [pc, #172]	@ 59fce0 <IMamb_Eng_Create+0x2bc>
  59fc30:	ebfffffe 	bl	59e74c <IMamb_Eng_SetArchitecture>
			59fc30: R_ARM_CALL	IMamb_Eng_SetArchitecture
  59fc34:	e3560005 	cmp	r6, #5
  59fc38:	979ff106 	ldrls	pc, [pc, r6, lsl #2]
  59fc3c:	ea00000d 	b	59fc78 <IMamb_Eng_Create+0x254>
  59fc40:	0059fc58 	subseq	pc, r9, r8, asr ip	@ <UNPREDICTABLE>
			59fc40: R_ARM_ABS32	.text
  59fc44:	0059fc64 	subseq	pc, r9, r4, ror #24
			59fc44: R_ARM_ABS32	.text
  59fc48:	0059fc58 	subseq	pc, r9, r8, asr ip	@ <UNPREDICTABLE>
			59fc48: R_ARM_ABS32	.text
  59fc4c:	0059fc64 	subseq	pc, r9, r4, ror #24
			59fc4c: R_ARM_ABS32	.text
  59fc50:	0059fc6c 	subseq	pc, r9, ip, ror #24
			59fc50: R_ARM_ABS32	.text
  59fc54:	0059fc6c 	subseq	pc, r9, ip, ror #24
			59fc54: R_ARM_ABS32	.text
  59fc58:	e3a00000 	mov	r0, #0
  59fc5c:	e1a01000 	mov	r1, r0
  59fc60:	ea000003 	b	59fc74 <IMamb_Eng_Create+0x250>
  59fc64:	e3a00001 	mov	r0, #1
  59fc68:	ea000000 	b	59fc70 <IMamb_Eng_Create+0x24c>
  59fc6c:	e3a00002 	mov	r0, #2
  59fc70:	e3a01000 	mov	r1, #0
  59fc74:	ebfffffe 	bl	59e6e8 <IMamb_Eng_SetHwSelection>
			59fc74: R_ARM_CALL	IMamb_Eng_SetHwSelection
  59fc78:	e3570000 	cmp	r7, #0
  59fc7c:	0a000001 	beq	59fc88 <IMamb_Eng_Create+0x264>
  59fc80:	e3a00001 	mov	r0, #1
  59fc84:	ebfffffe 	bl	59e9f4 <IMamb_Eng_SetMirrorAndFlipCorrection>
			59fc84: R_ARM_CALL	IMamb_Eng_SetMirrorAndFlipCorrection
  59fc88:	e3a00001 	mov	r0, #1
  59fc8c:	ebfffffe 	bl	59f998 <IMamb_Eng_SetAmbilightSpiCtrl>
			59fc8c: R_ARM_CALL	IMamb_Eng_SetAmbilightSpiCtrl
  59fc90:	e59f004c 	ldr	r0, [pc, #76]	@ 59fce4 <IMamb_Eng_Create+0x2c0>
  59fc94:	e59f1010 	ldr	r1, [pc, #16]	@ 59fcac <IMamb_Eng_Create+0x288>
  59fc98:	e1a02001 	mov	r2, r1
  59fc9c:	ebfffffe 	bl	0 <printk>
			59fc9c: R_ARM_CALL	printk
  59fca0:	e3a00001 	mov	r0, #1
  59fca4:	e24bd028 	sub	sp, fp, #40	@ 0x28
  59fca8:	e89daff0 	ldm	sp, {r4, r5, r6, r7, r8, r9, sl, fp, sp, pc}
  59fcac:	00085c25 	andeq	r5, r8, r5, lsr #24
			59fcac: R_ARM_ABS32	.rodata
  59fcb0:	000c28b8 			@ <UNDEFINED> instruction: 0x000c28b8
			59fcb0: R_ARM_ABS32	.bss
  59fcb4:	000f694a 	andeq	r6, pc, sl, asr #18
			59fcb4: R_ARM_ABS32	.rodata.str1.1
  59fcb8:	000f695f 	andeq	r6, pc, pc, asr r9	@ <UNPREDICTABLE>
			59fcb8: R_ARM_ABS32	.rodata.str1.1
  59fcbc:	000f6981 	andeq	r6, pc, r1, lsl #19
			59fcbc: R_ARM_ABS32	.rodata.str1.1
  59fcc0:	000f69a4 	andeq	r6, pc, r4, lsr #19
			59fcc0: R_ARM_ABS32	.rodata.str1.1
  59fcc4:	00089484 	andeq	r9, r8, r4, lsl #9
			59fcc4: R_ARM_ABS32	.data
  59fcc8:	000f69d3 	ldrdeq	r6, [pc], -r3
			59fcc8: R_ARM_ABS32	.rodata.str1.1
  59fccc:	000f69f0 	strdeq	r6, [pc], -r0
			59fccc: R_ARM_ABS32	.rodata.str1.1
  59fcd0:	000f6a0c 	andeq	r6, pc, ip, lsl #20
			59fcd0: R_ARM_ABS32	.rodata.str1.1
  59fcd4:	000f6a2b 	andeq	r6, pc, fp, lsr #20
			59fcd4: R_ARM_ABS32	.rodata.str1.1
  59fcd8:	000f6a4b 	andeq	r6, pc, fp, asr #20
			59fcd8: R_ARM_ABS32	.rodata.str1.1
  59fcdc:	000f6a5e 	andeq	r6, pc, lr, asr sl	@ <UNPREDICTABLE>
			59fcdc: R_ARM_ABS32	.rodata.str1.1
  59fce0:	000c28d8 	ldrdeq	r2, [ip], -r8
			59fce0: R_ARM_ABS32	.bss
  59fce4:	000f6a79 	andeq	r6, pc, r9, ror sl	@ <UNPREDICTABLE>
			59fce4: R_ARM_ABS32	.rodata.str1.1

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:


work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

005a1d24 <IMamb_App_GetArchIndex>:
  5a1d24:	e1a0c00d 	mov	ip, sp
  5a1d28:	e92dd830 	push	{r4, r5, fp, ip, lr, pc}
  5a1d2c:	e24cb004 	sub	fp, ip, #4
  5a1d30:	e59fc08c 	ldr	ip, [pc, #140]	@ 5a1dc4 <IMamb_App_GetArchIndex+0xa0>
  5a1d34:	e24dd010 	sub	sp, sp, #16
  5a1d38:	e1a0e003 	mov	lr, r3
  5a1d3c:	e3a03000 	mov	r3, #0
  5a1d40:	e5dc5000 	ldrb	r5, [ip]
  5a1d44:	e6ef4073 	uxtb	r4, r3
  5a1d48:	e1550000 	cmp	r5, r0
  5a1d4c:	1a000008 	bne	5a1d74 <IMamb_App_GetArchIndex+0x50>
  5a1d50:	e5dc5001 	ldrb	r5, [ip, #1]
  5a1d54:	e1550001 	cmp	r5, r1
  5a1d58:	1a000005 	bne	5a1d74 <IMamb_App_GetArchIndex+0x50>
  5a1d5c:	e5dc5002 	ldrb	r5, [ip, #2]
  5a1d60:	e1550002 	cmp	r5, r2
  5a1d64:	1a000002 	bne	5a1d74 <IMamb_App_GetArchIndex+0x50>
  5a1d68:	e5dc5003 	ldrb	r5, [ip, #3]
  5a1d6c:	e155000e 	cmp	r5, lr
  5a1d70:	0a000009 	beq	5a1d9c <IMamb_App_GetArchIndex+0x78>
  5a1d74:	e2833001 	add	r3, r3, #1
  5a1d78:	e28cc004 	add	ip, ip, #4
  5a1d7c:	e3530018 	cmp	r3, #24
  5a1d80:	1affffee 	bne	5a1d40 <IMamb_App_GetArchIndex+0x1c>
  5a1d84:	e59f103c 	ldr	r1, [pc, #60]	@ 5a1dc8 <IMamb_App_GetArchIndex+0xa4>
  5a1d88:	e3a0400a 	mov	r4, #10
  5a1d8c:	e59f0038 	ldr	r0, [pc, #56]	@ 5a1dcc <IMamb_App_GetArchIndex+0xa8>
  5a1d90:	e1a02001 	mov	r2, r1
  5a1d94:	ebfffffe 	bl	0 <printk>
			5a1d94: R_ARM_CALL	printk
  5a1d98:	ea000004 	b	5a1db0 <IMamb_App_GetArchIndex+0x8c>
  5a1d9c:	e88d4007 	stm	sp, {r0, r1, r2, lr}
  5a1da0:	e59f1020 	ldr	r1, [pc, #32]	@ 5a1dc8 <IMamb_App_GetArchIndex+0xa4>
  5a1da4:	e59f0024 	ldr	r0, [pc, #36]	@ 5a1dd0 <IMamb_App_GetArchIndex+0xac>
  5a1da8:	e1a02001 	mov	r2, r1
  5a1dac:	ebfffffe 	bl	0 <printk>
			5a1dac: R_ARM_CALL	printk
  5a1db0:	e59f301c 	ldr	r3, [pc, #28]	@ 5a1dd4 <IMamb_App_GetArchIndex+0xb0>
  5a1db4:	e1a00004 	mov	r0, r4
  5a1db8:	e5c34478 	strb	r4, [r3, #1144]	@ 0x478
  5a1dbc:	e24bd014 	sub	sp, fp, #20
  5a1dc0:	e89da830 	ldm	sp, {r4, r5, fp, sp, pc}
  5a1dc4:	000c2b0c 	andeq	r2, ip, ip, lsl #22
			5a1dc4: R_ARM_ABS32	.bss
  5a1dc8:	00087007 	andeq	r7, r8, r7
			5a1dc8: R_ARM_ABS32	.rodata
  5a1dcc:	000f6cbd 			@ <UNDEFINED> instruction: 0x000f6cbd
			5a1dcc: R_ARM_ABS32	.rodata.str1.1
  5a1dd0:	000f6d28 	andeq	r6, pc, r8, lsr #26
			5a1dd0: R_ARM_ABS32	.rodata.str1.1
  5a1dd4:	000c49d0 	ldrdeq	r4, [ip], -r0
			5a1dd4: R_ARM_ABS32	.bss

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:


work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

0059ff48 <IMamb_App_UpdateDefaultTuningData>:
  59ff48:	e1a0c00d 	mov	ip, sp
  59ff4c:	e59f0354 	ldr	r0, [pc, #852]	@ 5a02a8 <IMamb_App_UpdateDefaultTuningData+0x360>
  59ff50:	e92dd818 	push	{r3, r4, fp, ip, lr, pc}
  59ff54:	e24cb004 	sub	fp, ip, #4
  59ff58:	e59f134c 	ldr	r1, [pc, #844]	@ 5a02ac <IMamb_App_UpdateDefaultTuningData+0x364>
  59ff5c:	ebfffffe 	bl	0 <printk>
			59ff5c: R_ARM_CALL	printk
  59ff60:	e59f4348 	ldr	r4, [pc, #840]	@ 5a02b0 <IMamb_App_UpdateDefaultTuningData+0x368>
  59ff64:	e3a03000 	mov	r3, #0
  59ff68:	e59fe344 	ldr	lr, [pc, #836]	@ 5a02b4 <IMamb_App_UpdateDefaultTuningData+0x36c>
  59ff6c:	e7d32004 	ldrb	r2, [r3, r4]
  59ff70:	e59f1340 	ldr	r1, [pc, #832]	@ 5a02b8 <IMamb_App_UpdateDefaultTuningData+0x370>
  59ff74:	e7c3200e 	strb	r2, [r3, lr]
  59ff78:	e59f233c 	ldr	r2, [pc, #828]	@ 5a02bc <IMamb_App_UpdateDefaultTuningData+0x374>
  59ff7c:	e7d30002 	ldrb	r0, [r3, r2]
  59ff80:	e282c004 	add	ip, r2, #4
  59ff84:	e7d3c00c 	ldrb	ip, [r3, ip]
  59ff88:	e7c30001 	strb	r0, [r3, r1]
  59ff8c:	e2810004 	add	r0, r1, #4
  59ff90:	e7c3c000 	strb	ip, [r3, r0]
  59ff94:	e282c008 	add	ip, r2, #8
  59ff98:	e7d3c00c 	ldrb	ip, [r3, ip]
  59ff9c:	e2810008 	add	r0, r1, #8
  59ffa0:	e7c3c000 	strb	ip, [r3, r0]
  59ffa4:	e282c00c 	add	ip, r2, #12
  59ffa8:	e7d3c00c 	ldrb	ip, [r3, ip]
  59ffac:	e281000c 	add	r0, r1, #12
  59ffb0:	e7c3c000 	strb	ip, [r3, r0]
  59ffb4:	e282c010 	add	ip, r2, #16
  59ffb8:	e7d3c00c 	ldrb	ip, [r3, ip]
  59ffbc:	e2810010 	add	r0, r1, #16
  59ffc0:	e7c3c000 	strb	ip, [r3, r0]
  59ffc4:	e282c014 	add	ip, r2, #20
  59ffc8:	e7d3c00c 	ldrb	ip, [r3, ip]
  59ffcc:	e2810014 	add	r0, r1, #20
  59ffd0:	e7c3c000 	strb	ip, [r3, r0]
  59ffd4:	e2833001 	add	r3, r3, #1
  59ffd8:	e3530004 	cmp	r3, #4
  59ffdc:	1affffe2 	bne	59ff6c <IMamb_App_UpdateDefaultTuningData+0x24>
  59ffe0:	e3a03000 	mov	r3, #0
  59ffe4:	e2811018 	add	r1, r1, #24
  59ffe8:	e2824018 	add	r4, r2, #24
  59ffec:	e7d32004 	ldrb	r2, [r3, r4]
  59fff0:	e59f02c8 	ldr	r0, [pc, #712]	@ 5a02c0 <IMamb_App_UpdateDefaultTuningData+0x378>
  59fff4:	e7c32001 	strb	r2, [r3, r1]
  59fff8:	e59f22c4 	ldr	r2, [pc, #708]	@ 5a02c4 <IMamb_App_UpdateDefaultTuningData+0x37c>
  59fffc:	e7d3c002 	ldrb	ip, [r3, r2]
  5a0000:	e282e007 	add	lr, r2, #7
  5a0004:	e7d3e00e 	ldrb	lr, [r3, lr]
  5a0008:	e7c3c000 	strb	ip, [r3, r0]
  5a000c:	e280c007 	add	ip, r0, #7
  5a0010:	e7c3e00c 	strb	lr, [r3, ip]
  5a0014:	e282e00e 	add	lr, r2, #14
  5a0018:	e7d3e00e 	ldrb	lr, [r3, lr]
  5a001c:	e280c00e 	add	ip, r0, #14
  5a0020:	e7c3e00c 	strb	lr, [r3, ip]
  5a0024:	e282e015 	add	lr, r2, #21
  5a0028:	e7d3e00e 	ldrb	lr, [r3, lr]
  5a002c:	e280c015 	add	ip, r0, #21
  5a0030:	e7c3e00c 	strb	lr, [r3, ip]
  5a0034:	e282e01c 	add	lr, r2, #28
  5a0038:	e7d3e00e 	ldrb	lr, [r3, lr]
  5a003c:	e280c01c 	add	ip, r0, #28
  5a0040:	e2800023 	add	r0, r0, #35	@ 0x23
  5a0044:	e7c3e00c 	strb	lr, [r3, ip]
  5a0048:	e282c023 	add	ip, r2, #35	@ 0x23
  5a004c:	e7d3c00c 	ldrb	ip, [r3, ip]
  5a0050:	e7c3c000 	strb	ip, [r3, r0]
  5a0054:	e2833001 	add	r3, r3, #1
  5a0058:	e3530007 	cmp	r3, #7
  5a005c:	1affffe2 	bne	59ffec <IMamb_App_UpdateDefaultTuningData+0xa4>
  5a0060:	e3a00000 	mov	r0, #0
  5a0064:	e282402a 	add	r4, r2, #42	@ 0x2a
  5a0068:	e1a03000 	mov	r3, r0
  5a006c:	e59f2240 	ldr	r2, [pc, #576]	@ 5a02b4 <IMamb_App_UpdateDefaultTuningData+0x36c>
  5a0070:	e7d3c004 	ldrb	ip, [r3, r4]
  5a0074:	e282104d 	add	r1, r2, #77	@ 0x4d
  5a0078:	e7c3c001 	strb	ip, [r3, r1]
  5a007c:	e282c056 	add	ip, r2, #86	@ 0x56
  5a0080:	e59f1240 	ldr	r1, [pc, #576]	@ 5a02c8 <IMamb_App_UpdateDefaultTuningData+0x380>
  5a0084:	e7d3e001 	ldrb	lr, [r3, r1]
  5a0088:	e7c3e00c 	strb	lr, [r3, ip]
  5a008c:	e281e009 	add	lr, r1, #9
  5a0090:	e7d3e00e 	ldrb	lr, [r3, lr]
  5a0094:	e282c05f 	add	ip, r2, #95	@ 0x5f
  5a0098:	e7c3e00c 	strb	lr, [r3, ip]
  5a009c:	e281e012 	add	lr, r1, #18
  5a00a0:	e7d3e00e 	ldrb	lr, [r3, lr]
  5a00a4:	e282c068 	add	ip, r2, #104	@ 0x68
  5a00a8:	e7c3e00c 	strb	lr, [r3, ip]
  5a00ac:	e281e01b 	add	lr, r1, #27
  5a00b0:	e7d3e00e 	ldrb	lr, [r3, lr]
  5a00b4:	e282c071 	add	ip, r2, #113	@ 0x71
  5a00b8:	e7c3e00c 	strb	lr, [r3, ip]
  5a00bc:	e281e024 	add	lr, r1, #36	@ 0x24
  5a00c0:	e190e0be 	ldrh	lr, [r0, lr]
  5a00c4:	e282c07a 	add	ip, r2, #122	@ 0x7a
  5a00c8:	e180e0bc 	strh	lr, [r0, ip]
  5a00cc:	e281e036 	add	lr, r1, #54	@ 0x36
  5a00d0:	e190e0be 	ldrh	lr, [r0, lr]
  5a00d4:	e282c08c 	add	ip, r2, #140	@ 0x8c
  5a00d8:	e180e0bc 	strh	lr, [r0, ip]
  5a00dc:	e281e048 	add	lr, r1, #72	@ 0x48
  5a00e0:	e7d3e00e 	ldrb	lr, [r3, lr]
  5a00e4:	e282c09e 	add	ip, r2, #158	@ 0x9e
  5a00e8:	e2800002 	add	r0, r0, #2
  5a00ec:	e7c3e00c 	strb	lr, [r3, ip]
  5a00f0:	e281e051 	add	lr, r1, #81	@ 0x51
  5a00f4:	e7d3e00e 	ldrb	lr, [r3, lr]
  5a00f8:	e282c0a7 	add	ip, r2, #167	@ 0xa7
  5a00fc:	e7c3e00c 	strb	lr, [r3, ip]
  5a0100:	e281e05a 	add	lr, r1, #90	@ 0x5a
  5a0104:	e7d3e00e 	ldrb	lr, [r3, lr]
  5a0108:	e282c0b0 	add	ip, r2, #176	@ 0xb0
  5a010c:	e7c3e00c 	strb	lr, [r3, ip]
  5a0110:	e281e063 	add	lr, r1, #99	@ 0x63
  5a0114:	e7d3e00e 	ldrb	lr, [r3, lr]
  5a0118:	e282c0b9 	add	ip, r2, #185	@ 0xb9
  5a011c:	e7c3e00c 	strb	lr, [r3, ip]
  5a0120:	e281e06c 	add	lr, r1, #108	@ 0x6c
  5a0124:	e7d3e00e 	ldrb	lr, [r3, lr]
  5a0128:	e282c0c2 	add	ip, r2, #194	@ 0xc2
  5a012c:	e7c3e00c 	strb	lr, [r3, ip]
  5a0130:	e281e075 	add	lr, r1, #117	@ 0x75
  5a0134:	e7d3e00e 	ldrb	lr, [r3, lr]
  5a0138:	e282c0cb 	add	ip, r2, #203	@ 0xcb
  5a013c:	e7c3e00c 	strb	lr, [r3, ip]
  5a0140:	e2833001 	add	r3, r3, #1
  5a0144:	e3530009 	cmp	r3, #9
  5a0148:	1affffc7 	bne	5a006c <IMamb_App_UpdateDefaultTuningData+0x124>
  5a014c:	e3a03020 	mov	r3, #32
  5a0150:	e28220de 	add	r2, r2, #222	@ 0xde
  5a0154:	e542300a 	strb	r3, [r2, #-10]
  5a0158:	e281107e 	add	r1, r1, #126	@ 0x7e
  5a015c:	e5423005 	strb	r3, [r2, #-5]
  5a0160:	e3a0302c 	mov	r3, #44	@ 0x2c
  5a0164:	e5423009 	strb	r3, [r2, #-9]
  5a0168:	e5423004 	strb	r3, [r2, #-4]
  5a016c:	e3a03040 	mov	r3, #64	@ 0x40
  5a0170:	e5423008 	strb	r3, [r2, #-8]
  5a0174:	e5423003 	strb	r3, [r2, #-3]
  5a0178:	e3a03060 	mov	r3, #96	@ 0x60
  5a017c:	e5423007 	strb	r3, [r2, #-7]
  5a0180:	e5423002 	strb	r3, [r2, #-2]
  5a0184:	e3e0307f 	mvn	r3, #127	@ 0x7f
  5a0188:	e5423006 	strb	r3, [r2, #-6]
  5a018c:	e5423001 	strb	r3, [r2, #-1]
  5a0190:	e3a03000 	mov	r3, #0
  5a0194:	e7d30001 	ldrb	r0, [r3, r1]
  5a0198:	e7c30002 	strb	r0, [r3, r2]
  5a019c:	e2833001 	add	r3, r3, #1
  5a01a0:	e353000b 	cmp	r3, #11
  5a01a4:	1afffffa 	bne	5a0194 <IMamb_App_UpdateDefaultTuningData+0x24c>
  5a01a8:	e59f211c 	ldr	r2, [pc, #284]	@ 5a02cc <IMamb_App_UpdateDefaultTuningData+0x384>
  5a01ac:	e3a03000 	mov	r3, #0
  5a01b0:	e59f0118 	ldr	r0, [pc, #280]	@ 5a02d0 <IMamb_App_UpdateDefaultTuningData+0x388>
  5a01b4:	e7d31000 	ldrb	r1, [r3, r0]
  5a01b8:	e7c31002 	strb	r1, [r3, r2]
  5a01bc:	e2833001 	add	r3, r3, #1
  5a01c0:	e353000b 	cmp	r3, #11
  5a01c4:	1afffffa 	bne	5a01b4 <IMamb_App_UpdateDefaultTuningData+0x26c>
  5a01c8:	e59fc104 	ldr	ip, [pc, #260]	@ 5a02d4 <IMamb_App_UpdateDefaultTuningData+0x38c>
  5a01cc:	e3a03000 	mov	r3, #0
  5a01d0:	e59fe100 	ldr	lr, [pc, #256]	@ 5a02d8 <IMamb_App_UpdateDefaultTuningData+0x390>
  5a01d4:	e7d3200e 	ldrb	r2, [r3, lr]
  5a01d8:	e59f10fc 	ldr	r1, [pc, #252]	@ 5a02dc <IMamb_App_UpdateDefaultTuningData+0x394>
  5a01dc:	e7c3200c 	strb	r2, [r3, ip]
  5a01e0:	e7d30001 	ldrb	r0, [r3, r1]
  5a01e4:	e59f20f4 	ldr	r2, [pc, #244]	@ 5a02e0 <IMamb_App_UpdateDefaultTuningData+0x398>
  5a01e8:	e7c30002 	strb	r0, [r3, r2]
  5a01ec:	e2833001 	add	r3, r3, #1
  5a01f0:	e3530020 	cmp	r3, #32
  5a01f4:	1afffff6 	bne	5a01d4 <IMamb_App_UpdateDefaultTuningData+0x28c>
  5a01f8:	e2813020 	add	r3, r1, #32
  5a01fc:	e2811080 	add	r1, r1, #128	@ 0x80
  5a0200:	e2822020 	add	r2, r2, #32
  5a0204:	e1a00001 	mov	r0, r1
  5a0208:	e5d3c000 	ldrb	ip, [r3]
  5a020c:	e2833004 	add	r3, r3, #4
  5a0210:	e2822004 	add	r2, r2, #4
  5a0214:	e542c004 	strb	ip, [r2, #-4]
  5a0218:	e553c003 	ldrb	ip, [r3, #-3]
  5a021c:	e542c003 	strb	ip, [r2, #-3]
  5a0220:	e553c002 	ldrb	ip, [r3, #-2]
  5a0224:	e542c002 	strb	ip, [r2, #-2]
  5a0228:	e553c001 	ldrb	ip, [r3, #-1]
  5a022c:	e1530001 	cmp	r3, r1
  5a0230:	e542c001 	strb	ip, [r2, #-1]
  5a0234:	1afffff3 	bne	5a0208 <IMamb_App_UpdateDefaultTuningData+0x2c0>
  5a0238:	e59fe0a4 	ldr	lr, [pc, #164]	@ 5a02e4 <IMamb_App_UpdateDefaultTuningData+0x39c>
  5a023c:	e3a03000 	mov	r3, #0
  5a0240:	e3a02000 	mov	r2, #0
  5a0244:	e083c00e 	add	ip, r3, lr
  5a0248:	e0801003 	add	r1, r0, r3
  5a024c:	e7d14002 	ldrb	r4, [r1, r2]
  5a0250:	e7cc4002 	strb	r4, [ip, r2]
  5a0254:	e2822001 	add	r2, r2, #1
  5a0258:	e352003c 	cmp	r2, #60	@ 0x3c
  5a025c:	1afffffa 	bne	5a024c <IMamb_App_UpdateDefaultTuningData+0x304>
  5a0260:	e283303c 	add	r3, r3, #60	@ 0x3c
  5a0264:	e3530e5a 	cmp	r3, #1440	@ 0x5a0
  5a0268:	1afffff4 	bne	5a0240 <IMamb_App_UpdateDefaultTuningData+0x2f8>
  5a026c:	e59fe074 	ldr	lr, [pc, #116]	@ 5a02e8 <IMamb_App_UpdateDefaultTuningData+0x3a0>
  5a0270:	e3a03000 	mov	r3, #0
  5a0274:	e59f0070 	ldr	r0, [pc, #112]	@ 5a02ec <IMamb_App_UpdateDefaultTuningData+0x3a4>
  5a0278:	e3a02000 	mov	r2, #0
  5a027c:	e083c00e 	add	ip, r3, lr
  5a0280:	e0831000 	add	r1, r3, r0
  5a0284:	e19140b2 	ldrh	r4, [r1, r2]
  5a0288:	e18c40b2 	strh	r4, [ip, r2]
  5a028c:	e2822002 	add	r2, r2, #2
  5a0290:	e3520078 	cmp	r2, #120	@ 0x78
  5a0294:	1afffffa 	bne	5a0284 <IMamb_App_UpdateDefaultTuningData+0x33c>
  5a0298:	e2833078 	add	r3, r3, #120	@ 0x78
  5a029c:	e3530d2d 	cmp	r3, #2880	@ 0xb40
  5a02a0:	1afffff4 	bne	5a0278 <IMamb_App_UpdateDefaultTuningData+0x330>
  5a02a4:	e89da818 	ldm	sp, {r3, r4, fp, sp, pc}
  5a02a8:	000f6af4 	strdeq	r6, [pc], -r4
			5a02a8: R_ARM_ABS32	.rodata.str1.1
  5a02ac:	00085c7a 	andeq	r5, r8, sl, ror ip
			5a02ac: R_ARM_ABS32	.rodata
  5a02b0:	00085c9c 	muleq	r8, ip, ip
			5a02b0: R_ARM_ABS32	.rodata
  5a02b4:	000c29d8 	ldrdeq	r2, [ip], -r8
			5a02b4: R_ARM_ABS32	.bss
  5a02b8:	000c29dc 	ldrdeq	r2, [ip], -ip
			5a02b8: R_ARM_ABS32	.bss
  5a02bc:	00085ca0 	andeq	r5, r8, r0, lsr #25
			5a02bc: R_ARM_ABS32	.rodata
  5a02c0:	000c29fb 	strdeq	r2, [ip], -fp
			5a02c0: R_ARM_ABS32	.bss
  5a02c4:	00085cbf 			@ <UNDEFINED> instruction: 0x00085cbf
			5a02c4: R_ARM_ABS32	.rodata
  5a02c8:	00085cf2 	strdeq	r5, [r8], -r2
			5a02c8: R_ARM_ABS32	.rodata
  5a02cc:	000c2ac1 	andeq	r2, ip, r1, asr #21
			5a02cc: R_ARM_ABS32	.bss
  5a02d0:	00085d7b 	andeq	r5, r8, fp, ror sp
			5a02d0: R_ARM_ABS32	.rodata
  5a02d4:	000c2acc 	andeq	r2, ip, ip, asr #21
			5a02d4: R_ARM_ABS32	.bss
  5a02d8:	00085d86 	andeq	r5, r8, r6, lsl #27
			5a02d8: R_ARM_ABS32	.rodata
  5a02dc:	00085da6 	andeq	r5, r8, r6, lsr #27
			5a02dc: R_ARM_ABS32	.rodata
  5a02e0:	000c2aec 	andeq	r2, ip, ip, ror #21
			5a02e0: R_ARM_ABS32	.bss
  5a02e4:	000c2b6c 	andeq	r2, ip, ip, ror #22
			5a02e4: R_ARM_ABS32	.bss
  5a02e8:	000c310c 	andeq	r3, ip, ip, lsl #2
			5a02e8: R_ARM_ABS32	.bss
  5a02ec:	000863c6 	andeq	r6, r8, r6, asr #7
			5a02ec: R_ARM_ABS32	.rodata

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:


work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

000fb65c <EEPROM_Init>:
   fb65c:	e1a0c00d 	mov	ip, sp
   fb660:	e92dd810 	push	{r4, fp, ip, lr, pc}
   fb664:	e24cb004 	sub	fp, ip, #4
   fb668:	e24dd00c 	sub	sp, sp, #12
   fb66c:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
   fb670:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			fb670: R_ARM_CALL	__gnu_mcount_nc
   fb674:	e59f40b8 	ldr	r4, [pc, #184]	@ fb734 <EEPROM_Init+0xd8>
   fb678:	e5d43004 	ldrb	r3, [r4, #4]
   fb67c:	e3530000 	cmp	r3, #0
   fb680:	1a000028 	bne	fb728 <EEPROM_Init+0xcc>
   fb684:	e3a01001 	mov	r1, #1
   fb688:	e2840008 	add	r0, r4, #8
   fb68c:	e1a02001 	mov	r2, r1
   fb690:	ebfffffe 	bl	32c5f8 <x_sema_create>
			fb690: R_ARM_CALL	x_sema_create
   fb694:	ebfffffe 	bl	fba08 <EEP_SEMA_Init>
			fb694: R_ARM_CALL	EEP_SEMA_Init
   fb698:	ebfffffe 	bl	fb614 <EEPROM_InitClkDiv>
			fb698: R_ARM_CALL	EEPROM_InitClkDiv
   fb69c:	e24b1018 	sub	r1, fp, #24
   fb6a0:	e300016e 	movw	r0, #366	@ 0x16e
   fb6a4:	ebfffffe 	bl	c8c9c <DRVCUST_OptQuery>
			fb6a4: R_ARM_CALL	DRVCUST_OptQuery
   fb6a8:	e3500000 	cmp	r0, #0
   fb6ac:	e24b1018 	sub	r1, fp, #24
   fb6b0:	051b3018 	ldreq	r3, [fp, #-24]	@ 0xffffffe8
   fb6b4:	e300016f 	movw	r0, #367	@ 0x16f
   fb6b8:	05c4300c 	strbeq	r3, [r4, #12]
   fb6bc:	ebfffffe 	bl	c8c9c <DRVCUST_OptQuery>
			fb6bc: R_ARM_CALL	DRVCUST_OptQuery
   fb6c0:	e3500000 	cmp	r0, #0
   fb6c4:	e24b1018 	sub	r1, fp, #24
   fb6c8:	059f3068 	ldreq	r3, [pc, #104]	@ fb738 <EEPROM_Init+0xdc>
   fb6cc:	e3000172 	movw	r0, #370	@ 0x172
   fb6d0:	051b2018 	ldreq	r2, [fp, #-24]	@ 0xffffffe8
   fb6d4:	05c32002 	strbeq	r2, [r3, #2]
   fb6d8:	ebfffffe 	bl	c8c9c <DRVCUST_OptQuery>
			fb6d8: R_ARM_CALL	DRVCUST_OptQuery
   fb6dc:	e3500000 	cmp	r0, #0
   fb6e0:	e24b1018 	sub	r1, fp, #24
   fb6e4:	059f304c 	ldreq	r3, [pc, #76]	@ fb738 <EEPROM_Init+0xdc>
   fb6e8:	e3000175 	movw	r0, #373	@ 0x175
   fb6ec:	051b2018 	ldreq	r2, [fp, #-24]	@ 0xffffffe8
   fb6f0:	05c32003 	strbeq	r2, [r3, #3]
   fb6f4:	ebfffffe 	bl	c8c9c <DRVCUST_OptQuery>
			fb6f4: R_ARM_CALL	DRVCUST_OptQuery
   fb6f8:	e3500000 	cmp	r0, #0
   fb6fc:	e24b1018 	sub	r1, fp, #24
   fb700:	059f3030 	ldreq	r3, [pc, #48]	@ fb738 <EEPROM_Init+0xdc>
   fb704:	e3000176 	movw	r0, #374	@ 0x176
   fb708:	055b2018 	ldrbeq	r2, [fp, #-24]	@ 0xffffffe8
   fb70c:	05832004 	streq	r2, [r3, #4]
   fb710:	ebfffffe 	bl	c8c9c <DRVCUST_OptQuery>
			fb710: R_ARM_CALL	DRVCUST_OptQuery
   fb714:	e3500000 	cmp	r0, #0
   fb718:	051b3018 	ldreq	r3, [fp, #-24]	@ 0xffffffe8
   fb71c:	05c4300d 	strbeq	r3, [r4, #13]
   fb720:	e3a03001 	mov	r3, #1
   fb724:	e5c43004 	strb	r3, [r4, #4]
   fb728:	e3a00000 	mov	r0, #0
   fb72c:	e24bd010 	sub	sp, fp, #16
   fb730:	e89da810 	ldm	sp, {r4, fp, sp, pc}
   fb734:	0004f17c 	andeq	pc, r4, ip, ror r1	@ <UNPREDICTABLE>
			fb734: R_ARM_ABS32	.bss
   fb738:	0003cafc 	strdeq	ip, [r3], -ip	@ <UNPREDICTABLE>
			fb738: R_ARM_ABS32	.data

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:


work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

000fb814 <EEPROM_Read>:
   fb814:	e1a0c00d 	mov	ip, sp
   fb818:	e92dd800 	push	{fp, ip, lr, pc}
   fb81c:	e24cb004 	sub	fp, ip, #4
   fb820:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
   fb824:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			fb824: R_ARM_CALL	__gnu_mcount_nc
   fb828:	e1a01002 	mov	r1, r2
   fb82c:	e1a02003 	mov	r2, r3
   fb830:	ebfffffe 	bl	fb37c <MSDC_EEPROM_Read>
			fb830: R_ARM_CALL	MSDC_EEPROM_Read
   fb834:	e89da800 	ldm	sp, {fp, sp, pc}

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:


work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

000fb37c <MSDC_EEPROM_Read>:
   fb37c:	e1a0c00d 	mov	ip, sp
   fb380:	e92dd878 	push	{r3, r4, r5, r6, fp, ip, lr, pc}
   fb384:	e24cb004 	sub	fp, ip, #4
   fb388:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
   fb38c:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			fb38c: R_ARM_CALL	__gnu_mcount_nc
   fb390:	e1a05000 	mov	r5, r0
   fb394:	e1a06001 	mov	r6, r1
   fb398:	e1a04002 	mov	r4, r2
   fb39c:	ebfffed2 	bl	faeec <LzmaUncompress+0x50>
   fb3a0:	e59f305c 	ldr	r3, [pc, #92]	@ fb404 <MSDC_EEPROM_Read+0x88>
   fb3a4:	e593001c 	ldr	r0, [r3, #28]
   fb3a8:	e1550000 	cmp	r5, r0
   fb3ac:	2a000002 	bcs	fb3bc <MSDC_EEPROM_Read+0x40>
   fb3b0:	e0852004 	add	r2, r5, r4
   fb3b4:	e1520000 	cmp	r2, r0
   fb3b8:	9a000004 	bls	fb3d0 <MSDC_EEPROM_Read+0x54>
   fb3bc:	e1a01005 	mov	r1, r5
   fb3c0:	e1a02004 	mov	r2, r4
   fb3c4:	e59f003c 	ldr	r0, [pc, #60]	@ fb408 <MSDC_EEPROM_Read+0x8c>
   fb3c8:	ebfffffe 	bl	0 <printk>
			fb3c8: R_ARM_CALL	printk
   fb3cc:	ea000008 	b	fb3f4 <MSDC_EEPROM_Read+0x78>
   fb3d0:	e5930008 	ldr	r0, [r3, #8]
   fb3d4:	e1a01005 	mov	r1, r5
   fb3d8:	e1a02006 	mov	r2, r6
   fb3dc:	e1a03004 	mov	r3, r4
   fb3e0:	ebfffffe 	bl	fb324 <Loader_ReadMsdc>
			fb3e0: R_ARM_CALL	Loader_ReadMsdc
   fb3e4:	e1500004 	cmp	r0, r4
   fb3e8:	0a000003 	beq	fb3fc <MSDC_EEPROM_Read+0x80>
   fb3ec:	e59f0018 	ldr	r0, [pc, #24]	@ fb40c <MSDC_EEPROM_Read+0x90>
   fb3f0:	ebfffffe 	bl	0 <printk>
			fb3f0: R_ARM_CALL	printk
   fb3f4:	e3e00000 	mvn	r0, #0
   fb3f8:	e89da878 	ldm	sp, {r3, r4, r5, r6, fp, sp, pc}
   fb3fc:	e3a00000 	mov	r0, #0
   fb400:	e89da878 	ldm	sp, {r3, r4, r5, r6, fp, sp, pc}
   fb404:	0004f148 	andeq	pc, r4, r8, asr #2
			fb404: R_ARM_ABS32	.bss
   fb408:	00038439 	andeq	r8, r3, r9, lsr r4
			fb408: R_ARM_ABS32	.rodata.str1.1
   fb40c:	0003847f 	andeq	r8, r3, pc, ror r4
			fb40c: R_ARM_ABS32	.rodata.str1.1

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:


work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

000fb324 <Loader_ReadMsdc>:
   fb324:	e1a0c00d 	mov	ip, sp
   fb328:	e92ddb78 	push	{r3, r4, r5, r6, r8, r9, fp, ip, lr, pc}
   fb32c:	e24cb004 	sub	fp, ip, #4
   fb330:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
   fb334:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			fb334: R_ARM_CALL	__gnu_mcount_nc
   fb338:	e3a04000 	mov	r4, #0
   fb33c:	e1a05000 	mov	r5, r0
   fb340:	e1848001 	orr	r8, r4, r1
   fb344:	e1a09000 	mov	r9, r0
   fb348:	e1a01005 	mov	r1, r5
   fb34c:	e1a00008 	mov	r0, r8
   fb350:	e1a06003 	mov	r6, r3
   fb354:	ebfffffe 	bl	fb0fc <MSDCPART_Read>
			fb354: R_ARM_CALL	MSDCPART_Read
   fb358:	e1500004 	cmp	r0, r4
   fb35c:	1a000001 	bne	fb368 <Loader_ReadMsdc+0x44>
   fb360:	e1a00006 	mov	r0, r6
   fb364:	e89dab78 	ldm	sp, {r3, r4, r5, r6, r8, r9, fp, sp, pc}
   fb368:	e59f0008 	ldr	r0, [pc, #8]	@ fb378 <Loader_ReadMsdc+0x54>
   fb36c:	ebfffffe 	bl	0 <printk>
			fb36c: R_ARM_CALL	printk
   fb370:	e3e00000 	mvn	r0, #0
   fb374:	e89dab78 	ldm	sp, {r3, r4, r5, r6, r8, r9, fp, sp, pc}
   fb378:	0003840a 	andeq	r8, r3, sl, lsl #8
			fb378: R_ARM_ABS32	.rodata.str1.1

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:


work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

000fb0fc <MSDCPART_Read>:
   fb0fc:	e1a0c00d 	mov	ip, sp
   fb100:	e92dd830 	push	{r4, r5, fp, ip, lr, pc}
   fb104:	e24cb004 	sub	fp, ip, #4
   fb108:	e24dd010 	sub	sp, sp, #16
   fb10c:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
   fb110:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			fb110: R_ARM_CALL	__gnu_mcount_nc
   fb114:	e1a0c000 	mov	ip, r0
   fb118:	e6ff0071 	uxth	r0, r1
   fb11c:	e350003f 	cmp	r0, #63	@ 0x3f
   fb120:	9a000005 	bls	fb13c <MSDCPART_Read+0x40>
   fb124:	e59f0038 	ldr	r0, [pc, #56]	@ fb164 <MSDCPART_Read+0x68>
   fb128:	e3002307 	movw	r2, #775	@ 0x307
   fb12c:	e59f1034 	ldr	r1, [pc, #52]	@ fb168 <MSDCPART_Read+0x6c>
   fb130:	ebfffffe 	bl	0 <printk>
			fb130: R_ARM_CALL	printk
   fb134:	e3e00000 	mvn	r0, #0
   fb138:	ea000007 	b	fb15c <MSDCPART_Read+0x60>
   fb13c:	e1a04003 	mov	r4, r3
   fb140:	e3a05000 	mov	r5, #0
   fb144:	e58d2008 	str	r2, [sp, #8]
   fb148:	e2800001 	add	r0, r0, #1
   fb14c:	e1cd40f0 	strd	r4, [sp]
   fb150:	e1a0200c 	mov	r2, ip
   fb154:	e3a03000 	mov	r3, #0
   fb158:	ebfffffe 	bl	0 <msdc_partread>
			fb158: R_ARM_CALL	msdc_partread
   fb15c:	e24bd014 	sub	sp, fp, #20
   fb160:	e89da830 	ldm	sp, {r4, r5, fp, sp, pc}
   fb164:	000383d9 	ldrdeq	r8, [r3], -r9
			fb164: R_ARM_ABS32	.rodata.str1.1
   fb168:	00024792 	muleq	r2, r2, r7
			fb168: R_ARM_ABS32	.rodata

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:


work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

000fddd8 <vApiEepromDefaultInit>:
   fddd8:	e1a0c00d 	mov	ip, sp
   fdddc:	e92dd830 	push	{r4, r5, fp, ip, lr, pc}
   fdde0:	e24cb004 	sub	fp, ip, #4
   fdde4:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
   fdde8:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			fdde8: R_ARM_CALL	__gnu_mcount_nc
   fddec:	e3a04000 	mov	r4, #0
   fddf0:	e59f5060 	ldr	r5, [pc, #96]	@ fde58 <vApiEepromDefaultInit+0x80>
   fddf4:	e59f0060 	ldr	r0, [pc, #96]	@ fde5c <vApiEepromDefaultInit+0x84>
   fddf8:	ebfffffe 	bl	0 <printk>
			fddf8: R_ARM_CALL	printk
   fddfc:	e284006f 	add	r0, r4, #111	@ 0x6f
   fde00:	e7d51004 	ldrb	r1, [r5, r4]
   fde04:	e6ff0070 	uxth	r0, r0
   fde08:	e2844001 	add	r4, r4, #1
   fde0c:	ebfffffe 	bl	fdce4 <fgApiEepromWriteByte>
			fde0c: R_ARM_CALL	fgApiEepromWriteByte
   fde10:	e3540004 	cmp	r4, #4
   fde14:	1afffff8 	bne	fddfc <vApiEepromDefaultInit+0x24>
   fde18:	e3a01000 	mov	r1, #0
   fde1c:	e3a0006c 	mov	r0, #108	@ 0x6c
   fde20:	ebfffffe 	bl	fdce4 <fgApiEepromWriteByte>
			fde20: R_ARM_CALL	fgApiEepromWriteByte
   fde24:	e3a01000 	mov	r1, #0
   fde28:	e3a0006d 	mov	r0, #109	@ 0x6d
   fde2c:	ebfffffe 	bl	fdce4 <fgApiEepromWriteByte>
			fde2c: R_ARM_CALL	fgApiEepromWriteByte
   fde30:	e3a01000 	mov	r1, #0
   fde34:	e3a00094 	mov	r0, #148	@ 0x94
   fde38:	ebfffffe 	bl	fdce4 <fgApiEepromWriteByte>
			fde38: R_ARM_CALL	fgApiEepromWriteByte
   fde3c:	e3a01000 	mov	r1, #0
   fde40:	e3a00095 	mov	r0, #149	@ 0x95
   fde44:	ebfffffe 	bl	fdce4 <fgApiEepromWriteByte>
			fde44: R_ARM_CALL	fgApiEepromWriteByte
   fde48:	e3a01000 	mov	r1, #0
   fde4c:	e3a00085 	mov	r0, #133	@ 0x85
   fde50:	ebfffffe 	bl	fdce4 <fgApiEepromWriteByte>
			fde50: R_ARM_CALL	fgApiEepromWriteByte
   fde54:	e89da830 	ldm	sp, {r4, r5, fp, sp, pc}
   fde58:	0003cb48 	andeq	ip, r3, r8, asr #22
			fde58: R_ARM_ABS32	.data
   fde5c:	0003877a 	andeq	r8, r3, sl, ror r7
			fde5c: R_ARM_ABS32	.rodata.str1.1

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:


work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

000d38ec <DRVCUST_InitQuery64+0xb8>:
   d38ec:	e30031ff 	movw	r3, #511	@ 0x1ff
   d38f0:	e1500003 	cmp	r0, r3
   d38f4:	1a000738 	bne	d55dc <DRVCUST_InitQuery64+0x1da8>
   d38f8:	e3a02019 	mov	r2, #25
   d38fc:	e3a03000 	mov	r3, #0
   d3900:	e1c120f0 	strd	r2, [r1]
   d3904:	e3a00000 	mov	r0, #0
   d3908:	e89da818 	ldm	sp, {r3, r4, fp, sp, pc}


work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

000faeec <LzmaUncompress+0x50>:
   faeec:	e1a0c00d 	mov	ip, sp
   faef0:	e92dd878 	push	{r3, r4, r5, r6, fp, ip, lr, pc}
   faef4:	e24cb004 	sub	fp, ip, #4
   faef8:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
   faefc:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			faefc: R_ARM_CALL	__gnu_mcount_nc
   faf00:	e59f50e0 	ldr	r5, [pc, #224]	@ fafe8 <LzmaUncompress+0x14c>
   faf04:	e5d53000 	ldrb	r3, [r5]
   faf08:	e1a04005 	mov	r4, r5
   faf0c:	e3530000 	cmp	r3, #0
   faf10:	1a000032 	bne	fafe0 <LzmaUncompress+0x144>
   faf14:	e3a00e17 	mov	r0, #368	@ 0x170
   faf18:	e30061ff 	movw	r6, #511	@ 0x1ff
   faf1c:	ebfffffe 	bl	d55e4 <DRVCUST_InitGet64>
			faf1c: R_ARM_CALL	DRVCUST_InitGet64
   faf20:	e585001c 	str	r0, [r5, #28]
   faf24:	e3a00e1f 	mov	r0, #496	@ 0x1f0
   faf28:	ebfffffe 	bl	d55e4 <DRVCUST_InitGet64>
			faf28: R_ARM_CALL	DRVCUST_InitGet64
   faf2c:	e5850004 	str	r0, [r5, #4]
   faf30:	e1a00006 	mov	r0, r6
   faf34:	ebfffffe 	bl	d55e4 <DRVCUST_InitGet64>
			faf34: R_ARM_CALL	DRVCUST_InitGet64
   faf38:	e5850008 	str	r0, [r5, #8]
   faf3c:	e3a00c02 	mov	r0, #512	@ 0x200
   faf40:	ebfffffe 	bl	d55e4 <DRVCUST_InitGet64>
			faf40: R_ARM_CALL	DRVCUST_InitGet64
   faf44:	e585000c 	str	r0, [r5, #12]
   faf48:	e595001c 	ldr	r0, [r5, #28]
   faf4c:	ebfffffe 	bl	398f04 <x_mem_alloc_virtual>
			faf4c: R_ARM_CALL	x_mem_alloc_virtual
   faf50:	e3500000 	cmp	r0, #0
   faf54:	e5850030 	str	r0, [r5, #48]	@ 0x30
   faf58:	1a000003 	bne	faf6c <LzmaUncompress+0xd0>
   faf5c:	e59f0088 	ldr	r0, [pc, #136]	@ fafec <LzmaUncompress+0x150>
   faf60:	ebfffffe 	bl	0 <printk>
			faf60: R_ARM_CALL	printk
   faf64:	e3e00000 	mvn	r0, #0
   faf68:	e89da878 	ldm	sp, {r3, r4, r5, r6, fp, sp, pc}
   faf6c:	e5950008 	ldr	r0, [r5, #8]
   faf70:	e2800c02 	add	r0, r0, #512	@ 0x200
   faf74:	e2800002 	add	r0, r0, #2
   faf78:	ebfffffe 	bl	d55e4 <DRVCUST_InitGet64>
			faf78: R_ARM_CALL	DRVCUST_InitGet64
   faf7c:	e5850010 	str	r0, [r5, #16]
   faf80:	e595000c 	ldr	r0, [r5, #12]
   faf84:	e2800c02 	add	r0, r0, #512	@ 0x200
   faf88:	e2800002 	add	r0, r0, #2
   faf8c:	ebfffffe 	bl	d55e4 <DRVCUST_InitGet64>
			faf8c: R_ARM_CALL	DRVCUST_InitGet64
   faf90:	e595201c 	ldr	r2, [r5, #28]
   faf94:	e3e03000 	mvn	r3, #0
   faf98:	e5853020 	str	r3, [r5, #32]
   faf9c:	e3a03001 	mov	r3, #1
   fafa0:	e585302c 	str	r3, [r5, #44]	@ 0x2c
   fafa4:	e1520006 	cmp	r2, r6
   fafa8:	e5850014 	str	r0, [r5, #20]
   fafac:	91a01003 	movls	r1, r3
   fafb0:	81a014a2 	lsrhi	r1, r2, #9
   fafb4:	e3520000 	cmp	r2, #0
   fafb8:	e5950030 	ldr	r0, [r5, #48]	@ 0x30
   fafbc:	e3e03000 	mvn	r3, #0
   fafc0:	e5851018 	str	r1, [r5, #24]
   fafc4:	e5853024 	str	r3, [r5, #36]	@ 0x24
   fafc8:	e5853028 	str	r3, [r5, #40]	@ 0x28
   fafcc:	0a000001 	beq	fafd8 <LzmaUncompress+0x13c>
   fafd0:	e3a010ff 	mov	r1, #255	@ 0xff
   fafd4:	ebfffffe 	bl	0 <memset>
			fafd4: R_ARM_CALL	memset
   fafd8:	e3a03001 	mov	r3, #1
   fafdc:	e5c43000 	strb	r3, [r4]
   fafe0:	e3a00000 	mov	r0, #0
   fafe4:	e89da878 	ldm	sp, {r3, r4, r5, r6, fp, sp, pc}
   fafe8:	0004f148 	andeq	pc, r4, r8, asr #2
			fafe8: R_ARM_ABS32	.bss
   fafec:	0003830b 	andeq	r8, r3, fp, lsl #6
			fafec: R_ARM_ABS32	.rodata.str1.1
