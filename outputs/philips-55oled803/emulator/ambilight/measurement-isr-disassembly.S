
work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

001a4160 <_OutputVSyncIsr>:
  1a4160:	e1a0c00d 	mov	ip, sp
  1a4164:	e92dd810 	push	{r4, fp, ip, lr, pc}
  1a4168:	e24cb004 	sub	fp, ip, #4
  1a416c:	e24dd00c 	sub	sp, sp, #12
  1a4170:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
  1a4174:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			1a4174: R_ARM_CALL	__gnu_mcount_nc
  1a4178:	e3500017 	cmp	r0, #23
  1a417c:	1a00001a 	bne	1a41ec <_OutputVSyncIsr+0x8c>
  1a4180:	e59f3074 	ldr	r3, [pc, #116]	@ 1a41fc <_OutputVSyncIsr+0x9c>
  1a4184:	e3a04000 	mov	r4, #0
  1a4188:	e24b0018 	sub	r0, fp, #24
  1a418c:	e5c34008 	strb	r4, [r3, #8]
  1a4190:	ebfffffe 	bl	147628 <vDrvGetTCONIrqStatus>
			1a4190: R_ARM_CALL	vDrvGetTCONIrqStatus
  1a4194:	e51b3018 	ldr	r3, [fp, #-24]	@ 0xffffffe8
  1a4198:	e3130080 	tst	r3, #128	@ 0x80
  1a419c:	0a00000c 	beq	1a41d4 <_OutputVSyncIsr+0x74>
  1a41a0:	ebfffffe 	bl	190a18 <u1DrvAmbiLitGetStrapID>
			1a41a0: R_ARM_CALL	u1DrvAmbiLitGetStrapID
  1a41a4:	e59f1054 	ldr	r1, [pc, #84]	@ 1a4200 <_OutputVSyncIsr+0xa0>
  1a41a8:	e1a02000 	mov	r2, r0
  1a41ac:	e59f0050 	ldr	r0, [pc, #80]	@ 1a4204 <_OutputVSyncIsr+0xa4>
  1a41b0:	ebfffffe 	bl	190920 <vDrvAmbiLitUpdateLine>
			1a41b0: R_ARM_CALL	vDrvAmbiLitUpdateLine
  1a41b4:	e3a01080 	mov	r1, #128	@ 0x80
  1a41b8:	e59f0048 	ldr	r0, [pc, #72]	@ 1a4208 <_OutputVSyncIsr+0xa8>
  1a41bc:	e1a02001 	mov	r2, r1
  1a41c0:	ebfffffe 	bl	398ab8 <vIO32Write1BMsk>
			1a41c0: R_ARM_CALL	vIO32Write1BMsk
  1a41c4:	e59f003c 	ldr	r0, [pc, #60]	@ 1a4208 <_OutputVSyncIsr+0xa8>
  1a41c8:	e1a01004 	mov	r1, r4
  1a41cc:	e3a02080 	mov	r2, #128	@ 0x80
  1a41d0:	ebfffffe 	bl	398ab8 <vIO32Write1BMsk>
			1a41d0: R_ARM_CALL	vIO32Write1BMsk
  1a41d4:	e51b3018 	ldr	r3, [fp, #-24]	@ 0xffffffe8
  1a41d8:	e3130040 	tst	r3, #64	@ 0x40
  1a41dc:	0a000000 	beq	1a41e4 <_OutputVSyncIsr+0x84>
  1a41e0:	ebfffffe 	bl	1a6c58 <vVdoOutISR>
			1a41e0: R_ARM_CALL	vVdoOutISR
  1a41e4:	e51b0018 	ldr	r0, [fp, #-24]	@ 0xffffffe8
  1a41e8:	ebfffffe 	bl	1475e8 <vDrvSetTCONIrqClear>
			1a41e8: R_ARM_CALL	vDrvSetTCONIrqClear
  1a41ec:	e3a00017 	mov	r0, #23
  1a41f0:	ebfffffe 	bl	398cf8 <BIM_ClearIrq>
			1a41f0: R_ARM_CALL	BIM_ClearIrq
  1a41f4:	e24bd010 	sub	sp, fp, #16
  1a41f8:	e89da810 	ldm	sp, {r4, fp, sp, pc}
  1a41fc:	000594dc 	ldrdeq	r9, [r5], -ip
			1a41fc: R_ARM_ABS32	.bss
	...
			1a4200: R_ARM_ABS32	u1AmbiLitBLKArray
			1a4204: R_ARM_ABS32	u2AmbiLitArray
  1a4208:	f003422e 			@ <UNDEFINED> instruction: 0xf003422e

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:


work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

001a4334 <VdoMLInit>:
  1a4334:	e1a0c00d 	mov	ip, sp
  1a4338:	e92dd870 	push	{r4, r5, r6, fp, ip, lr, pc}
  1a433c:	e24cb004 	sub	fp, ip, #4
  1a4340:	e24dd01c 	sub	sp, sp, #28
  1a4344:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
  1a4348:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			1a4348: R_ARM_CALL	__gnu_mcount_nc
  1a434c:	e59f5170 	ldr	r5, [pc, #368]	@ 1a44c4 <VdoMLInit+0x190>
  1a4350:	e3a03000 	mov	r3, #0
  1a4354:	e50b3020 	str	r3, [fp, #-32]	@ 0xffffffe0
  1a4358:	e5953014 	ldr	r3, [r5, #20]
  1a435c:	e3530000 	cmp	r3, #0
  1a4360:	1a000003 	bne	1a4374 <VdoMLInit+0x40>
  1a4364:	e24b0020 	sub	r0, fp, #32
  1a4368:	e3a01002 	mov	r1, #2
  1a436c:	e3a02001 	mov	r2, #1
  1a4370:	ebfffffe 	bl	32c5f8 <x_sema_create>
			1a4370: R_ARM_CALL	x_sema_create
  1a4374:	ebfffffe 	bl	399298 <HalCriticalStart>
			1a4374: R_ARM_CALL	HalCriticalStart
  1a4378:	e5953014 	ldr	r3, [r5, #20]
  1a437c:	e3530000 	cmp	r3, #0
  1a4380:	0a000005 	beq	1a439c <VdoMLInit+0x68>
  1a4384:	ebfffffe 	bl	399324 <HalCriticalEnd>
			1a4384: R_ARM_CALL	HalCriticalEnd
  1a4388:	e51b0020 	ldr	r0, [fp, #-32]	@ 0xffffffe0
  1a438c:	e3500000 	cmp	r0, #0
  1a4390:	0a000005 	beq	1a43ac <VdoMLInit+0x78>
  1a4394:	ebfffffe 	bl	32c6c0 <x_sema_delete>
			1a4394: R_ARM_CALL	x_sema_delete
  1a4398:	ea000003 	b	1a43ac <VdoMLInit+0x78>
  1a439c:	e51b2020 	ldr	r2, [fp, #-32]	@ 0xffffffe0
  1a43a0:	e59f311c 	ldr	r3, [pc, #284]	@ 1a44c4 <VdoMLInit+0x190>
  1a43a4:	e5832014 	str	r2, [r3, #20]
  1a43a8:	ebfffffe 	bl	399324 <HalCriticalEnd>
			1a43a8: R_ARM_CALL	HalCriticalEnd
  1a43ac:	e5950014 	ldr	r0, [r5, #20]
  1a43b0:	e3a01001 	mov	r1, #1
  1a43b4:	ebfffffe 	bl	32c6e0 <x_sema_lock>
			1a43b4: R_ARM_CALL	x_sema_lock
  1a43b8:	e5d56018 	ldrb	r6, [r5, #24]
  1a43bc:	e59f4100 	ldr	r4, [pc, #256]	@ 1a44c4 <VdoMLInit+0x190>
  1a43c0:	e3560000 	cmp	r6, #0
  1a43c4:	0a000003 	beq	1a43d8 <VdoMLInit+0xa4>
  1a43c8:	e5940014 	ldr	r0, [r4, #20]
  1a43cc:	ebfffffe 	bl	32c894 <x_sema_unlock>
			1a43cc: R_ARM_CALL	x_sema_unlock
  1a43d0:	e5d40018 	ldrb	r0, [r4, #24]
  1a43d4:	ea000038 	b	1a44bc <VdoMLInit+0x188>
  1a43d8:	ebfffffe 	bl	1a423c <vAllocateSWReg>
			1a43d8: R_ARM_CALL	vAllocateSWReg
  1a43dc:	ebfffffe 	bl	57e388 <VDP_XdataInit>
			1a43dc: R_ARM_CALL	VDP_XdataInit
  1a43e0:	e3a01001 	mov	r1, #1
  1a43e4:	e1a02006 	mov	r2, r6
  1a43e8:	e1a00004 	mov	r0, r4
  1a43ec:	ebfffffe 	bl	32c5f8 <x_sema_create>
			1a43ec: R_ARM_CALL	x_sema_create
  1a43f0:	e2840004 	add	r0, r4, #4
  1a43f4:	e3a01002 	mov	r1, #2
  1a43f8:	e3a02001 	mov	r2, #1
  1a43fc:	ebfffffe 	bl	32c5f8 <x_sema_create>
			1a43fc: R_ARM_CALL	x_sema_create
  1a4400:	e5d43019 	ldrb	r3, [r4, #25]
  1a4404:	e3530000 	cmp	r3, #0
  1a4408:	1a00000c 	bne	1a4440 <VdoMLInit+0x10c>
  1a440c:	e3a00014 	mov	r0, #20
  1a4410:	e59f10b0 	ldr	r1, [pc, #176]	@ 1a44c8 <VdoMLInit+0x194>
  1a4414:	e284201c 	add	r2, r4, #28
  1a4418:	ebfffffe 	bl	32c500 <x_os_drv_reg_isr_ex>
			1a4418: R_ARM_CALL	x_os_drv_reg_isr_ex
  1a441c:	e3500000 	cmp	r0, #0
  1a4420:	1a000006 	bne	1a4440 <VdoMLInit+0x10c>
  1a4424:	e3a00017 	mov	r0, #23
  1a4428:	e59f109c 	ldr	r1, [pc, #156]	@ 1a44cc <VdoMLInit+0x198>
  1a442c:	e2842020 	add	r2, r4, #32
  1a4430:	ebfffffe 	bl	32c500 <x_os_drv_reg_isr_ex>
			1a4430: R_ARM_CALL	x_os_drv_reg_isr_ex
  1a4434:	e3500000 	cmp	r0, #0
  1a4438:	03a03001 	moveq	r3, #1
  1a443c:	05c43019 	strbeq	r3, [r4, #25]
  1a4440:	e5d56019 	ldrb	r6, [r5, #25]
  1a4444:	e59f4078 	ldr	r4, [pc, #120]	@ 1a44c4 <VdoMLInit+0x190>
  1a4448:	e3560000 	cmp	r6, #0
  1a444c:	1a000003 	bne	1a4460 <VdoMLInit+0x12c>
  1a4450:	e5940014 	ldr	r0, [r4, #20]
  1a4454:	ebfffffe 	bl	32c894 <x_sema_unlock>
			1a4454: R_ARM_CALL	x_sema_unlock
  1a4458:	e1a00006 	mov	r0, r6
  1a445c:	ea000016 	b	1a44bc <VdoMLInit+0x188>
  1a4460:	ebfffffe 	bl	10974c <vApiHwInit>
			1a4460: R_ARM_CALL	vApiHwInit
  1a4464:	ebfffffe 	bl	db17c <DRVCUST_HwInit>
			1a4464: R_ARM_CALL	DRVCUST_HwInit
  1a4468:	ebfffffe 	bl	109718 <vApiVideoInit>
			1a4468: R_ARM_CALL	vApiVideoInit
  1a446c:	ebfffffe 	bl	dbec4 <DRVCUST_VideoInit>
			1a446c: R_ARM_CALL	DRVCUST_VideoInit
  1a4470:	ebfffffe 	bl	41adc0 <vDrvCvbsVfePD>
			1a4470: R_ARM_CALL	vDrvCvbsVfePD
  1a4474:	e3a00000 	mov	r0, #0
  1a4478:	ebfffffe 	bl	41c284 <vDrvAllHDADCPow>
			1a4478: R_ARM_CALL	vDrvAllHDADCPow
  1a447c:	e59f304c 	ldr	r3, [pc, #76]	@ 1a44d0 <VdoMLInit+0x19c>
  1a4480:	e3a02b02 	mov	r2, #2048	@ 0x800
  1a4484:	e59f1048 	ldr	r1, [pc, #72]	@ 1a44d4 <VdoMLInit+0x1a0>
  1a4488:	e24b0024 	sub	r0, fp, #36	@ 0x24
  1a448c:	e58d3000 	str	r3, [sp]
  1a4490:	e3a03000 	mov	r3, #0
  1a4494:	e58d3004 	str	r3, [sp, #4]
  1a4498:	e58d3008 	str	r3, [sp, #8]
  1a449c:	e3a0303c 	mov	r3, #60	@ 0x3c
  1a44a0:	ebfffffe 	bl	32cb20 <x_thread_create>
			1a44a0: R_ARM_CALL	x_thread_create
  1a44a4:	e3500000 	cmp	r0, #0
  1a44a8:	e5950014 	ldr	r0, [r5, #20]
  1a44ac:	03a03001 	moveq	r3, #1
  1a44b0:	05c43018 	strbeq	r3, [r4, #24]
  1a44b4:	ebfffffe 	bl	32c894 <x_sema_unlock>
			1a44b4: R_ARM_CALL	x_sema_unlock
  1a44b8:	e5d50018 	ldrb	r0, [r5, #24]
  1a44bc:	e24bd018 	sub	sp, fp, #24
  1a44c0:	e89da870 	ldm	sp, {r4, r5, r6, fp, sp, pc}
  1a44c4:	000594dc 	ldrdeq	r9, [r5], -ip
			1a44c4: R_ARM_ABS32	.bss
	...
			1a44c8: R_ARM_ABS32	_VSyncIsr
			1a44cc: R_ARM_ABS32	_OutputVSyncIsr
			1a44d0: R_ARM_ABS32	NptvMainLoop
  1a44d4:	000483a8 	andeq	r8, r4, r8, lsr #7
			1a44d4: R_ARM_ABS32	.rodata.str1.1

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

00147628 <vDrvGetTCONIrqStatus>:
  147628:	e1a0c00d 	mov	ip, sp
  14762c:	e92dd800 	push	{fp, ip, lr, pc}
  147630:	e24cb004 	sub	fp, ip, #4
  147634:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
  147638:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			147638: R_ARM_CALL	__gnu_mcount_nc
  14763c:	e59f3008 	ldr	r3, [pc, #8]	@ 14764c <vDrvGetTCONIrqStatus+0x24>
  147640:	e5d33224 	ldrb	r3, [r3, #548]	@ 0x224
  147644:	e5803000 	str	r3, [r0]
  147648:	e89da800 	ldm	sp, {fp, sp, pc}
  14764c:	f0034000 			@ <UNDEFINED> instruction: 0xf0034000

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:


work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

001475e8 <vDrvSetTCONIrqClear>:
  1475e8:	e1a0c00d 	mov	ip, sp
  1475ec:	e92dd818 	push	{r3, r4, fp, ip, lr, pc}
  1475f0:	e24cb004 	sub	fp, ip, #4
  1475f4:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
  1475f8:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			1475f8: R_ARM_CALL	__gnu_mcount_nc
  1475fc:	e3a020ff 	mov	r2, #255	@ 0xff
  147600:	e1a01000 	mov	r1, r0
  147604:	e59f4018 	ldr	r4, [pc, #24]	@ 147624 <vDrvSetTCONIrqClear+0x3c>
  147608:	e1a00004 	mov	r0, r4
  14760c:	ebfffffe 	bl	398ab8 <vIO32Write1BMsk>
			14760c: R_ARM_CALL	vIO32Write1BMsk
  147610:	e1a00004 	mov	r0, r4
  147614:	e3a01000 	mov	r1, #0
  147618:	e3a020ff 	mov	r2, #255	@ 0xff
  14761c:	ebfffffe 	bl	398ab8 <vIO32Write1BMsk>
			14761c: R_ARM_CALL	vIO32Write1BMsk
  147620:	e89da818 	ldm	sp, {r3, r4, fp, sp, pc}
  147624:	f003422e 			@ <UNDEFINED> instruction: 0xf003422e

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:


work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

00398b84 <BIM_EnableIrq>:
  398b84:	e1a0c00d 	mov	ip, sp
  398b88:	e92dd818 	push	{r3, r4, fp, ip, lr, pc}
  398b8c:	e24cb004 	sub	fp, ip, #4
  398b90:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
  398b94:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			398b94: R_ARM_CALL	__gnu_mcount_nc
  398b98:	e35000a7 	cmp	r0, #167	@ 0xa7
  398b9c:	8a00000a 	bhi	398bcc <BIM_EnableIrq+0x48>
  398ba0:	e59f302c 	ldr	r3, [pc, #44]	@ 398bd4 <BIM_EnableIrq+0x50>
  398ba4:	e1a022a0 	lsr	r2, r0, #5
  398ba8:	e200c01f 	and	ip, r0, #31
  398bac:	e3a04001 	mov	r4, #1
  398bb0:	e2800068 	add	r0, r0, #104	@ 0x68
  398bb4:	e7931102 	ldr	r1, [r3, r2, lsl #2]
  398bb8:	e1811c14 	orr	r1, r1, r4, lsl ip
  398bbc:	e7831102 	str	r1, [r3, r2, lsl #2]
  398bc0:	ebfffffe 	bl	0 <enable_irq>
			398bc0: R_ARM_CALL	enable_irq
  398bc4:	e1a00004 	mov	r0, r4
  398bc8:	e89da818 	ldm	sp, {r3, r4, fp, sp, pc}
  398bcc:	e3a00000 	mov	r0, #0
  398bd0:	e89da818 	ldm	sp, {r3, r4, fp, sp, pc}
  398bd4:	00075250 	andeq	r5, r7, r0, asr r2
			398bd4: R_ARM_ABS32	.bss

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:
