
work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

00596228 <amb_writeColorGrid>:
  596228:	e3500000 	cmp	r0, #0
  59622c:	13510000 	cmpne	r1, #0
  596230:	e92d40f0 	push	{r4, r5, r6, r7, lr}
  596234:	e59d6018 	ldr	r6, [sp, #24]
  596238:	e1dd41b4 	ldrh	r4, [sp, #20]
  59623c:	0a00002c 	beq	5962f4 <amb_writeColorGrid+0xcc>
  596240:	e3520000 	cmp	r2, #0
  596244:	13530000 	cmpne	r3, #0
  596248:	0a000029 	beq	5962f4 <amb_writeColorGrid+0xcc>
  59624c:	e3540d0a 	cmp	r4, #640	@ 0x280
  596250:	8a000029 	bhi	5962fc <amb_writeColorGrid+0xd4>
  596254:	e590c01c 	ldr	ip, [r0, #28]
  596258:	e35c0009 	cmp	ip, #9
  59625c:	13a0e000 	movne	lr, #0
  596260:	11a0c00e 	movne	ip, lr
  596264:	0a000024 	beq	5962fc <amb_writeColorGrid+0xd4>
  596268:	e15c0004 	cmp	ip, r4
  59626c:	2a00001e 	bcs	5962ec <amb_writeColorGrid+0xc4>
  596270:	e3560001 	cmp	r6, #1
  596274:	e5905014 	ldr	r5, [r0, #20]
  596278:	1a00000d 	bne	5962b4 <amb_writeColorGrid+0x8c>
  59627c:	e19170be 	ldrh	r7, [r1, lr]
  596280:	e085500c 	add	r5, r5, ip
  596284:	e1a07427 	lsr	r7, r7, #8
  596288:	e5c57a24 	strb	r7, [r5, #2596]	@ 0xa24
  59628c:	e19270be 	ldrh	r7, [r2, lr]
  596290:	e5905014 	ldr	r5, [r0, #20]
  596294:	e1a07427 	lsr	r7, r7, #8
  596298:	e085500c 	add	r5, r5, ip
  59629c:	e5c57ca4 	strb	r7, [r5, #3236]	@ 0xca4
  5962a0:	e19370be 	ldrh	r7, [r3, lr]
  5962a4:	e5905014 	ldr	r5, [r0, #20]
  5962a8:	e1a07427 	lsr	r7, r7, #8
  5962ac:	e085500c 	add	r5, r5, ip
  5962b0:	ea000009 	b	5962dc <amb_writeColorGrid+0xb4>
  5962b4:	e7d1700c 	ldrb	r7, [r1, ip]
  5962b8:	e085500c 	add	r5, r5, ip
  5962bc:	e5c57a24 	strb	r7, [r5, #2596]	@ 0xa24
  5962c0:	e5905014 	ldr	r5, [r0, #20]
  5962c4:	e7d2700c 	ldrb	r7, [r2, ip]
  5962c8:	e085500c 	add	r5, r5, ip
  5962cc:	e5c57ca4 	strb	r7, [r5, #3236]	@ 0xca4
  5962d0:	e5905014 	ldr	r5, [r0, #20]
  5962d4:	e7d3700c 	ldrb	r7, [r3, ip]
  5962d8:	e085500c 	add	r5, r5, ip
  5962dc:	e5c57f24 	strb	r7, [r5, #3876]	@ 0xf24
  5962e0:	e28cc001 	add	ip, ip, #1
  5962e4:	e28ee002 	add	lr, lr, #2
  5962e8:	eaffffde 	b	596268 <amb_writeColorGrid+0x40>
  5962ec:	e3a00000 	mov	r0, #0
  5962f0:	e8bd80f0 	pop	{r4, r5, r6, r7, pc}
  5962f4:	e3a00002 	mov	r0, #2
  5962f8:	e8bd80f0 	pop	{r4, r5, r6, r7, pc}
  5962fc:	e3a00003 	mov	r0, #3
  596300:	e8bd80f0 	pop	{r4, r5, r6, r7, pc}

00596304 <amb_writeExternalGrid>:
  596304:	e3500000 	cmp	r0, #0
  596308:	13510000 	cmpne	r1, #0
  59630c:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
  596310:	0a000015 	beq	59636c <amb_writeExternalGrid+0x68>
  596314:	e3520d0a 	cmp	r2, #640	@ 0x280
  596318:	93a03000 	movls	r3, #0
  59631c:	8a000014 	bhi	596374 <amb_writeExternalGrid+0x70>
  596320:	e1530002 	cmp	r3, r2
  596324:	2a00000e 	bcs	596364 <amb_writeExternalGrid+0x60>
  596328:	e590c014 	ldr	ip, [r0, #20]
  59632c:	e591e000 	ldr	lr, [r1]
  596330:	e08cc003 	add	ip, ip, r3
  596334:	e5ccea24 	strb	lr, [ip, #2596]	@ 0xa24
  596338:	e491e004 	ldr	lr, [r1], #4
  59633c:	e590c014 	ldr	ip, [r0, #20]
  596340:	e7e7e45e 	ubfx	lr, lr, #8, #8
  596344:	e08cc003 	add	ip, ip, r3
  596348:	e5cceca4 	strb	lr, [ip, #3236]	@ 0xca4
  59634c:	e590c014 	ldr	ip, [r0, #20]
  596350:	e551e002 	ldrb	lr, [r1, #-2]
  596354:	e08cc003 	add	ip, ip, r3
  596358:	e2833001 	add	r3, r3, #1
  59635c:	e5ccef24 	strb	lr, [ip, #3876]	@ 0xf24
  596360:	eaffffee 	b	596320 <amb_writeExternalGrid+0x1c>
  596364:	e3a00000 	mov	r0, #0
  596368:	e49df004 	pop	{pc}		@ (ldr pc, [sp], #4)
  59636c:	e3a00002 	mov	r0, #2
  596370:	e49df004 	pop	{pc}		@ (ldr pc, [sp], #4)
  596374:	e3a00003 	mov	r0, #3
  596378:	e49df004 	pop	{pc}		@ (ldr pc, [sp], #4)

0059637c <amb_getRedColorGridNovatek>:
  59637c:	e59f300c 	ldr	r3, [pc, #12]	@ 596390 <amb_getRedColorGridNovatek+0x14>
  596380:	e3500000 	cmp	r0, #0
  596384:	03a00000 	moveq	r0, #0
  596388:	11a00003 	movne	r0, r3
  59638c:	e12fff1e 	bx	lr
  596390:	000bec00 	andeq	lr, fp, r0, lsl #24
			596390: R_ARM_ABS32	.bss

00596394 <amb_getGreenColorGridNovatek>:
  596394:	e59f300c 	ldr	r3, [pc, #12]	@ 5963a8 <amb_getGreenColorGridNovatek+0x14>
  596398:	e3500000 	cmp	r0, #0
  59639c:	03a00000 	moveq	r0, #0
  5963a0:	11a00003 	movne	r0, r3
  5963a4:	e12fff1e 	bx	lr
  5963a8:	000bee80 	andeq	lr, fp, r0, lsl #29
			5963a8: R_ARM_ABS32	.bss

005963ac <amb_getBlueColorGridNovatek>:
  5963ac:	e59f300c 	ldr	r3, [pc, #12]	@ 5963c0 <amb_getBlueColorGridNovatek+0x14>
  5963b0:	e3500000 	cmp	r0, #0
  5963b4:	03a00000 	moveq	r0, #0
  5963b8:	11a00003 	movne	r0, r3
  5963bc:	e12fff1e 	bx	lr
  5963c0:	000bf100 	andeq	pc, fp, r0, lsl #2
			5963c0: R_ARM_ABS32	.bss
