
work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

00143124 <vDrvLcdimSpiSendDataSWModeMbyN>:
  143124:	e1a0c00d 	mov	ip, sp
  143128:	e92dd8f0 	push	{r4, r5, r6, r7, fp, ip, lr, pc}
  14312c:	e24cb004 	sub	fp, ip, #4
  143130:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
  143134:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			143134: R_ARM_CALL	__gnu_mcount_nc
  143138:	e1a04001 	mov	r4, r1
  14313c:	e1a05002 	mov	r5, r2
  143140:	e3a01000 	mov	r1, #0
  143144:	e3a02002 	mov	r2, #2
  143148:	e1a07000 	mov	r7, r0
  14314c:	e59f0094 	ldr	r0, [pc, #148]	@ 1431e8 <vDrvLcdimSpiSendDataSWModeMbyN+0xc4>
  143150:	ebfffffe 	bl	398ab8 <vIO32Write1BMsk>
			143150: R_ARM_CALL	vIO32Write1BMsk
  143154:	e59f0090 	ldr	r0, [pc, #144]	@ 1431ec <vDrvLcdimSpiSendDataSWModeMbyN+0xc8>
  143158:	e1a01204 	lsl	r1, r4, #4
  14315c:	e3a02eff 	mov	r2, #4080	@ 0xff0
  143160:	e59f6088 	ldr	r6, [pc, #136]	@ 1431f0 <vDrvLcdimSpiSendDataSWModeMbyN+0xcc>
  143164:	ebfffffe 	bl	398b00 <vIO32Write2BMsk>
			143164: R_ARM_CALL	vIO32Write2BMsk
  143168:	e59f0084 	ldr	r0, [pc, #132]	@ 1431f4 <vDrvLcdimSpiSendDataSWModeMbyN+0xd0>
  14316c:	e1a01205 	lsl	r1, r5, #4
  143170:	e3a02eff 	mov	r2, #4080	@ 0xff0
  143174:	ebfffffe 	bl	398b00 <vIO32Write2BMsk>
			143174: R_ARM_CALL	vIO32Write2BMsk
  143178:	ebfffffe 	bl	142ca0 <u1DrvLcdimSpiRWProtect>
			143178: R_ARM_CALL	u1DrvLcdimSpiRWProtect
  14317c:	e3500000 	cmp	r0, #0
  143180:	1a000008 	bne	1431a8 <vDrvLcdimSpiSendDataSWModeMbyN+0x84>
  143184:	e3a00ffa 	mov	r0, #1000	@ 0x3e8
  143188:	ebfffffe 	bl	142fc4 <vDrvLcdimSpiWaitReady>
			143188: R_ARM_CALL	vDrvLcdimSpiWaitReady
  14318c:	ebfffffe 	bl	142ca0 <u1DrvLcdimSpiRWProtect>
			14318c: R_ARM_CALL	u1DrvLcdimSpiRWProtect
  143190:	e3500000 	cmp	r0, #0
  143194:	1a000003 	bne	1431a8 <vDrvLcdimSpiSendDataSWModeMbyN+0x84>
  143198:	e5860404 	str	r0, [r6, #1028]	@ 0x404
  14319c:	e59f0054 	ldr	r0, [pc, #84]	@ 1431f8 <vDrvLcdimSpiSendDataSWModeMbyN+0xd4>
  1431a0:	ebfffffe 	bl	0 <printk>
			1431a0: R_ARM_CALL	printk
  1431a4:	e89da8f0 	ldm	sp, {r4, r5, r6, r7, fp, sp, pc}
  1431a8:	e0040495 	mul	r4, r5, r4
  1431ac:	e59f203c 	ldr	r2, [pc, #60]	@ 1431f0 <vDrvLcdimSpiSendDataSWModeMbyN+0xcc>
  1431b0:	e3a03000 	mov	r3, #0
  1431b4:	e5863400 	str	r3, [r6, #1024]	@ 0x400
  1431b8:	e1530004 	cmp	r3, r4
  1431bc:	17d71003 	ldrbne	r1, [r7, r3]
  1431c0:	12833001 	addne	r3, r3, #1
  1431c4:	15821408 	strne	r1, [r2, #1032]	@ 0x408
  1431c8:	1afffffa 	bne	1431b8 <vDrvLcdimSpiSendDataSWModeMbyN+0x94>
  1431cc:	e3a01001 	mov	r1, #1
  1431d0:	e59f0010 	ldr	r0, [pc, #16]	@ 1431e8 <vDrvLcdimSpiSendDataSWModeMbyN+0xc4>
  1431d4:	e1a02001 	mov	r2, r1
  1431d8:	ebfffffe 	bl	398ab8 <vIO32Write1BMsk>
			1431d8: R_ARM_CALL	vIO32Write1BMsk
  1431dc:	e59f0018 	ldr	r0, [pc, #24]	@ 1431fc <vDrvLcdimSpiSendDataSWModeMbyN+0xd8>
  1431e0:	ebfffffe 	bl	142fc4 <vDrvLcdimSpiWaitReady>
			1431e0: R_ARM_CALL	vDrvLcdimSpiWaitReady
  1431e4:	e89da8f0 	ldm	sp, {r4, r5, r6, r7, fp, sp, pc}
  1431e8:	f002944c 			@ <UNDEFINED> instruction: 0xf002944c
  1431ec:	f0029440 			@ <UNDEFINED> instruction: 0xf0029440
  1431f0:	f0029000 			@ <UNDEFINED> instruction: 0xf0029000
  1431f4:	f0029442 			@ <UNDEFINED> instruction: 0xf0029442
  1431f8:	0003ebca 	andeq	lr, r3, sl, asr #23
			1431f8: R_ARM_ABS32	.rodata.str1.1
  1431fc:	000f4240 	andeq	r4, pc, r0, asr #4

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:

work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

00142fc4 <vDrvLcdimSpiWaitReady>:
  142fc4:	e1a0c00d 	mov	ip, sp
  142fc8:	e92dd800 	push	{fp, ip, lr, pc}
  142fcc:	e24cb004 	sub	fp, ip, #4
  142fd0:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
  142fd4:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			142fd4: R_ARM_CALL	__gnu_mcount_nc
  142fd8:	e3a03000 	mov	r3, #0
  142fdc:	e59f102c 	ldr	r1, [pc, #44]	@ 143010 <vDrvLcdimSpiWaitReady+0x4c>
  142fe0:	e1530000 	cmp	r3, r0
  142fe4:	0a000005 	beq	143000 <vDrvLcdimSpiWaitReady+0x3c>
  142fe8:	e5d1244c 	ldrb	r2, [r1, #1100]	@ 0x44c
  142fec:	e7e022d2 	ubfx	r2, r2, #5, #1
  142ff0:	e3520001 	cmp	r2, #1
  142ff4:	0a000003 	beq	143008 <vDrvLcdimSpiWaitReady+0x44>
  142ff8:	e2833001 	add	r3, r3, #1
  142ffc:	eafffff7 	b	142fe0 <vDrvLcdimSpiWaitReady+0x1c>
  143000:	e3a00000 	mov	r0, #0
  143004:	e89da800 	ldm	sp, {fp, sp, pc}
  143008:	e1a00002 	mov	r0, r2
  14300c:	e89da800 	ldm	sp, {fp, sp, pc}
  143010:	f0029000 			@ <UNDEFINED> instruction: 0xf0029000

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:

work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

00142ca0 <u1DrvLcdimSpiRWProtect>:
  142ca0:	e1a0c00d 	mov	ip, sp
  142ca4:	e92dd800 	push	{fp, ip, lr, pc}
  142ca8:	e24cb004 	sub	fp, ip, #4
  142cac:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
  142cb0:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			142cb0: R_ARM_CALL	__gnu_mcount_nc
  142cb4:	e59f0010 	ldr	r0, [pc, #16]	@ 142ccc <u1DrvLcdimSpiRWProtect+0x2c>
  142cb8:	ebfffffe 	bl	398a68 <u2IO32Read2B>
			142cb8: R_ARM_CALL	u2IO32Read2B
  142cbc:	e7e90050 	ubfx	r0, r0, #0, #10
  142cc0:	e16f0f10 	clz	r0, r0
  142cc4:	e1a002a0 	lsr	r0, r0, #5
  142cc8:	e89da800 	ldm	sp, {fp, sp, pc}
  142ccc:	f0029404 			@ <UNDEFINED> instruction: 0xf0029404

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:

work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

005a2ea4 <IMamb_Fms_Execute>:
  5a2ea4:	e1a0c00d 	mov	ip, sp
  5a2ea8:	e3a00000 	mov	r0, #0
  5a2eac:	e92dd830 	push	{r4, r5, fp, ip, lr, pc}
  5a2eb0:	e24cb004 	sub	fp, ip, #4
  5a2eb4:	e59f50bc 	ldr	r5, [pc, #188]	@ 5a2f78 <IMamb_Fms_Execute+0xd4>
  5a2eb8:	e24dde3d 	sub	sp, sp, #976	@ 0x3d0
  5a2ebc:	e24b3014 	sub	r3, fp, #20
  5a2ec0:	e59f40b4 	ldr	r4, [pc, #180]	@ 5a2f7c <IMamb_Fms_Execute+0xd8>
  5a2ec4:	e18300b5 	strh	r0, [r3, r5]
  5a2ec8:	e5943000 	ldr	r3, [r4]
  5a2ecc:	e1530000 	cmp	r3, r0
  5a2ed0:	0a000025 	beq	5a2f6c <IMamb_Fms_Execute+0xc8>
  5a2ed4:	e2841004 	add	r1, r4, #4
  5a2ed8:	ebfffffe 	bl	188c <IMamb_fpgaR_GetAmbiContent>
			5a2ed8: R_ARM_CALL	IMamb_fpgaR_GetAmbiContent
  5a2edc:	e3a00001 	mov	r0, #1
  5a2ee0:	e59f1098 	ldr	r1, [pc, #152]	@ 5a2f80 <IMamb_Fms_Execute+0xdc>
  5a2ee4:	ebfffffe 	bl	188c <IMamb_fpgaR_GetAmbiContent>
			5a2ee4: R_ARM_CALL	IMamb_fpgaR_GetAmbiContent
  5a2ee8:	e3a00002 	mov	r0, #2
  5a2eec:	e59f1090 	ldr	r1, [pc, #144]	@ 5a2f84 <IMamb_Fms_Execute+0xe0>
  5a2ef0:	ebfffffe 	bl	188c <IMamb_fpgaR_GetAmbiContent>
			5a2ef0: R_ARM_CALL	IMamb_fpgaR_GetAmbiContent
  5a2ef4:	e3a02d0a 	mov	r2, #640	@ 0x280
  5a2ef8:	e3a03001 	mov	r3, #1
  5a2efc:	e88d000c 	stm	sp, {r2, r3}
  5a2f00:	e1a01004 	mov	r1, r4
  5a2f04:	e59f2074 	ldr	r2, [pc, #116]	@ 5a2f80 <IMamb_Fms_Execute+0xdc>
  5a2f08:	e4910004 	ldr	r0, [r1], #4
  5a2f0c:	e2823c05 	add	r3, r2, #1280	@ 0x500
  5a2f10:	ebfffffe 	bl	596228 <amb_writeColorGrid>
			5a2f10: R_ARM_CALL	amb_writeColorGrid
  5a2f14:	e5940000 	ldr	r0, [r4]
  5a2f18:	ebfffffe 	bl	595ff4 <amb_computeMeasurements>
			5a2f18: R_ARM_CALL	amb_computeMeasurements
  5a2f1c:	e5940000 	ldr	r0, [r4]
  5a2f20:	ebfffffe 	bl	596048 <amb_computeAlgorithms>
			5a2f20: R_ARM_CALL	amb_computeAlgorithms
  5a2f24:	e5940000 	ldr	r0, [r4]
  5a2f28:	ebfffffe 	bl	59608c <amb_computeDriver>
			5a2f28: R_ARM_CALL	amb_computeDriver
  5a2f2c:	e24b1ff5 	sub	r1, fp, #980	@ 0x3d4
  5a2f30:	e5940000 	ldr	r0, [r4]
  5a2f34:	e2411001 	sub	r1, r1, #1
  5a2f38:	e24b2ff6 	sub	r2, fp, #984	@ 0x3d8
  5a2f3c:	ebfffffe 	bl	597c94 <amb_getOutputBuffer>
			5a2f3c: R_ARM_CALL	amb_getOutputBuffer
  5a2f40:	e5d43f04 	ldrb	r3, [r4, #3844]	@ 0xf04
  5a2f44:	e3530000 	cmp	r3, #0
  5a2f48:	0a000007 	beq	5a2f6c <IMamb_Fms_Execute+0xc8>
  5a2f4c:	e24b3014 	sub	r3, fp, #20
  5a2f50:	e19310b5 	ldrh	r1, [r3, r5]
  5a2f54:	e3510000 	cmp	r1, #0
  5a2f58:	0a000003 	beq	5a2f6c <IMamb_Fms_Execute+0xc8>
  5a2f5c:	e24b2ff5 	sub	r2, fp, #980	@ 0x3d4
  5a2f60:	e5d40f05 	ldrb	r0, [r4, #3845]	@ 0xf05
  5a2f64:	e2422001 	sub	r2, r2, #1
  5a2f68:	ebfffffe 	bl	1900 <IMambR_WriteSPI>
			5a2f68: R_ARM_CALL	IMambR_WriteSPI
  5a2f6c:	e3a00000 	mov	r0, #0
  5a2f70:	e24bd014 	sub	sp, fp, #20
  5a2f74:	e89da830 	ldm	sp, {r4, r5, fp, sp, pc}
  5a2f78:	fffffc3c 			@ <UNDEFINED> instruction: 0xfffffc3c
  5a2f7c:	000c4e88 	andeq	r4, ip, r8, lsl #29
			5a2f7c: R_ARM_ABS32	.bss
  5a2f80:	000c538c 	andeq	r5, ip, ip, lsl #7
			5a2f80: R_ARM_ABS32	.bss
  5a2f84:	000c588c 	andeq	r5, ip, ip, lsl #17
			5a2f84: R_ARM_ABS32	.bss

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:

work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

00001900 <IMambR_WriteSPI>:
    1900:	e1a0c00d 	mov	ip, sp
    1904:	e92dd800 	push	{fp, ip, lr, pc}
    1908:	e24cb004 	sub	fp, ip, #4
    190c:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
    1910:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			1910: R_ARM_CALL	__gnu_mcount_nc
    1914:	e1a03000 	mov	r3, r0
    1918:	e1a00001 	mov	r0, r1
    191c:	e1a01002 	mov	r1, r2
    1920:	e1a02003 	mov	r2, r3
    1924:	ebfffffe 	bl	1434f4 <vDrvAmbiLitBatchWriteCmd>
			1924: R_ARM_CALL	vDrvAmbiLitBatchWriteCmd
    1928:	e89da800 	ldm	sp, {fp, sp, pc}

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:

work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

001434f4 <vDrvAmbiLitBatchWriteCmd>:
  1434f4:	e1a0c00d 	mov	ip, sp
  1434f8:	e92dd800 	push	{fp, ip, lr, pc}
  1434fc:	e24cb004 	sub	fp, ip, #4
  143500:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
  143504:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			143504: R_ARM_CALL	__gnu_mcount_nc
  143508:	e1a03120 	lsr	r3, r0, #2
  14350c:	e3a02004 	mov	r2, #4
  143510:	e1a00001 	mov	r0, r1
  143514:	e1a01003 	mov	r1, r3
  143518:	ebfffffe 	bl	143124 <vDrvLcdimSpiSendDataSWModeMbyN>
			143518: R_ARM_CALL	vDrvLcdimSpiSendDataSWModeMbyN
  14351c:	e89da800 	ldm	sp, {fp, sp, pc}

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:

work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

00599750 <amb_driv_compute>:
  599750:	e1a0c00d 	mov	ip, sp
  599754:	e92ddff0 	push	{r4, r5, r6, r7, r8, r9, sl, fp, ip, lr, pc}
  599758:	e2504000 	subs	r4, r0, #0
  59975c:	e24cb004 	sub	fp, ip, #4
  599760:	e24dd044 	sub	sp, sp, #68	@ 0x44
  599764:	0a000302 	beq	59a374 <amb_driv_compute+0xc24>
  599768:	e59f3c10 	ldr	r3, [pc, #3088]	@ 59a380 <amb_driv_compute+0xc30>
  59976c:	e3a01f4b 	mov	r1, #300	@ 0x12c
  599770:	e1d408be 	ldrh	r0, [r4, #142]	@ 0x8e
  599774:	e5d32000 	ldrb	r2, [r3]
  599778:	e2800001 	add	r0, r0, #1
  59977c:	e6ff0070 	uxth	r0, r0
  599780:	e2822001 	add	r2, r2, #1
  599784:	e6ef2072 	uxtb	r2, r2
  599788:	e1c408be 	strh	r0, [r4, #142]	@ 0x8e
  59978c:	e5c32000 	strb	r2, [r3]
  599790:	e50b2054 	str	r2, [fp, #-84]	@ 0xffffffac
  599794:	ebfffffe 	bl	6563a0 <__aeabi_uidivmod>
			599794: R_ARM_CALL	__aeabi_uidivmod
  599798:	e6ff1071 	uxth	r1, r1
  59979c:	e3510000 	cmp	r1, #0
  5997a0:	1a00000e 	bne	5997e0 <amb_driv_compute+0x90>
  5997a4:	e5d4309c 	ldrb	r3, [r4, #156]	@ 0x9c
  5997a8:	e353004a 	cmp	r3, #74	@ 0x4a
  5997ac:	8a000004 	bhi	5997c4 <amb_driv_compute+0x74>
  5997b0:	e5d4308c 	ldrb	r3, [r4, #140]	@ 0x8c
  5997b4:	e3530000 	cmp	r3, #0
  5997b8:	12433001 	subne	r3, r3, #1
  5997bc:	1a000006 	bne	5997dc <amb_driv_compute+0x8c>
  5997c0:	ea000006 	b	5997e0 <amb_driv_compute+0x90>
  5997c4:	e353004b 	cmp	r3, #75	@ 0x4b
  5997c8:	0a000004 	beq	5997e0 <amb_driv_compute+0x90>
  5997cc:	e5d4308c 	ldrb	r3, [r4, #140]	@ 0x8c
  5997d0:	e3530033 	cmp	r3, #51	@ 0x33
  5997d4:	8a000001 	bhi	5997e0 <amb_driv_compute+0x90>
  5997d8:	e2833001 	add	r3, r3, #1
  5997dc:	e5c4308c 	strb	r3, [r4, #140]	@ 0x8c
  5997e0:	e3a03000 	mov	r3, #0
  5997e4:	e50b4050 	str	r4, [fp, #-80]	@ 0xffffffb0
  5997e8:	e5843594 	str	r3, [r4, #1428]	@ 0x594
  5997ec:	e5843590 	str	r3, [r4, #1424]	@ 0x590
  5997f0:	e584358c 	str	r3, [r4, #1420]	@ 0x58c
  5997f4:	e5843598 	str	r3, [r4, #1432]	@ 0x598
  5997f8:	e284303c 	add	r3, r4, #60	@ 0x3c
  5997fc:	e50b3060 	str	r3, [fp, #-96]	@ 0xffffffa0
  599800:	e50b4048 	str	r4, [fp, #-72]	@ 0xffffffb8
  599804:	e50b4044 	str	r4, [fp, #-68]	@ 0xffffffbc
  599808:	e51b9044 	ldr	r9, [fp, #-68]	@ 0xffffffbc
  59980c:	e5d99132 	ldrb	r9, [r9, #306]	@ 0x132
  599810:	e3190080 	tst	r9, #128	@ 0x80
  599814:	e50b9040 	str	r9, [fp, #-64]	@ 0xffffffc0
  599818:	0a000017 	beq	59987c <amb_driv_compute+0x12c>
  59981c:	e5943598 	ldr	r3, [r4, #1432]	@ 0x598
  599820:	e3a0607d 	mov	r6, #125	@ 0x7d
  599824:	e5d42586 	ldrb	r2, [r4, #1414]	@ 0x586
  599828:	e30f1fff 	movw	r1, #65535	@ 0xffff
  59982c:	e1d409b2 	ldrh	r0, [r4, #146]	@ 0x92
  599830:	e5945574 	ldr	r5, [r4, #1396]	@ 0x574
  599834:	e0030396 	mul	r3, r6, r3
  599838:	e5d46587 	ldrb	r6, [r4, #1415]	@ 0x587
  59983c:	e1a00500 	lsl	r0, r0, #10
  599840:	e0866002 	add	r6, r6, r2
  599844:	e5d42588 	ldrb	r2, [r4, #1416]	@ 0x588
  599848:	e0866002 	add	r6, r6, r2
  59984c:	e0060396 	mul	r6, r6, r3
  599850:	ebfffffe 	bl	6563c0 <__divsi3>
			599850: R_ARM_CALL	__aeabi_idiv
  599854:	e0000096 	mul	r0, r6, r0
  599858:	e1a07520 	lsr	r7, r0, #10
  59985c:	e1550007 	cmp	r5, r7
  599860:	9a000193 	bls	599eb4 <amb_driv_compute+0x764>
  599864:	e1a00507 	lsl	r0, r7, #10
  599868:	e1a01005 	mov	r1, r5
  59986c:	ebfffffe 	bl	6561b4 <__udivsi3>
			59986c: R_ARM_CALL	__aeabi_uidiv
  599870:	e1a03004 	mov	r3, r4
  599874:	e3a0203c 	mov	r2, #60	@ 0x3c
  599878:	ea00017d 	b	599e74 <amb_driv_compute+0x724>
  59987c:	e51b3050 	ldr	r3, [fp, #-80]	@ 0xffffffb0
  599880:	e1d33bfa 	ldrsh	r3, [r3, #186]	@ 0xba
  599884:	e3530023 	cmp	r3, #35	@ 0x23
  599888:	e50b304c 	str	r3, [fp, #-76]	@ 0xffffffb4
  59988c:	83a08000 	movhi	r8, #0
  599890:	81a06008 	movhi	r6, r8
  599894:	81a05008 	movhi	r5, r8
  599898:	8a000165 	bhi	599e34 <amb_driv_compute+0x6e4>
  59989c:	e59490a0 	ldr	r9, [r4, #160]	@ 0xa0
  5998a0:	e3012304 	movw	r2, #4868	@ 0x1304
  5998a4:	e5943598 	ldr	r3, [r4, #1432]	@ 0x598
  5998a8:	e3a01000 	mov	r1, #0
  5998ac:	e24b0035 	sub	r0, fp, #53	@ 0x35
  5998b0:	e50b9058 	str	r9, [fp, #-88]	@ 0xffffffa8
  5998b4:	e51b9044 	ldr	r9, [fp, #-68]	@ 0xffffffbc
  5998b8:	e2833001 	add	r3, r3, #1
  5998bc:	e5843598 	str	r3, [r4, #1432]	@ 0x598
  5998c0:	e2893f5b 	add	r3, r9, #364	@ 0x16c
  5998c4:	e51b9058 	ldr	r9, [fp, #-88]	@ 0xffffffa8
  5998c8:	e1d330d2 	ldrsb	r3, [r3, #2]
  5998cc:	e0239392 	mla	r3, r2, r3, r9
  5998d0:	e51b904c 	ldr	r9, [fp, #-76]	@ 0xffffffb4
  5998d4:	e3a0200c 	mov	r2, #12
  5998d8:	e0233992 	mla	r3, r2, r9, r3
  5998dc:	e3a02009 	mov	r2, #9
  5998e0:	e593677c 	ldr	r6, [r3, #1916]	@ 0x77c
  5998e4:	e5937784 	ldr	r7, [r3, #1924]	@ 0x784
  5998e8:	e5935780 	ldr	r5, [r3, #1920]	@ 0x780
  5998ec:	ebfffffe 	bl	0 <memset>
			5998ec: R_ARM_CALL	memset
  5998f0:	e5941080 	ldr	r1, [r4, #128]	@ 0x80
  5998f4:	e1a00406 	lsl	r0, r6, #8
  5998f8:	e2811001 	add	r1, r1, #1
  5998fc:	ebfffffe 	bl	6561b4 <__udivsi3>
			5998fc: R_ARM_CALL	__aeabi_uidiv
  599900:	e5941084 	ldr	r1, [r4, #132]	@ 0x84
  599904:	e1a06000 	mov	r6, r0
  599908:	e1a00405 	lsl	r0, r5, #8
  59990c:	e2811001 	add	r1, r1, #1
  599910:	ebfffffe 	bl	6561b4 <__udivsi3>
			599910: R_ARM_CALL	__aeabi_uidiv
  599914:	e5941088 	ldr	r1, [r4, #136]	@ 0x88
  599918:	e1a05000 	mov	r5, r0
  59991c:	e1a00407 	lsl	r0, r7, #8
  599920:	e2811001 	add	r1, r1, #1
  599924:	ebfffffe 	bl	6561b4 <__udivsi3>
			599924: R_ARM_CALL	__aeabi_uidiv
  599928:	e1550006 	cmp	r5, r6
  59992c:	e1a0a000 	mov	sl, r0
  599930:	31a07006 	movcc	r7, r6
  599934:	21a07005 	movcs	r7, r5
  599938:	e1570000 	cmp	r7, r0
  59993c:	31a07000 	movcc	r7, r0
  599940:	e1550006 	cmp	r5, r6
  599944:	21a02006 	movcs	r2, r6
  599948:	31a02005 	movcc	r2, r5
  59994c:	e1520000 	cmp	r2, r0
  599950:	21a02000 	movcs	r2, r0
  599954:	e1560007 	cmp	r6, r7
  599958:	03a01000 	moveq	r1, #0
  59995c:	0a000002 	beq	59996c <amb_driv_compute+0x21c>
  599960:	e1550007 	cmp	r5, r7
  599964:	13a01002 	movne	r1, #2
  599968:	03a01001 	moveq	r1, #1
  59996c:	e15a0002 	cmp	sl, r2
  599970:	e24be02c 	sub	lr, fp, #44	@ 0x2c
  599974:	10622005 	rsbne	r2, r2, r5
  599978:	116f2f12 	clzne	r2, r2
  59997c:	11a022a2 	lsrne	r2, r2, #5
  599980:	e08e3001 	add	r3, lr, r1
  599984:	e0840001 	add	r0, r4, r1
  599988:	03a02002 	moveq	r2, #2
  59998c:	e2611003 	rsb	r1, r1, #3
  599990:	e0621001 	rsb	r1, r2, r1
  599994:	e5d0c57c 	ldrb	ip, [r0, #1404]	@ 0x57c
  599998:	e6ef1071 	uxtb	r1, r1
  59999c:	e5d0857f 	ldrb	r8, [r0, #1407]	@ 0x57f
  5999a0:	e5d0e582 	ldrb	lr, [r0, #1410]	@ 0x582
  5999a4:	e0840001 	add	r0, r4, r1
  5999a8:	e543c009 	strb	ip, [r3, #-9]
  5999ac:	e5d0957c 	ldrb	r9, [r0, #1404]	@ 0x57c
  5999b0:	e26cc0ff 	rsb	ip, ip, #255	@ 0xff
  5999b4:	e5438006 	strb	r8, [r3, #-6]
  5999b8:	e26880ff 	rsb	r8, r8, #255	@ 0xff
  5999bc:	e543e003 	strb	lr, [r3, #-3]
  5999c0:	e26ee0ff 	rsb	lr, lr, #255	@ 0xff
  5999c4:	e159000c 	cmp	r9, ip
  5999c8:	b1a0c009 	movlt	ip, r9
  5999cc:	e24b902c 	sub	r9, fp, #44	@ 0x2c
  5999d0:	e0891001 	add	r1, r9, r1
  5999d4:	e5d0957f 	ldrb	r9, [r0, #1407]	@ 0x57f
  5999d8:	e5d00582 	ldrb	r0, [r0, #1410]	@ 0x582
  5999dc:	e541c009 	strb	ip, [r1, #-9]
  5999e0:	e1590008 	cmp	r9, r8
  5999e4:	b1a08009 	movlt	r8, r9
  5999e8:	e150000e 	cmp	r0, lr
  5999ec:	b1a0e000 	movlt	lr, r0
  5999f0:	e24b002c 	sub	r0, fp, #44	@ 0x2c
  5999f4:	e5418006 	strb	r8, [r1, #-6]
  5999f8:	e541e003 	strb	lr, [r1, #-3]
  5999fc:	e0801002 	add	r1, r0, r2
  599a00:	e5530009 	ldrb	r0, [r3, #-9]
  599a04:	e0842002 	add	r2, r4, r2
  599a08:	e26000ff 	rsb	r0, r0, #255	@ 0xff
  599a0c:	e06cc000 	rsb	ip, ip, r0
  599a10:	e5d2057c 	ldrb	r0, [r2, #1404]	@ 0x57c
  599a14:	e15c0000 	cmp	ip, r0
  599a18:	a1a0c000 	movge	ip, r0
  599a1c:	e541c009 	strb	ip, [r1, #-9]
  599a20:	e5530006 	ldrb	r0, [r3, #-6]
  599a24:	e26000ff 	rsb	r0, r0, #255	@ 0xff
  599a28:	e0688000 	rsb	r8, r8, r0
  599a2c:	e5d2057f 	ldrb	r0, [r2, #1407]	@ 0x57f
  599a30:	e1580000 	cmp	r8, r0
  599a34:	a1a08000 	movge	r8, r0
  599a38:	e5418006 	strb	r8, [r1, #-6]
  599a3c:	e5533003 	ldrb	r3, [r3, #-3]
  599a40:	e26330ff 	rsb	r3, r3, #255	@ 0xff
  599a44:	e06ee003 	rsb	lr, lr, r3
  599a48:	e5d23582 	ldrb	r3, [r2, #1410]	@ 0x582
  599a4c:	e15e0003 	cmp	lr, r3
  599a50:	a1a0e003 	movge	lr, r3
  599a54:	e541e003 	strb	lr, [r1, #-3]
  599a58:	e3a010ff 	mov	r1, #255	@ 0xff
  599a5c:	e55b3035 	ldrb	r3, [fp, #-53]	@ 0xffffffcb
  599a60:	e55b2034 	ldrb	r2, [fp, #-52]	@ 0xffffffcc
  599a64:	e55b0033 	ldrb	r0, [fp, #-51]	@ 0xffffffcd
  599a68:	e0030693 	mul	r3, r3, r6
  599a6c:	e0233592 	mla	r3, r2, r5, r3
  599a70:	e0203a90 	mla	r0, r0, sl, r3
  599a74:	ebfffffe 	bl	6561b4 <__udivsi3>
			599a74: R_ARM_CALL	__aeabi_uidiv
  599a78:	e55b3032 	ldrb	r3, [fp, #-50]	@ 0xffffffce
  599a7c:	e1a08000 	mov	r8, r0
  599a80:	e55b2031 	ldrb	r2, [fp, #-49]	@ 0xffffffcf
  599a84:	e3a010ff 	mov	r1, #255	@ 0xff
  599a88:	e55b0030 	ldrb	r0, [fp, #-48]	@ 0xffffffd0
  599a8c:	e0030693 	mul	r3, r3, r6
  599a90:	e0233592 	mla	r3, r2, r5, r3
  599a94:	e0203a90 	mla	r0, r0, sl, r3
  599a98:	ebfffffe 	bl	6561b4 <__udivsi3>
			599a98: R_ARM_CALL	__aeabi_uidiv
  599a9c:	e55b302f 	ldrb	r3, [fp, #-47]	@ 0xffffffd1
  599aa0:	e1a09000 	mov	r9, r0
  599aa4:	e55b202e 	ldrb	r2, [fp, #-46]	@ 0xffffffd2
  599aa8:	e3a010ff 	mov	r1, #255	@ 0xff
  599aac:	e55b002d 	ldrb	r0, [fp, #-45]	@ 0xffffffd3
  599ab0:	e0030693 	mul	r3, r3, r6
  599ab4:	e0233592 	mla	r3, r2, r5, r3
  599ab8:	e0203a90 	mla	r0, r0, sl, r3
  599abc:	ebfffffe 	bl	6561b4 <__udivsi3>
			599abc: R_ARM_CALL	__aeabi_uidiv
  599ac0:	e3580000 	cmp	r8, #0
  599ac4:	e1a01000 	mov	r1, r0
  599ac8:	1a000004 	bne	599ae0 <amb_driv_compute+0x390>
  599acc:	e3590000 	cmp	r9, #0
  599ad0:	1a000002 	bne	599ae0 <amb_driv_compute+0x390>
  599ad4:	e3500000 	cmp	r0, #0
  599ad8:	03a08a01 	moveq	r8, #4096	@ 0x1000
  599adc:	0a00000b 	beq	599b10 <amb_driv_compute+0x3c0>
  599ae0:	e30f0fff 	movw	r0, #65535	@ 0xffff
  599ae4:	e1570000 	cmp	r7, r0
  599ae8:	31a00007 	movcc	r0, r7
  599aec:	e1590008 	cmp	r9, r8
  599af0:	21a08009 	movcs	r8, r9
  599af4:	e1a00600 	lsl	r0, r0, #12
  599af8:	e1580001 	cmp	r8, r1
  599afc:	21a01008 	movcs	r1, r8
  599b00:	ebfffffe 	bl	6561b4 <__udivsi3>
			599b00: R_ARM_CALL	__aeabi_uidiv
  599b04:	e3500601 	cmp	r0, #1048576	@ 0x100000
  599b08:	31a08000 	movcc	r8, r0
  599b0c:	23a08601 	movcs	r8, #1048576	@ 0x100000
  599b10:	e51b2040 	ldr	r2, [fp, #-64]	@ 0xffffffc0
  599b14:	e3a0900a 	mov	r9, #10
  599b18:	e3a010ff 	mov	r1, #255	@ 0xff
  599b1c:	e6af2072 	sxtb	r2, r2
  599b20:	e0274299 	mla	r7, r9, r2, r4
  599b24:	e50b2040 	str	r2, [fp, #-64]	@ 0xffffffc0
  599b28:	e51be040 	ldr	lr, [fp, #-64]	@ 0xffffffc0
  599b2c:	e5d73009 	ldrb	r3, [r7, #9]
  599b30:	e5d7200a 	ldrb	r2, [r7, #10]
  599b34:	e0030693 	mul	r3, r3, r6
  599b38:	e0233592 	mla	r3, r2, r5, r3
  599b3c:	e28e2001 	add	r2, lr, #1
  599b40:	e0224299 	mla	r2, r9, r2, r4
  599b44:	e5d20001 	ldrb	r0, [r2, #1]
  599b48:	e0203a90 	mla	r0, r0, sl, r3
  599b4c:	ebfffffe 	bl	6561b4 <__udivsi3>
			599b4c: R_ARM_CALL	__aeabi_uidiv
  599b50:	e0020890 	mul	r2, r0, r8
  599b54:	e5d7100d 	ldrb	r1, [r7, #13]
  599b58:	e5d7000e 	ldrb	r0, [r7, #14]
  599b5c:	e1a03622 	lsr	r3, r2, #12
  599b60:	e50b305c 	str	r3, [fp, #-92]	@ 0xffffffa4
  599b64:	e5d7300c 	ldrb	r3, [r7, #12]
  599b68:	e50b206c 	str	r2, [fp, #-108]	@ 0xffffff94
  599b6c:	e0030693 	mul	r3, r3, r6
  599b70:	e0233591 	mla	r3, r1, r5, r3
  599b74:	e3a010ff 	mov	r1, #255	@ 0xff
  599b78:	e0203a90 	mla	r0, r0, sl, r3
  599b7c:	ebfffffe 	bl	6561b4 <__udivsi3>
			599b7c: R_ARM_CALL	__aeabi_uidiv
  599b80:	e0030890 	mul	r3, r0, r8
  599b84:	e5d7000f 	ldrb	r0, [r7, #15]
  599b88:	e5d71010 	ldrb	r1, [r7, #16]
  599b8c:	e0060690 	mul	r6, r0, r6
  599b90:	e5d70011 	ldrb	r0, [r7, #17]
  599b94:	e1a0c623 	lsr	ip, r3, #12
  599b98:	e50b3068 	str	r3, [fp, #-104]	@ 0xffffff98
  599b9c:	e50bc064 	str	ip, [fp, #-100]	@ 0xffffff9c
  599ba0:	e0256591 	mla	r5, r1, r5, r6
  599ba4:	e3a010ff 	mov	r1, #255	@ 0xff
  599ba8:	e0205a90 	mla	r0, r0, sl, r5
  599bac:	ebfffffe 	bl	6561b4 <__udivsi3>
			599bac: R_ARM_CALL	__aeabi_uidiv
  599bb0:	e51b206c 	ldr	r2, [fp, #-108]	@ 0xffffff94
  599bb4:	e0000890 	mul	r0, r0, r8
  599bb8:	e51b3068 	ldr	r3, [fp, #-104]	@ 0xffffff98
  599bbc:	e30f1fff 	movw	r1, #65535	@ 0xffff
  599bc0:	e51bc064 	ldr	ip, [fp, #-100]	@ 0xffffff9c
  599bc4:	e1b02e22 	lsrs	r2, r2, #28
  599bc8:	e51b2040 	ldr	r2, [fp, #-64]	@ 0xffffffc0
  599bcc:	e51b505c 	ldr	r5, [fp, #-92]	@ 0xffffffa4
  599bd0:	11a05001 	movne	r5, r1
  599bd4:	e1b03e23 	lsrs	r3, r3, #28
  599bd8:	e5d77008 	ldrb	r7, [r7, #8]
  599bdc:	e084a002 	add	sl, r4, r2
  599be0:	01a0600c 	moveq	r6, ip
  599be4:	e5da386d 	ldrb	r3, [sl, #2157]	@ 0x86d
  599be8:	11a06001 	movne	r6, r1
  599bec:	e1b0ee20 	lsrs	lr, r0, #28
  599bf0:	11a08001 	movne	r8, r1
  599bf4:	01a08620 	lsreq	r8, r0, #12
  599bf8:	e3530001 	cmp	r3, #1
  599bfc:	1a000006 	bne	599c1c <amb_driv_compute+0x4cc>
  599c00:	e5d4086c 	ldrb	r0, [r4, #2156]	@ 0x86c
  599c04:	e3500009 	cmp	r0, #9
  599c08:	8a000003 	bhi	599c1c <amb_driv_compute+0x4cc>
  599c0c:	e0000097 	mul	r0, r7, r0
  599c10:	e1a01009 	mov	r1, r9
  599c14:	ebfffffe 	bl	6563c0 <__divsi3>
			599c14: R_ARM_CALL	__aeabi_idiv
  599c18:	e6ff7070 	uxth	r7, r0
  599c1c:	e5943094 	ldr	r3, [r4, #148]	@ 0x94
  599c20:	e3530001 	cmp	r3, #1
  599c24:	1a00001e 	bne	599ca4 <amb_driv_compute+0x554>
  599c28:	e5943098 	ldr	r3, [r4, #152]	@ 0x98
  599c2c:	e3530003 	cmp	r3, #3
  599c30:	0a00001b 	beq	599ca4 <amb_driv_compute+0x554>
  599c34:	e5d49585 	ldrb	r9, [r4, #1413]	@ 0x585
  599c38:	e3a01064 	mov	r1, #100	@ 0x64
  599c3c:	e0890309 	add	r0, r9, r9, lsl #6
  599c40:	e1a00080 	lsl	r0, r0, #1
  599c44:	ebfffffe 	bl	6563c0 <__divsi3>
			599c44: R_ARM_CALL	__aeabi_idiv
  599c48:	e3100cff 	tst	r0, #65280	@ 0xff00
  599c4c:	1a000003 	bne	599c60 <amb_driv_compute+0x510>
  599c50:	e6ff0070 	uxth	r0, r0
  599c54:	e3500000 	cmp	r0, #0
  599c58:	0a000007 	beq	599c7c <amb_driv_compute+0x52c>
  599c5c:	ea000000 	b	599c64 <amb_driv_compute+0x514>
  599c60:	e3a000ff 	mov	r0, #255	@ 0xff
  599c64:	e3a03064 	mov	r3, #100	@ 0x64
  599c68:	e1a01009 	mov	r1, r9
  599c6c:	e0000093 	mul	r0, r3, r0
  599c70:	ebfffffe 	bl	6563c0 <__divsi3>
			599c70: R_ARM_CALL	__aeabi_idiv
  599c74:	e2400064 	sub	r0, r0, #100	@ 0x64
  599c78:	e6ef0070 	uxtb	r0, r0
  599c7c:	e350001e 	cmp	r0, #30
  599c80:	e3a01064 	mov	r1, #100	@ 0x64
  599c84:	23a0001e 	movcs	r0, #30
  599c88:	e6ef0070 	uxtb	r0, r0
  599c8c:	e2800064 	add	r0, r0, #100	@ 0x64
  599c90:	e0000790 	mul	r0, r0, r7
  599c94:	ebfffffe 	bl	6563c0 <__divsi3>
			599c94: R_ARM_CALL	__aeabi_idiv
  599c98:	e3100cff 	tst	r0, #65280	@ 0xff00
  599c9c:	06ff7070 	uxtheq	r7, r0
  599ca0:	13a070ff 	movne	r7, #255	@ 0xff
  599ca4:	e5d4308c 	ldrb	r3, [r4, #140]	@ 0x8c
  599ca8:	e2877001 	add	r7, r7, #1
  599cac:	e1530007 	cmp	r3, r7
  599cb0:	d0637007 	rsble	r7, r3, r7
  599cb4:	e5943000 	ldr	r3, [r4]
  599cb8:	d0050795 	mulle	r5, r5, r7
  599cbc:	c3a08000 	movgt	r8, #0
  599cc0:	c1a06008 	movgt	r6, r8
  599cc4:	c1a05008 	movgt	r5, r8
  599cc8:	d0060796 	mulle	r6, r6, r7
  599ccc:	d0080798 	mulle	r8, r8, r7
  599cd0:	d1a05425 	lsrle	r5, r5, #8
  599cd4:	d1a06426 	lsrle	r6, r6, #8
  599cd8:	d1a08428 	lsrle	r8, r8, #8
  599cdc:	e3530000 	cmp	r3, #0
  599ce0:	1a00000b 	bne	599d14 <amb_driv_compute+0x5c4>
  599ce4:	e1a02825 	lsr	r2, r5, #16
  599ce8:	e30f3fff 	movw	r3, #65535	@ 0xffff
  599cec:	e1a02802 	lsl	r2, r2, #16
  599cf0:	e3520000 	cmp	r2, #0
  599cf4:	e1a02826 	lsr	r2, r6, #16
  599cf8:	11a05003 	movne	r5, r3
  599cfc:	e1a02802 	lsl	r2, r2, #16
  599d00:	e3520000 	cmp	r2, #0
  599d04:	e1a02828 	lsr	r2, r8, #16
  599d08:	11a06003 	movne	r6, r3
  599d0c:	e1a02802 	lsl	r2, r2, #16
  599d10:	ea000010 	b	599d58 <amb_driv_compute+0x608>
  599d14:	e2855008 	add	r5, r5, #8
  599d18:	e2866008 	add	r6, r6, #8
  599d1c:	e1a05225 	lsr	r5, r5, #4
  599d20:	e1a06226 	lsr	r6, r6, #4
  599d24:	e3c52eff 	bic	r2, r5, #4080	@ 0xff0
  599d28:	e2888008 	add	r8, r8, #8
  599d2c:	e3c2200f 	bic	r2, r2, #15
  599d30:	e1a08228 	lsr	r8, r8, #4
  599d34:	e3520000 	cmp	r2, #0
  599d38:	e3c62eff 	bic	r2, r6, #4080	@ 0xff0
  599d3c:	e3003fff 	movw	r3, #4095	@ 0xfff
  599d40:	e3c2200f 	bic	r2, r2, #15
  599d44:	11a05003 	movne	r5, r3
  599d48:	e3520000 	cmp	r2, #0
  599d4c:	e3c82eff 	bic	r2, r8, #4080	@ 0xff0
  599d50:	11a06003 	movne	r6, r3
  599d54:	e3c2200f 	bic	r2, r2, #15
  599d58:	e3520000 	cmp	r2, #0
  599d5c:	11a08003 	movne	r8, r3
  599d60:	e594387c 	ldr	r3, [r4, #2172]	@ 0x87c
  599d64:	e3530001 	cmp	r3, #1
  599d68:	1a00001c 	bne	599de0 <amb_driv_compute+0x690>
  599d6c:	e51b904c 	ldr	r9, [fp, #-76]	@ 0xffffffb4
  599d70:	e59430a8 	ldr	r3, [r4, #168]	@ 0xa8
  599d74:	e59410b0 	ldr	r1, [r4, #176]	@ 0xb0
  599d78:	e3590000 	cmp	r9, #0
  599d7c:	e59420ac 	ldr	r2, [r4, #172]	@ 0xac
  599d80:	0a000004 	beq	599d98 <amb_driv_compute+0x648>
  599d84:	e0813003 	add	r3, r1, r3
  599d88:	e0833002 	add	r3, r3, r2
  599d8c:	e2433001 	sub	r3, r3, #1
  599d90:	e1590003 	cmp	r9, r3
  599d94:	1a000011 	bne	599de0 <amb_driv_compute+0x690>
  599d98:	e3041b23 	movw	r1, #19235	@ 0x4b23
  599d9c:	e3023646 	movw	r3, #9798	@ 0x2646
  599da0:	e0010691 	mul	r1, r1, r6
  599da4:	e0211593 	mla	r1, r3, r5, r1
  599da8:	e3003e98 	movw	r3, #3736	@ 0xe98
  599dac:	e0211893 	mla	r1, r3, r8, r1
  599db0:	e2811901 	add	r1, r1, #16384	@ 0x4000
  599db4:	e1a017c1 	asr	r1, r1, #15
  599db8:	e3510d7d 	cmp	r1, #8000	@ 0x1f40
  599dbc:	da000007 	ble	599de0 <amb_driv_compute+0x690>
  599dc0:	e3a00a7d 	mov	r0, #512000	@ 0x7d000
  599dc4:	ebfffffe 	bl	6563c0 <__divsi3>
			599dc4: R_ARM_CALL	__aeabi_idiv
  599dc8:	e0050095 	mul	r5, r5, r0
  599dcc:	e0060096 	mul	r6, r6, r0
  599dd0:	e0080098 	mul	r8, r8, r0
  599dd4:	e1a05345 	asr	r5, r5, #6
  599dd8:	e1a06346 	asr	r6, r6, #6
  599ddc:	e1a08348 	asr	r8, r8, #6
  599de0:	e594358c 	ldr	r3, [r4, #1420]	@ 0x58c
  599de4:	e51b904c 	ldr	r9, [fp, #-76]	@ 0xffffffb4
  599de8:	e0833005 	add	r3, r3, r5
  599dec:	e584358c 	str	r3, [r4, #1420]	@ 0x58c
  599df0:	e5943590 	ldr	r3, [r4, #1424]	@ 0x590
  599df4:	e0833006 	add	r3, r3, r6
  599df8:	e5843590 	str	r3, [r4, #1424]	@ 0x590
  599dfc:	e5943594 	ldr	r3, [r4, #1428]	@ 0x594
  599e00:	e0833008 	add	r3, r3, r8
  599e04:	e5843594 	str	r3, [r4, #1428]	@ 0x594
  599e08:	e3a0300c 	mov	r3, #12
  599e0c:	e0030993 	mul	r3, r3, r9
  599e10:	e51b9058 	ldr	r9, [fp, #-88]	@ 0xffffffa8
  599e14:	e0892003 	add	r2, r9, r3
  599e18:	e5825fec 	str	r5, [r2, #4076]	@ 0xfec
  599e1c:	e59420a0 	ldr	r2, [r4, #160]	@ 0xa0
  599e20:	e0822003 	add	r2, r2, r3
  599e24:	e5826ff0 	str	r6, [r2, #4080]	@ 0xff0
  599e28:	e59420a0 	ldr	r2, [r4, #160]	@ 0xa0
  599e2c:	e0823003 	add	r3, r2, r3
  599e30:	e5838ff4 	str	r8, [r3, #4084]	@ 0xff4
  599e34:	e51b3048 	ldr	r3, [fp, #-72]	@ 0xffffffb8
  599e38:	e51b9044 	ldr	r9, [fp, #-68]	@ 0xffffffbc
  599e3c:	e583559c 	str	r5, [r3, #1436]	@ 0x59c
  599e40:	e283300c 	add	r3, r3, #12
  599e44:	e5836594 	str	r6, [r3, #1428]	@ 0x594
  599e48:	e2899001 	add	r9, r9, #1
  599e4c:	e5838598 	str	r8, [r3, #1432]	@ 0x598
  599e50:	e50b3048 	str	r3, [fp, #-72]	@ 0xffffffb8
  599e54:	e51b3050 	ldr	r3, [fp, #-80]	@ 0xffffffb0
  599e58:	e50b9044 	str	r9, [fp, #-68]	@ 0xffffffbc
  599e5c:	e2833002 	add	r3, r3, #2
  599e60:	e50b3050 	str	r3, [fp, #-80]	@ 0xffffffb0
  599e64:	e51b3060 	ldr	r3, [fp, #-96]	@ 0xffffffa0
  599e68:	e1590003 	cmp	r9, r3
  599e6c:	1afffe65 	bne	599808 <amb_driv_compute+0xb8>
  599e70:	eafffe69 	b	59981c <amb_driv_compute+0xcc>
  599e74:	e593159c 	ldr	r1, [r3, #1436]	@ 0x59c
  599e78:	e2522001 	subs	r2, r2, #1
  599e7c:	e283300c 	add	r3, r3, #12
  599e80:	e0010091 	mul	r1, r1, r0
  599e84:	e1a01521 	lsr	r1, r1, #10
  599e88:	e5831590 	str	r1, [r3, #1424]	@ 0x590
  599e8c:	e5931594 	ldr	r1, [r3, #1428]	@ 0x594
  599e90:	e0010091 	mul	r1, r1, r0
  599e94:	e1a01521 	lsr	r1, r1, #10
  599e98:	e5831594 	str	r1, [r3, #1428]	@ 0x594
  599e9c:	e5931598 	ldr	r1, [r3, #1432]	@ 0x598
  599ea0:	e0010091 	mul	r1, r1, r0
  599ea4:	e1a01521 	lsr	r1, r1, #10
  599ea8:	e5831598 	str	r1, [r3, #1432]	@ 0x598
  599eac:	1afffff0 	bne	599e74 <amb_driv_compute+0x724>
  599eb0:	e1a05007 	mov	r5, r7
  599eb4:	e3560000 	cmp	r6, #0
  599eb8:	05846578 	streq	r6, [r4, #1400]	@ 0x578
  599ebc:	0a000003 	beq	599ed0 <amb_driv_compute+0x780>
  599ec0:	e1a00405 	lsl	r0, r5, #8
  599ec4:	e1a01006 	mov	r1, r6
  599ec8:	ebfffffe 	bl	6561b4 <__udivsi3>
			599ec8: R_ARM_CALL	__aeabi_uidiv
  599ecc:	e5840578 	str	r0, [r4, #1400]	@ 0x578
  599ed0:	e1a00005 	mov	r0, r5
  599ed4:	e3a01e7d 	mov	r1, #2000	@ 0x7d0
  599ed8:	ebfffffe 	bl	6561b4 <__udivsi3>
			599ed8: R_ARM_CALL	__aeabi_uidiv
  599edc:	e5943000 	ldr	r3, [r4]
  599ee0:	e35000ff 	cmp	r0, #255	@ 0xff
  599ee4:	23a000ff 	movcs	r0, #255	@ 0xff
  599ee8:	e5840574 	str	r0, [r4, #1396]	@ 0x574
  599eec:	e3530000 	cmp	r3, #0
  599ef0:	1a000062 	bne	59a080 <amb_driv_compute+0x930>
  599ef4:	e284ee59 	add	lr, r4, #1424	@ 0x590
  599ef8:	e2847038 	add	r7, r4, #56	@ 0x38
  599efc:	e28ee00c 	add	lr, lr, #12
  599f00:	e1a00004 	mov	r0, r4
  599f04:	e3e08069 	mvn	r8, #105	@ 0x69
  599f08:	e5843570 	str	r3, [r4, #1392]	@ 0x570
  599f0c:	e1500007 	cmp	r0, r7
  599f10:	0a000033 	beq	599fe4 <amb_driv_compute+0x894>
  599f14:	e5d02132 	ldrb	r2, [r0, #306]	@ 0x132
  599f18:	e35200ff 	cmp	r2, #255	@ 0xff
  599f1c:	0a000030 	beq	599fe4 <amb_driv_compute+0x894>
  599f20:	e1a0200e 	mov	r2, lr
  599f24:	e3a0c000 	mov	ip, #0
  599f28:	e35c0000 	cmp	ip, #0
  599f2c:	1a000012 	bne	599f7c <amb_driv_compute+0x82c>
  599f30:	e5d411ac 	ldrb	r1, [r4, #428]	@ 0x1ac
  599f34:	e2836003 	add	r6, r3, #3
  599f38:	e5d451ae 	ldrb	r5, [r4, #430]	@ 0x1ae
  599f3c:	e3560d0f 	cmp	r6, #960	@ 0x3c0
  599f40:	e3811496 	orr	r1, r1, #-1778384896	@ 0x96000000
  599f44:	e3811501 	orr	r1, r1, #4194304	@ 0x400000
  599f48:	e1811705 	orr	r1, r1, r5, lsl #14
  599f4c:	e5d451ad 	ldrb	r5, [r4, #429]	@ 0x1ad
  599f50:	e1811385 	orr	r1, r1, r5, lsl #7
  599f54:	ca000008 	bgt	599f7c <amb_driv_compute+0x82c>
  599f58:	e1a09841 	asr	r9, r1, #16
  599f5c:	e0845003 	add	r5, r4, r3
  599f60:	e2833004 	add	r3, r3, #4
  599f64:	e5c581af 	strb	r8, [r5, #431]	@ 0x1af
  599f68:	e5c591b0 	strb	r9, [r5, #432]	@ 0x1b0
  599f6c:	e1a09441 	asr	r9, r1, #8
  599f70:	e0846006 	add	r6, r4, r6
  599f74:	e5c591b1 	strb	r9, [r5, #433]	@ 0x1b1
  599f78:	e5c611af 	strb	r1, [r6, #431]	@ 0x1af
  599f7c:	e2836005 	add	r6, r3, #5
  599f80:	e3560d0f 	cmp	r6, #960	@ 0x3c0
  599f84:	ca00000e 	bgt	599fc4 <amb_driv_compute+0x874>
  599f88:	e592502c 	ldr	r5, [r2, #44]	@ 0x2c
  599f8c:	e0841003 	add	r1, r4, r3
  599f90:	e2833006 	add	r3, r3, #6
  599f94:	e0846006 	add	r6, r4, r6
  599f98:	e5c151b0 	strb	r5, [r1, #432]	@ 0x1b0
  599f9c:	e1a09425 	lsr	r9, r5, #8
  599fa0:	e5c191af 	strb	r9, [r1, #431]	@ 0x1af
  599fa4:	e5925028 	ldr	r5, [r2, #40]	@ 0x28
  599fa8:	e5c151b2 	strb	r5, [r1, #434]	@ 0x1b2
  599fac:	e1a09425 	lsr	r9, r5, #8
  599fb0:	e5c191b1 	strb	r9, [r1, #433]	@ 0x1b1
  599fb4:	e5925024 	ldr	r5, [r2, #36]	@ 0x24
  599fb8:	e1a09425 	lsr	r9, r5, #8
  599fbc:	e5c191b3 	strb	r9, [r1, #435]	@ 0x1b3
  599fc0:	e5c651af 	strb	r5, [r6, #431]	@ 0x1af
  599fc4:	e28cc001 	add	ip, ip, #1
  599fc8:	e242200c 	sub	r2, r2, #12
  599fcc:	e35c0004 	cmp	ip, #4
  599fd0:	1affffd4 	bne	599f28 <amb_driv_compute+0x7d8>
  599fd4:	e5843570 	str	r3, [r4, #1392]	@ 0x570
  599fd8:	e28ee030 	add	lr, lr, #48	@ 0x30
  599fdc:	e2800004 	add	r0, r0, #4
  599fe0:	eaffffc9 	b	599f0c <amb_driv_compute+0x7bc>
  599fe4:	e5d451ac 	ldrb	r5, [r4, #428]	@ 0x1ac
  599fe8:	e3a03029 	mov	r3, #41	@ 0x29
  599fec:	e5d481ad 	ldrb	r8, [r4, #429]	@ 0x1ad
  599ff0:	e3a0607d 	mov	r6, #125	@ 0x7d
  599ff4:	e5d471ae 	ldrb	r7, [r4, #430]	@ 0x1ae
  599ff8:	e30f1fff 	movw	r1, #65535	@ 0xffff
  599ffc:	e5940590 	ldr	r0, [r4, #1424]	@ 0x590
  59a000:	e1a05185 	lsl	r5, r5, #3
  59a004:	e1a08188 	lsl	r8, r8, #3
  59a008:	e1a07187 	lsl	r7, r7, #3
  59a00c:	e0050593 	mul	r5, r3, r5
  59a010:	e1a00500 	lsl	r0, r0, #10
  59a014:	e0080893 	mul	r8, r3, r8
  59a018:	e0030793 	mul	r3, r3, r7
  59a01c:	e1a05545 	asr	r5, r5, #10
  59a020:	e1a08548 	asr	r8, r8, #10
  59a024:	e5c45586 	strb	r5, [r4, #1414]	@ 0x586
  59a028:	e1a07543 	asr	r7, r3, #10
  59a02c:	e5c48587 	strb	r8, [r4, #1415]	@ 0x587
  59a030:	e5c47588 	strb	r7, [r4, #1416]	@ 0x588
  59a034:	ebfffffe 	bl	6561b4 <__udivsi3>
			59a034: R_ARM_CALL	__aeabi_uidiv
  59a038:	e0000096 	mul	r0, r6, r0
  59a03c:	e30f1fff 	movw	r1, #65535	@ 0xffff
  59a040:	e0080098 	mul	r8, r8, r0
  59a044:	e594058c 	ldr	r0, [r4, #1420]	@ 0x58c
  59a048:	e1a00500 	lsl	r0, r0, #10
  59a04c:	e1a08528 	lsr	r8, r8, #10
  59a050:	ebfffffe 	bl	6561b4 <__udivsi3>
			59a050: R_ARM_CALL	__aeabi_uidiv
  59a054:	e0000096 	mul	r0, r6, r0
  59a058:	e30f1fff 	movw	r1, #65535	@ 0xffff
  59a05c:	e0050095 	mul	r5, r5, r0
  59a060:	e5940594 	ldr	r0, [r4, #1428]	@ 0x594
  59a064:	e1a00500 	lsl	r0, r0, #10
  59a068:	e0885525 	add	r5, r8, r5, lsr #10
  59a06c:	ebfffffe 	bl	6561b4 <__udivsi3>
			59a06c: R_ARM_CALL	__aeabi_uidiv
  59a070:	e0000096 	mul	r0, r6, r0
  59a074:	e0020097 	mul	r2, r7, r0
  59a078:	e0852522 	add	r2, r5, r2, lsr #10
  59a07c:	ea0000b9 	b	59a368 <amb_driv_compute+0xc18>
  59a080:	e3530001 	cmp	r3, #1
  59a084:	e3a02000 	mov	r2, #0
  59a088:	1a0000b6 	bne	59a368 <amb_driv_compute+0xc18>
  59a08c:	e51b9054 	ldr	r9, [fp, #-84]	@ 0xffffffac
  59a090:	e1d4ebb8 	ldrh	lr, [r4, #184]	@ 0xb8
  59a094:	e5842570 	str	r2, [r4, #1392]	@ 0x570
  59a098:	e359003f 	cmp	r9, #63	@ 0x3f
  59a09c:	9a000046 	bls	59a1bc <amb_driv_compute+0xa6c>
  59a0a0:	e3e0103e 	mvn	r1, #62	@ 0x3e
  59a0a4:	e1a05002 	mov	r5, r2
  59a0a8:	e5c411af 	strb	r1, [r4, #431]	@ 0x1af
  59a0ac:	e3e06007 	mvn	r6, #7
  59a0b0:	e1a01002 	mov	r1, r2
  59a0b4:	e155000e 	cmp	r5, lr
  59a0b8:	aa00003a 	bge	59a1a8 <amb_driv_compute+0xa58>
  59a0bc:	e5d401ae 	ldrb	r0, [r4, #430]	@ 0x1ae
  59a0c0:	e2822006 	add	r2, r2, #6
  59a0c4:	e1a0c003 	mov	ip, r3
  59a0c8:	e0801301 	add	r1, r0, r1, lsl #6
  59a0cc:	e1a00002 	mov	r0, r2
  59a0d0:	e3500007 	cmp	r0, #7
  59a0d4:	9a000008 	bls	59a0fc <amb_driv_compute+0x9ac>
  59a0d8:	e35c0d0f 	cmp	ip, #960	@ 0x3c0
  59a0dc:	cafffffd 	bgt	59a0d8 <amb_driv_compute+0x988>
  59a0e0:	e2400008 	sub	r0, r0, #8
  59a0e4:	e084800c 	add	r8, r4, ip
  59a0e8:	e1a07031 	lsr	r7, r1, r0
  59a0ec:	e28cc001 	add	ip, ip, #1
  59a0f0:	e5c871af 	strb	r7, [r8, #431]	@ 0x1af
  59a0f4:	e0411017 	sub	r1, r1, r7, lsl r0
  59a0f8:	eafffff4 	b	59a0d0 <amb_driv_compute+0x980>
  59a0fc:	e1a001a2 	lsr	r0, r2, #3
  59a100:	e0222096 	mla	r2, r6, r0, r2
  59a104:	e0833000 	add	r3, r3, r0
  59a108:	e5d401ad 	ldrb	r0, [r4, #429]	@ 0x1ad
  59a10c:	e1a0c003 	mov	ip, r3
  59a110:	e2822006 	add	r2, r2, #6
  59a114:	e0801301 	add	r1, r0, r1, lsl #6
  59a118:	e1a00002 	mov	r0, r2
  59a11c:	e3500007 	cmp	r0, #7
  59a120:	9a000008 	bls	59a148 <amb_driv_compute+0x9f8>
  59a124:	e35c0d0f 	cmp	ip, #960	@ 0x3c0
  59a128:	cafffffd 	bgt	59a124 <amb_driv_compute+0x9d4>
  59a12c:	e2400008 	sub	r0, r0, #8
  59a130:	e084800c 	add	r8, r4, ip
  59a134:	e1a07031 	lsr	r7, r1, r0
  59a138:	e28cc001 	add	ip, ip, #1
  59a13c:	e5c871af 	strb	r7, [r8, #431]	@ 0x1af
  59a140:	e0411017 	sub	r1, r1, r7, lsl r0
  59a144:	eafffff4 	b	59a11c <amb_driv_compute+0x9cc>
  59a148:	e1a001a2 	lsr	r0, r2, #3
  59a14c:	e0222096 	mla	r2, r6, r0, r2
  59a150:	e0833000 	add	r3, r3, r0
  59a154:	e5d401ac 	ldrb	r0, [r4, #428]	@ 0x1ac
  59a158:	e1a0c003 	mov	ip, r3
  59a15c:	e2822006 	add	r2, r2, #6
  59a160:	e0801301 	add	r1, r0, r1, lsl #6
  59a164:	e1a00002 	mov	r0, r2
  59a168:	e3500007 	cmp	r0, #7
  59a16c:	9a000008 	bls	59a194 <amb_driv_compute+0xa44>
  59a170:	e35c0d0f 	cmp	ip, #960	@ 0x3c0
  59a174:	cafffffd 	bgt	59a170 <amb_driv_compute+0xa20>
  59a178:	e2400008 	sub	r0, r0, #8
  59a17c:	e084800c 	add	r8, r4, ip
  59a180:	e1a07031 	lsr	r7, r1, r0
  59a184:	e28cc001 	add	ip, ip, #1
  59a188:	e5c871af 	strb	r7, [r8, #431]	@ 0x1af
  59a18c:	e0411017 	sub	r1, r1, r7, lsl r0
  59a190:	eafffff4 	b	59a168 <amb_driv_compute+0xa18>
  59a194:	e1a001a2 	lsr	r0, r2, #3
  59a198:	e2855001 	add	r5, r5, #1
  59a19c:	e0222096 	mla	r2, r6, r0, r2
  59a1a0:	e0833000 	add	r3, r3, r0
  59a1a4:	eaffffc2 	b	59a0b4 <amb_driv_compute+0x964>
  59a1a8:	e5843570 	str	r3, [r4, #1392]	@ 0x570
  59a1ac:	e3a02000 	mov	r2, #0
  59a1b0:	e59f31c8 	ldr	r3, [pc, #456]	@ 59a380 <amb_driv_compute+0xc30>
  59a1b4:	e5c32000 	strb	r2, [r3]
  59a1b8:	ea000044 	b	59a2d0 <amb_driv_compute+0xb80>
  59a1bc:	e3e0103d 	mvn	r1, #61	@ 0x3d
  59a1c0:	e1a00004 	mov	r0, r4
  59a1c4:	e5c411af 	strb	r1, [r4, #431]	@ 0x1af
  59a1c8:	e1a06002 	mov	r6, r2
  59a1cc:	e1a01002 	mov	r1, r2
  59a1d0:	e3e07007 	mvn	r7, #7
  59a1d4:	e156000e 	cmp	r6, lr
  59a1d8:	aa00003b 	bge	59a2cc <amb_driv_compute+0xb7c>
  59a1dc:	e590c5a4 	ldr	ip, [r0, #1444]	@ 0x5a4
  59a1e0:	e282200c 	add	r2, r2, #12
  59a1e4:	e1a05003 	mov	r5, r3
  59a1e8:	e08c1601 	add	r1, ip, r1, lsl #12
  59a1ec:	e1a0c002 	mov	ip, r2
  59a1f0:	e35c0007 	cmp	ip, #7
  59a1f4:	9a000008 	bls	59a21c <amb_driv_compute+0xacc>
  59a1f8:	e3550d0f 	cmp	r5, #960	@ 0x3c0
  59a1fc:	cafffffd 	bgt	59a1f8 <amb_driv_compute+0xaa8>
  59a200:	e24cc008 	sub	ip, ip, #8
  59a204:	e0849005 	add	r9, r4, r5
  59a208:	e1a08c31 	lsr	r8, r1, ip
  59a20c:	e2855001 	add	r5, r5, #1
  59a210:	e5c981af 	strb	r8, [r9, #431]	@ 0x1af
  59a214:	e0411c18 	sub	r1, r1, r8, lsl ip
  59a218:	eafffff4 	b	59a1f0 <amb_driv_compute+0xaa0>
  59a21c:	e1a0c1a2 	lsr	ip, r2, #3
  59a220:	e0222c97 	mla	r2, r7, ip, r2
  59a224:	e083300c 	add	r3, r3, ip
  59a228:	e590c5a0 	ldr	ip, [r0, #1440]	@ 0x5a0
  59a22c:	e1a05003 	mov	r5, r3
  59a230:	e282200c 	add	r2, r2, #12
  59a234:	e08c1601 	add	r1, ip, r1, lsl #12
  59a238:	e1a0c002 	mov	ip, r2
  59a23c:	e35c0007 	cmp	ip, #7
  59a240:	9a000008 	bls	59a268 <amb_driv_compute+0xb18>
  59a244:	e3550d0f 	cmp	r5, #960	@ 0x3c0
  59a248:	cafffffd 	bgt	59a244 <amb_driv_compute+0xaf4>
  59a24c:	e24cc008 	sub	ip, ip, #8
  59a250:	e0849005 	add	r9, r4, r5
  59a254:	e1a08c31 	lsr	r8, r1, ip
  59a258:	e2855001 	add	r5, r5, #1
  59a25c:	e5c981af 	strb	r8, [r9, #431]	@ 0x1af
  59a260:	e0411c18 	sub	r1, r1, r8, lsl ip
  59a264:	eafffff4 	b	59a23c <amb_driv_compute+0xaec>
  59a268:	e1a0c1a2 	lsr	ip, r2, #3
  59a26c:	e0222c97 	mla	r2, r7, ip, r2
  59a270:	e083300c 	add	r3, r3, ip
  59a274:	e590c59c 	ldr	ip, [r0, #1436]	@ 0x59c
  59a278:	e1a05003 	mov	r5, r3
  59a27c:	e282200c 	add	r2, r2, #12
  59a280:	e08c1601 	add	r1, ip, r1, lsl #12
  59a284:	e1a0c002 	mov	ip, r2
  59a288:	e35c0007 	cmp	ip, #7
  59a28c:	9a000008 	bls	59a2b4 <amb_driv_compute+0xb64>
  59a290:	e3550d0f 	cmp	r5, #960	@ 0x3c0
  59a294:	cafffffd 	bgt	59a290 <amb_driv_compute+0xb40>
  59a298:	e24cc008 	sub	ip, ip, #8
  59a29c:	e0849005 	add	r9, r4, r5
  59a2a0:	e1a08c31 	lsr	r8, r1, ip
  59a2a4:	e2855001 	add	r5, r5, #1
  59a2a8:	e5c981af 	strb	r8, [r9, #431]	@ 0x1af
  59a2ac:	e0411c18 	sub	r1, r1, r8, lsl ip
  59a2b0:	eafffff4 	b	59a288 <amb_driv_compute+0xb38>
  59a2b4:	e1a0c1a2 	lsr	ip, r2, #3
  59a2b8:	e2866001 	add	r6, r6, #1
  59a2bc:	e280000c 	add	r0, r0, #12
  59a2c0:	e0222c97 	mla	r2, r7, ip, r2
  59a2c4:	e083300c 	add	r3, r3, ip
  59a2c8:	eaffffc1 	b	59a1d4 <amb_driv_compute+0xa84>
  59a2cc:	e5843570 	str	r3, [r4, #1392]	@ 0x570
  59a2d0:	e5d461ac 	ldrb	r6, [r4, #428]	@ 0x1ac
  59a2d4:	e3a03029 	mov	r3, #41	@ 0x29
  59a2d8:	e5d481ad 	ldrb	r8, [r4, #429]	@ 0x1ad
  59a2dc:	e3a0507d 	mov	r5, #125	@ 0x7d
  59a2e0:	e5d471ae 	ldrb	r7, [r4, #430]	@ 0x1ae
  59a2e4:	e3001fff 	movw	r1, #4095	@ 0xfff
  59a2e8:	e5940590 	ldr	r0, [r4, #1424]	@ 0x590
  59a2ec:	e1a06206 	lsl	r6, r6, #4
  59a2f0:	e1a08208 	lsl	r8, r8, #4
  59a2f4:	e1a07207 	lsl	r7, r7, #4
  59a2f8:	e0060693 	mul	r6, r3, r6
  59a2fc:	e1a00500 	lsl	r0, r0, #10
  59a300:	e0080893 	mul	r8, r3, r8
  59a304:	e0030793 	mul	r3, r3, r7
  59a308:	e1a06546 	asr	r6, r6, #10
  59a30c:	e1a08548 	asr	r8, r8, #10
  59a310:	e5c46586 	strb	r6, [r4, #1414]	@ 0x586
  59a314:	e1a07543 	asr	r7, r3, #10
  59a318:	e5c48587 	strb	r8, [r4, #1415]	@ 0x587
  59a31c:	e5c47588 	strb	r7, [r4, #1416]	@ 0x588
  59a320:	ebfffffe 	bl	6561b4 <__udivsi3>
			59a320: R_ARM_CALL	__aeabi_uidiv
  59a324:	e0000095 	mul	r0, r5, r0
  59a328:	e3001fff 	movw	r1, #4095	@ 0xfff
  59a32c:	e0080098 	mul	r8, r8, r0
  59a330:	e594058c 	ldr	r0, [r4, #1420]	@ 0x58c
  59a334:	e1a00500 	lsl	r0, r0, #10
  59a338:	e1a08528 	lsr	r8, r8, #10
  59a33c:	ebfffffe 	bl	6561b4 <__udivsi3>
			59a33c: R_ARM_CALL	__aeabi_uidiv
  59a340:	e0000095 	mul	r0, r5, r0
  59a344:	e3001fff 	movw	r1, #4095	@ 0xfff
  59a348:	e0060096 	mul	r6, r6, r0
  59a34c:	e5940594 	ldr	r0, [r4, #1428]	@ 0x594
  59a350:	e1a00500 	lsl	r0, r0, #10
  59a354:	e0886526 	add	r6, r8, r6, lsr #10
  59a358:	ebfffffe 	bl	6561b4 <__udivsi3>
			59a358: R_ARM_CALL	__aeabi_uidiv
  59a35c:	e0000095 	mul	r0, r5, r0
  59a360:	e0020097 	mul	r2, r7, r0
  59a364:	e0862522 	add	r2, r6, r2, lsr #10
  59a368:	e5842574 	str	r2, [r4, #1396]	@ 0x574
  59a36c:	e3a00001 	mov	r0, #1
  59a370:	ea000000 	b	59a378 <amb_driv_compute+0xc28>
  59a374:	e1a00004 	mov	r0, r4
  59a378:	e24bd028 	sub	sp, fp, #40	@ 0x28
  59a37c:	e89daff0 	ldm	sp, {r4, r5, r6, r7, r8, r9, sl, fp, sp, pc}
  59a380:	000c1c58 	andeq	r1, ip, r8, asr ip
			59a380: R_ARM_ABS32	.bss

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:

work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

00190920 <vDrvAmbiLitUpdateLine>:
  190920:	e1a0c00d 	mov	ip, sp
  190924:	e92ddff0 	push	{r4, r5, r6, r7, r8, r9, sl, fp, ip, lr, pc}
  190928:	e24cb004 	sub	fp, ip, #4
  19092c:	e24dd00c 	sub	sp, sp, #12
  190930:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
  190934:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			190934: R_ARM_CALL	__gnu_mcount_nc
  190938:	e59f60c8 	ldr	r6, [pc, #200]	@ 190a08 <vDrvAmbiLitUpdateLine+0xe8>
  19093c:	e1a07000 	mov	r7, r0
  190940:	e59fa0c4 	ldr	sl, [pc, #196]	@ 190a0c <vDrvAmbiLitUpdateLine+0xec>
  190944:	e3a04000 	mov	r4, #0
  190948:	e1a09001 	mov	r9, r1
  19094c:	e5560cba 	ldrb	r0, [r6, #-3258]	@ 0xfffff346
  190950:	e1a08006 	mov	r8, r6
  190954:	e3a01014 	mov	r1, #20
  190958:	e1a05002 	mov	r5, r2
  19095c:	e0863000 	add	r3, r6, r0
  190960:	e2800001 	add	r0, r0, #1
  190964:	e5432cb9 	strb	r2, [r3, #-3257]	@ 0xfffff347
  190968:	e6ef0070 	uxtb	r0, r0
  19096c:	ebfffffe 	bl	6563a0 <__aeabi_uidivmod>
			19096c: R_ARM_CALL	__aeabi_uidivmod
  190970:	e5461cba 	strb	r1, [r6, #-3258]	@ 0xfffff346
  190974:	e5583cbc 	ldrb	r3, [r8, #-3260]	@ 0xfffff344
  190978:	e1530004 	cmp	r3, r4
  19097c:	9a00001f 	bls	190a00 <vDrvAmbiLitUpdateLine+0xe0>
  190980:	e59f0088 	ldr	r0, [pc, #136]	@ 190a10 <vDrvAmbiLitUpdateLine+0xf0>
  190984:	ebfffffe 	bl	398a68 <u2IO32Read2B>
			190984: R_ARM_CALL	u2IO32Read2B
  190988:	e1a01000 	mov	r1, r0
  19098c:	e59f0080 	ldr	r0, [pc, #128]	@ 190a14 <vDrvAmbiLitUpdateLine+0xf4>
  190990:	e50b1030 	str	r1, [fp, #-48]	@ 0xffffffd0
  190994:	ebfffffe 	bl	398a68 <u2IO32Read2B>
			190994: R_ARM_CALL	u2IO32Read2B
  190998:	e7e432d0 	ubfx	r3, r0, #5, #5
  19099c:	e5560cbc 	ldrb	r0, [r6, #-3260]	@ 0xfffff344
  1909a0:	e51b1030 	ldr	r1, [fp, #-48]	@ 0xffffffd0
  1909a4:	e59a2b0c 	ldr	r2, [sl, #2828]	@ 0xb0c
  1909a8:	e0204095 	mla	r0, r5, r0, r4
  1909ac:	e1a00080 	lsl	r0, r0, #1
  1909b0:	e18710b0 	strh	r1, [r7, r0]
  1909b4:	e5561cbc 	ldrb	r1, [r6, #-3260]	@ 0xfffff344
  1909b8:	e0214195 	mla	r1, r5, r1, r4
  1909bc:	e2811d0a 	add	r1, r1, #640	@ 0x280
  1909c0:	e1a01081 	lsl	r1, r1, #1
  1909c4:	e18720b1 	strh	r2, [r7, r1]
  1909c8:	e1a02822 	lsr	r2, r2, #16
  1909cc:	e5561cbc 	ldrb	r1, [r6, #-3260]	@ 0xfffff344
  1909d0:	e0214195 	mla	r1, r5, r1, r4
  1909d4:	e2811c05 	add	r1, r1, #1280	@ 0x500
  1909d8:	e1a01081 	lsl	r1, r1, #1
  1909dc:	e18720b1 	strh	r2, [r7, r1]
  1909e0:	e5562cbc 	ldrb	r2, [r6, #-3260]	@ 0xfffff344
  1909e4:	e0229295 	mla	r2, r5, r2, r9
  1909e8:	e7c23004 	strb	r3, [r2, r4]
  1909ec:	e0862004 	add	r2, r6, r4
  1909f0:	e2844001 	add	r4, r4, #1
  1909f4:	e5423ca5 	strb	r3, [r2, #-3237]	@ 0xfffff35b
  1909f8:	e6ef4074 	uxtb	r4, r4
  1909fc:	eaffffdc 	b	190974 <vDrvAmbiLitUpdateLine+0x54>
  190a00:	e24bd028 	sub	sp, fp, #40	@ 0x28
  190a04:	e89daff0 	ldm	sp, {r4, r5, r6, r7, r8, r9, sl, fp, sp, pc}
  190a08:	0005844c 	andeq	r8, r5, ip, asr #8
			190a08: R_ARM_ABS32	.bss
  190a0c:	f0027000 			@ <UNDEFINED> instruction: 0xf0027000
  190a10:	f0027b0a 			@ <UNDEFINED> instruction: 0xf0027b0a
  190a14:	f0027b08 			@ <UNDEFINED> instruction: 0xf0027b08

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:

work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

00190c0c <_vDrvAmbiLISR>:
  190c0c:	e1a0c00d 	mov	ip, sp
  190c10:	e92dd818 	push	{r3, r4, fp, ip, lr, pc}
  190c14:	e24cb004 	sub	fp, ip, #4
  190c18:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
  190c1c:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			190c1c: R_ARM_CALL	__gnu_mcount_nc
  190c20:	e59f3084 	ldr	r3, [pc, #132]	@ 190cac <_vDrvAmbiLISR+0xa0>
  190c24:	e5d32224 	ldrb	r2, [r3, #548]	@ 0x224
  190c28:	e5d34224 	ldrb	r4, [r3, #548]	@ 0x224
  190c2c:	e1b023a2 	lsrs	r2, r2, #7
  190c30:	e7e04354 	ubfx	r4, r4, #6, #1
  190c34:	0a00000f 	beq	190c78 <_vDrvAmbiLISR+0x6c>
  190c38:	e2433a0d 	sub	r3, r3, #53248	@ 0xd000
  190c3c:	e59f006c 	ldr	r0, [pc, #108]	@ 190cb0 <_vDrvAmbiLISR+0xa4>
  190c40:	e5d32b08 	ldrb	r2, [r3, #2824]	@ 0xb08
  190c44:	e59f3068 	ldr	r3, [pc, #104]	@ 190cb4 <_vDrvAmbiLISR+0xa8>
  190c48:	e2801c0f 	add	r1, r0, #3840	@ 0xf00
  190c4c:	e202201f 	and	r2, r2, #31
  190c50:	e5432cb9 	strb	r2, [r3, #-3257]	@ 0xfffff347
  190c54:	ebfffffe 	bl	190920 <vDrvAmbiLitUpdateLine>
			190c54: R_ARM_CALL	vDrvAmbiLitUpdateLine
  190c58:	e3a01080 	mov	r1, #128	@ 0x80
  190c5c:	e59f0054 	ldr	r0, [pc, #84]	@ 190cb8 <_vDrvAmbiLISR+0xac>
  190c60:	e1a02001 	mov	r2, r1
  190c64:	ebfffffe 	bl	398ab8 <vIO32Write1BMsk>
			190c64: R_ARM_CALL	vIO32Write1BMsk
  190c68:	e59f0048 	ldr	r0, [pc, #72]	@ 190cb8 <_vDrvAmbiLISR+0xac>
  190c6c:	e3a01000 	mov	r1, #0
  190c70:	e3a02080 	mov	r2, #128	@ 0x80
  190c74:	ebfffffe 	bl	398ab8 <vIO32Write1BMsk>
			190c74: R_ARM_CALL	vIO32Write1BMsk
  190c78:	e3540000 	cmp	r4, #0
  190c7c:	0a000007 	beq	190ca0 <_vDrvAmbiLISR+0x94>
  190c80:	e3a01040 	mov	r1, #64	@ 0x40
  190c84:	e59f002c 	ldr	r0, [pc, #44]	@ 190cb8 <_vDrvAmbiLISR+0xac>
  190c88:	e1a02001 	mov	r2, r1
  190c8c:	ebfffffe 	bl	398ab8 <vIO32Write1BMsk>
			190c8c: R_ARM_CALL	vIO32Write1BMsk
  190c90:	e59f0020 	ldr	r0, [pc, #32]	@ 190cb8 <_vDrvAmbiLISR+0xac>
  190c94:	e3a01000 	mov	r1, #0
  190c98:	e3a02040 	mov	r2, #64	@ 0x40
  190c9c:	ebfffffe 	bl	398ab8 <vIO32Write1BMsk>
			190c9c: R_ARM_CALL	vIO32Write1BMsk
  190ca0:	e3a00017 	mov	r0, #23
  190ca4:	ebfffffe 	bl	398cf8 <BIM_ClearIrq>
			190ca4: R_ARM_CALL	BIM_ClearIrq
  190ca8:	e89da818 	ldm	sp, {r3, r4, fp, sp, pc}
  190cac:	f0034000 			@ <UNDEFINED> instruction: 0xf0034000
  190cb0:	00057a28 	andeq	r7, r5, r8, lsr #20
			190cb0: R_ARM_ABS32	.bss
  190cb4:	0005844c 	andeq	r8, r5, ip, asr #8
			190cb4: R_ARM_ABS32	.bss
  190cb8:	f003422e 			@ <UNDEFINED> instruction: 0xf003422e

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:

work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

00190ce8 <vDrvInitAmbiLISR>:
  190ce8:	e1a0c00d 	mov	ip, sp
  190cec:	e92dd818 	push	{r3, r4, fp, ip, lr, pc}
  190cf0:	e24cb004 	sub	fp, ip, #4
  190cf4:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
  190cf8:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			190cf8: R_ARM_CALL	__gnu_mcount_nc
  190cfc:	e59f4028 	ldr	r4, [pc, #40]	@ 190d2c <vDrvInitAmbiLISR+0x44>
  190d00:	e5d4375c 	ldrb	r3, [r4, #1884]	@ 0x75c
  190d04:	e3530000 	cmp	r3, #0
  190d08:	189da818 	ldmne	sp, {r3, r4, fp, sp, pc}
  190d0c:	e59f001c 	ldr	r0, [pc, #28]	@ 190d30 <vDrvInitAmbiLISR+0x48>
  190d10:	e3a0103f 	mov	r1, #63	@ 0x3f
  190d14:	e3a020ff 	mov	r2, #255	@ 0xff
  190d18:	ebfffffe 	bl	398ab8 <vIO32Write1BMsk>
			190d18: R_ARM_CALL	vIO32Write1BMsk
  190d1c:	e3a00001 	mov	r0, #1
  190d20:	e5c4075c 	strb	r0, [r4, #1884]	@ 0x75c
  190d24:	ebfffffe 	bl	190cbc <vDrvAmbiLEnableISR>
			190d24: R_ARM_CALL	vDrvAmbiLEnableISR
  190d28:	e89da818 	ldm	sp, {r3, r4, fp, sp, pc}
  190d2c:	0005844c 	andeq	r8, r5, ip, asr #8
			190d2c: R_ARM_ABS32	.bss
  190d30:	f003422d 			@ <UNDEFINED> instruction: 0xf003422d

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:

work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

00190cbc <vDrvAmbiLEnableISR>:
  190cbc:	e1a0c00d 	mov	ip, sp
  190cc0:	e92dd800 	push	{fp, ip, lr, pc}
  190cc4:	e24cb004 	sub	fp, ip, #4
  190cc8:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
  190ccc:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			190ccc: R_ARM_CALL	__gnu_mcount_nc
  190cd0:	e3a01004 	mov	r1, #4
  190cd4:	e59f0008 	ldr	r0, [pc, #8]	@ 190ce4 <vDrvAmbiLEnableISR+0x28>
  190cd8:	e1a02001 	mov	r2, r1
  190cdc:	ebfffffe 	bl	398ab8 <vIO32Write1BMsk>
			190cdc: R_ARM_CALL	vIO32Write1BMsk
  190ce0:	e89da800 	ldm	sp, {fp, sp, pc}
  190ce4:	f0008035 			@ <UNDEFINED> instruction: 0xf0008035

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:

work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

00190818 <vDrvAmbiLitSysInit>:
  190818:	e1a0c00d 	mov	ip, sp
  19081c:	e92ddbf0 	push	{r4, r5, r6, r7, r8, r9, fp, ip, lr, pc}
  190820:	e24cb004 	sub	fp, ip, #4
  190824:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
  190828:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			190828: R_ARM_CALL	__gnu_mcount_nc
  19082c:	ebfffffe 	bl	e2ba8 <PANEL_GetPanelWidth>
			19082c: R_ARM_CALL	PANEL_GetPanelWidth
  190830:	e1a04000 	mov	r4, r0
  190834:	ebfffffe 	bl	e2bd0 <PANEL_GetPanelHeight>
			190834: R_ARM_CALL	PANEL_GetPanelHeight
  190838:	e3a01014 	mov	r1, #20
  19083c:	e1a07000 	mov	r7, r0
  190840:	ebfffffe 	bl	6561b4 <__udivsi3>
			190840: R_ARM_CALL	__aeabi_uidiv
  190844:	e3a01014 	mov	r1, #20
  190848:	e1a05000 	mov	r5, r0
  19084c:	e1a00007 	mov	r0, r7
  190850:	e1a062a4 	lsr	r6, r4, #5
  190854:	e204901f 	and	r9, r4, #31
  190858:	ebfffffe 	bl	6563a0 <__aeabi_uidivmod>
			190858: R_ARM_CALL	__aeabi_uidivmod
  19085c:	e0818005 	add	r8, r1, r5
  190860:	e3a01001 	mov	r1, #1
  190864:	e1a02001 	mov	r2, r1
  190868:	e59f0094 	ldr	r0, [pc, #148]	@ 190904 <vDrvAmbiLitSysInit+0xec>
  19086c:	ebfffffe 	bl	398ab8 <vIO32Write1BMsk>
			19086c: R_ARM_CALL	vIO32Write1BMsk
  190870:	e3a01000 	mov	r1, #0
  190874:	e3a020f8 	mov	r2, #248	@ 0xf8
  190878:	e59f0084 	ldr	r0, [pc, #132]	@ 190904 <vDrvAmbiLitSysInit+0xec>
  19087c:	e0899006 	add	r9, r9, r6
  190880:	ebfffffe 	bl	398ab8 <vIO32Write1BMsk>
			190880: R_ARM_CALL	vIO32Write1BMsk
  190884:	e3a00000 	mov	r0, #0
  190888:	ebfffffe 	bl	1907ec <vDrvAmbiLitSetMaskMode>
			190888: R_ARM_CALL	vDrvAmbiLitSetMaskMode
  19088c:	e3003438 	movw	r3, #1080	@ 0x438
  190890:	e59f0070 	ldr	r0, [pc, #112]	@ 190908 <vDrvAmbiLitSysInit+0xf0>
  190894:	e1570003 	cmp	r7, r3
  190898:	93540d1e 	cmpls	r4, #1920	@ 0x780
  19089c:	e3a0200f 	mov	r2, #15
  1908a0:	93a01004 	movls	r1, #4
  1908a4:	83a01006 	movhi	r1, #6
  1908a8:	ebfffffe 	bl	398ab8 <vIO32Write1BMsk>
			1908a8: R_ARM_CALL	vIO32Write1BMsk
  1908ac:	e59f0058 	ldr	r0, [pc, #88]	@ 19090c <vDrvAmbiLitSysInit+0xf4>
  1908b0:	e1a01006 	mov	r1, r6
  1908b4:	e3a020ff 	mov	r2, #255	@ 0xff
  1908b8:	ebfffffe 	bl	398ab8 <vIO32Write1BMsk>
			1908b8: R_ARM_CALL	vIO32Write1BMsk
  1908bc:	e59f004c 	ldr	r0, [pc, #76]	@ 190910 <vDrvAmbiLitSysInit+0xf8>
  1908c0:	e1a01005 	mov	r1, r5
  1908c4:	e3a020ff 	mov	r2, #255	@ 0xff
  1908c8:	ebfffffe 	bl	398ab8 <vIO32Write1BMsk>
			1908c8: R_ARM_CALL	vIO32Write1BMsk
  1908cc:	e59f0040 	ldr	r0, [pc, #64]	@ 190914 <vDrvAmbiLitSysInit+0xfc>
  1908d0:	e1a01009 	mov	r1, r9
  1908d4:	e3a020ff 	mov	r2, #255	@ 0xff
  1908d8:	ebfffffe 	bl	398ab8 <vIO32Write1BMsk>
			1908d8: R_ARM_CALL	vIO32Write1BMsk
  1908dc:	e3a020ff 	mov	r2, #255	@ 0xff
  1908e0:	e59f0030 	ldr	r0, [pc, #48]	@ 190918 <vDrvAmbiLitSysInit+0x100>
  1908e4:	e1a01008 	mov	r1, r8
  1908e8:	ebfffffe 	bl	398ab8 <vIO32Write1BMsk>
			1908e8: R_ARM_CALL	vIO32Write1BMsk
  1908ec:	e59f3028 	ldr	r3, [pc, #40]	@ 19091c <vDrvAmbiLitSysInit+0x104>
  1908f0:	e3a02020 	mov	r2, #32
  1908f4:	e5432cbc 	strb	r2, [r3, #-3260]	@ 0xfffff344
  1908f8:	e3a02014 	mov	r2, #20
  1908fc:	e5432cbb 	strb	r2, [r3, #-3259]	@ 0xfffff345
  190900:	e89dabf0 	ldm	sp, {r4, r5, r6, r7, r8, r9, fp, sp, pc}
  190904:	f0027b00 			@ <UNDEFINED> instruction: 0xf0027b00
  190908:	f0027b01 			@ <UNDEFINED> instruction: 0xf0027b01
  19090c:	f0027b04 			@ <UNDEFINED> instruction: 0xf0027b04
  190910:	f0027b05 			@ <UNDEFINED> instruction: 0xf0027b05
  190914:	f0027b06 			@ <UNDEFINED> instruction: 0xf0027b06
  190918:	f0027b07 			@ <UNDEFINED> instruction: 0xf0027b07
  19091c:	0005844c 	andeq	r8, r5, ip, asr #8
			19091c: R_ARM_ABS32	.bss

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:

work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

00190d90 <vDrvAmbiLGetContent>:
  190d90:	e1a0c00d 	mov	ip, sp
  190d94:	e92dd800 	push	{fp, ip, lr, pc}
  190d98:	e24cb004 	sub	fp, ip, #4
  190d9c:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
  190da0:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			190da0: R_ARM_CALL	__gnu_mcount_nc
  190da4:	e3500002 	cmp	r0, #2
  190da8:	e1a03000 	mov	r3, r0
  190dac:	8a000005 	bhi	190dc8 <vDrvAmbiLGetContent+0x38>
  190db0:	e1a00001 	mov	r0, r1
  190db4:	e59f1028 	ldr	r1, [pc, #40]	@ 190de4 <vDrvAmbiLGetContent+0x54>
  190db8:	e3a02c05 	mov	r2, #1280	@ 0x500
  190dbc:	e0211392 	mla	r1, r2, r3, r1
  190dc0:	ebfffffe 	bl	0 <memcpy>
			190dc0: R_ARM_CALL	memcpy
  190dc4:	e89da800 	ldm	sp, {fp, sp, pc}
  190dc8:	e1a02003 	mov	r2, r3
  190dcc:	e59f3014 	ldr	r3, [pc, #20]	@ 190de8 <vDrvAmbiLGetContent+0x58>
  190dd0:	e59f1014 	ldr	r1, [pc, #20]	@ 190dec <vDrvAmbiLGetContent+0x5c>
  190dd4:	e3a00001 	mov	r0, #1
  190dd8:	e5d3375c 	ldrb	r3, [r3, #1884]	@ 0x75c
  190ddc:	ebfffffe 	bl	1e9f00 <NPTV_IsLog>
			190ddc: R_ARM_CALL	NPTV_IsLog
  190de0:	e89da800 	ldm	sp, {fp, sp, pc}
  190de4:	00057a28 	andeq	r7, r5, r8, lsr #20
			190de4: R_ARM_ABS32	.bss
  190de8:	0005844c 	andeq	r8, r5, ip, asr #8
			190de8: R_ARM_ABS32	.bss
  190dec:	000467c0 	andeq	r6, r4, r0, asr #15
			190dec: R_ARM_ABS32	.rodata.str1.1

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:
