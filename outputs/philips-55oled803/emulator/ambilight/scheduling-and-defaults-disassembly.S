
work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

00597f34 <amb_setAlignments>:
  597f34:	e1a0c00d 	mov	ip, sp
  597f38:	e24dd008 	sub	sp, sp, #8
  597f3c:	e92ddff0 	push	{r4, r5, r6, r7, r8, r9, sl, fp, ip, lr, pc}
  597f40:	e24cb00c 	sub	fp, ip, #12
  597f44:	e24dd014 	sub	sp, sp, #20
  597f48:	e3500000 	cmp	r0, #0
  597f4c:	e5db900c 	ldrb	r9, [fp, #12]
  597f50:	e98b000c 	stmib	fp, {r2, r3}
  597f54:	e5db300b 	ldrb	r3, [fp, #11]
  597f58:	e5db2010 	ldrb	r2, [fp, #16]
  597f5c:	e5db8004 	ldrb	r8, [fp, #4]
  597f60:	e5db7005 	ldrb	r7, [fp, #5]
  597f64:	e5db6006 	ldrb	r6, [fp, #6]
  597f68:	e5db5007 	ldrb	r5, [fp, #7]
  597f6c:	e5db4008 	ldrb	r4, [fp, #8]
  597f70:	e5dbe009 	ldrb	lr, [fp, #9]
  597f74:	e5dbc00a 	ldrb	ip, [fp, #10]
  597f78:	e50b3034 	str	r3, [fp, #-52]	@ 0xffffffcc
  597f7c:	e50b9030 	str	r9, [fp, #-48]	@ 0xffffffd0
  597f80:	0a000079 	beq	59816c <amb_setAlignments+0x238>
  597f84:	e5909004 	ldr	r9, [r0, #4]
  597f88:	e3590000 	cmp	r9, #0
  597f8c:	0a000076 	beq	59816c <amb_setAlignments+0x238>
  597f90:	e3580000 	cmp	r8, #0
  597f94:	1a000021 	bne	598020 <amb_setAlignments+0xec>
  597f98:	e3570000 	cmp	r7, #0
  597f9c:	1a00001f 	bne	598020 <amb_setAlignments+0xec>
  597fa0:	e3560000 	cmp	r6, #0
  597fa4:	1a00001d 	bne	598020 <amb_setAlignments+0xec>
  597fa8:	e3550000 	cmp	r5, #0
  597fac:	1a00001b 	bne	598020 <amb_setAlignments+0xec>
  597fb0:	e3540000 	cmp	r4, #0
  597fb4:	1a000019 	bne	598020 <amb_setAlignments+0xec>
  597fb8:	e35e0000 	cmp	lr, #0
  597fbc:	1a000017 	bne	598020 <amb_setAlignments+0xec>
  597fc0:	e35c0000 	cmp	ip, #0
  597fc4:	1a000015 	bne	598020 <amb_setAlignments+0xec>
  597fc8:	e3530000 	cmp	r3, #0
  597fcc:	1a000013 	bne	598020 <amb_setAlignments+0xec>
  597fd0:	e51ba030 	ldr	sl, [fp, #-48]	@ 0xffffffd0
  597fd4:	e35a0000 	cmp	sl, #0
  597fd8:	1a000010 	bne	598020 <amb_setAlignments+0xec>
  597fdc:	e599c004 	ldr	ip, [r9, #4]
  597fe0:	e3520000 	cmp	r2, #0
  597fe4:	e59fe18c 	ldr	lr, [pc, #396]	@ 598178 <amb_setAlignments+0x244>
  597fe8:	03a020c8 	moveq	r2, #200	@ 0xc8
  597fec:	e08cc18c 	add	ip, ip, ip, lsl #3
  597ff0:	e08e300c 	add	r3, lr, ip
  597ff4:	e7de800c 	ldrb	r8, [lr, ip]
  597ff8:	e5d3a007 	ldrb	sl, [r3, #7]
  597ffc:	e5d37001 	ldrb	r7, [r3, #1]
  598000:	e5d36002 	ldrb	r6, [r3, #2]
  598004:	e5d35003 	ldrb	r5, [r3, #3]
  598008:	e5d34004 	ldrb	r4, [r3, #4]
  59800c:	e5d3e005 	ldrb	lr, [r3, #5]
  598010:	e5d3c006 	ldrb	ip, [r3, #6]
  598014:	e5d33008 	ldrb	r3, [r3, #8]
  598018:	e50ba034 	str	sl, [fp, #-52]	@ 0xffffffcc
  59801c:	e50b3030 	str	r3, [fp, #-48]	@ 0xffffffd0
  598020:	e3510000 	cmp	r1, #0
  598024:	1a000027 	bne	5980c8 <amb_setAlignments+0x194>
  598028:	e3a0a00a 	mov	sl, #10
  59802c:	e5909004 	ldr	r9, [r0, #4]
  598030:	e003019a 	mul	r3, sl, r1
  598034:	e0899003 	add	r9, r9, r3
  598038:	e5c98009 	strb	r8, [r9, #9]
  59803c:	e5909004 	ldr	r9, [r0, #4]
  598040:	e0899003 	add	r9, r9, r3
  598044:	e5c9700a 	strb	r7, [r9, #10]
  598048:	e2819001 	add	r9, r1, #1
  59804c:	e590a004 	ldr	sl, [r0, #4]
  598050:	e3a0100a 	mov	r1, #10
  598054:	e359000c 	cmp	r9, #12
  598058:	e02aa991 	mla	sl, r1, r9, sl
  59805c:	e5ca6001 	strb	r6, [sl, #1]
  598060:	e5901004 	ldr	r1, [r0, #4]
  598064:	e51ba034 	ldr	sl, [fp, #-52]	@ 0xffffffcc
  598068:	e0811003 	add	r1, r1, r3
  59806c:	e5c1500c 	strb	r5, [r1, #12]
  598070:	e5901004 	ldr	r1, [r0, #4]
  598074:	e0811003 	add	r1, r1, r3
  598078:	e5c1400d 	strb	r4, [r1, #13]
  59807c:	e5901004 	ldr	r1, [r0, #4]
  598080:	e0811003 	add	r1, r1, r3
  598084:	e5c1e00e 	strb	lr, [r1, #14]
  598088:	e5901004 	ldr	r1, [r0, #4]
  59808c:	e0811003 	add	r1, r1, r3
  598090:	e5c1c00f 	strb	ip, [r1, #15]
  598094:	e5901004 	ldr	r1, [r0, #4]
  598098:	e0811003 	add	r1, r1, r3
  59809c:	e5c1a010 	strb	sl, [r1, #16]
  5980a0:	e5901004 	ldr	r1, [r0, #4]
  5980a4:	e51ba030 	ldr	sl, [fp, #-48]	@ 0xffffffd0
  5980a8:	e0811003 	add	r1, r1, r3
  5980ac:	e5c1a011 	strb	sl, [r1, #17]
  5980b0:	e5901004 	ldr	r1, [r0, #4]
  5980b4:	e0813003 	add	r3, r1, r3
  5980b8:	e1a01009 	mov	r1, r9
  5980bc:	e5c32008 	strb	r2, [r3, #8]
  5980c0:	1affffd8 	bne	598028 <amb_setAlignments+0xf4>
  5980c4:	ea000024 	b	59815c <amb_setAlignments+0x228>
  5980c8:	e351000c 	cmp	r1, #12
  5980cc:	83a00003 	movhi	r0, #3
  5980d0:	8a000026 	bhi	598170 <amb_setAlignments+0x23c>
  5980d4:	e2413001 	sub	r3, r1, #1
  5980d8:	e3a0a00a 	mov	sl, #10
  5980dc:	e003039a 	mul	r3, sl, r3
  5980e0:	e0899003 	add	r9, r9, r3
  5980e4:	e5c98009 	strb	r8, [r9, #9]
  5980e8:	e5908004 	ldr	r8, [r0, #4]
  5980ec:	e51b9030 	ldr	r9, [fp, #-48]	@ 0xffffffd0
  5980f0:	e0888003 	add	r8, r8, r3
  5980f4:	e5c8700a 	strb	r7, [r8, #10]
  5980f8:	e5907004 	ldr	r7, [r0, #4]
  5980fc:	e021719a 	mla	r1, sl, r1, r7
  598100:	e5c16001 	strb	r6, [r1, #1]
  598104:	e5901004 	ldr	r1, [r0, #4]
  598108:	e0811003 	add	r1, r1, r3
  59810c:	e5c1500c 	strb	r5, [r1, #12]
  598110:	e5901004 	ldr	r1, [r0, #4]
  598114:	e0811003 	add	r1, r1, r3
  598118:	e5c1400d 	strb	r4, [r1, #13]
  59811c:	e5901004 	ldr	r1, [r0, #4]
  598120:	e0811003 	add	r1, r1, r3
  598124:	e5c1e00e 	strb	lr, [r1, #14]
  598128:	e5901004 	ldr	r1, [r0, #4]
  59812c:	e0811003 	add	r1, r1, r3
  598130:	e5c1c00f 	strb	ip, [r1, #15]
  598134:	e5901004 	ldr	r1, [r0, #4]
  598138:	e51bc034 	ldr	ip, [fp, #-52]	@ 0xffffffcc
  59813c:	e0811003 	add	r1, r1, r3
  598140:	e5c1c010 	strb	ip, [r1, #16]
  598144:	e5901004 	ldr	r1, [r0, #4]
  598148:	e0811003 	add	r1, r1, r3
  59814c:	e5c19011 	strb	r9, [r1, #17]
  598150:	e5901004 	ldr	r1, [r0, #4]
  598154:	e0813003 	add	r3, r1, r3
  598158:	e5c32008 	strb	r2, [r3, #8]
  59815c:	e5900004 	ldr	r0, [r0, #4]
  598160:	ebfff743 	bl	595e74 <amb_algo_applySunriseMode+0x88>
  598164:	e3a00000 	mov	r0, #0
  598168:	ea000000 	b	598170 <amb_setAlignments+0x23c>
  59816c:	e3a00002 	mov	r0, #2
  598170:	e24bd028 	sub	sp, fp, #40	@ 0x28
  598174:	e89daff0 	ldm	sp, {r4, r5, r6, r7, r8, r9, sl, fp, sp, pc}
  598178:	00084798 	muleq	r8, r8, r7
			598178: R_ARM_ABS32	.rodata

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:


work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

005a3538 <IMamb_Fms_SetAlignments>:
  5a3538:	e1a0c00d 	mov	ip, sp
  5a353c:	e3a02009 	mov	r2, #9
  5a3540:	e92dd830 	push	{r4, r5, fp, ip, lr, pc}
  5a3544:	e24cb004 	sub	fp, ip, #4
  5a3548:	e24dd018 	sub	sp, sp, #24
  5a354c:	e1a04001 	mov	r4, r1
  5a3550:	e1a05000 	mov	r5, r0
  5a3554:	e3a01000 	mov	r1, #0
  5a3558:	e24b001d 	sub	r0, fp, #29
  5a355c:	ebfffffe 	bl	0 <memset>
			5a355c: R_ARM_CALL	memset
  5a3560:	e5d43001 	ldrb	r3, [r4, #1]
  5a3564:	e54b301d 	strb	r3, [fp, #-29]	@ 0xffffffe3
  5a3568:	e5d43002 	ldrb	r3, [r4, #2]
  5a356c:	e54b301c 	strb	r3, [fp, #-28]	@ 0xffffffe4
  5a3570:	e5d43003 	ldrb	r3, [r4, #3]
  5a3574:	e54b301b 	strb	r3, [fp, #-27]	@ 0xffffffe5
  5a3578:	e5d43004 	ldrb	r3, [r4, #4]
  5a357c:	e54b301a 	strb	r3, [fp, #-26]	@ 0xffffffe6
  5a3580:	e5d43005 	ldrb	r3, [r4, #5]
  5a3584:	e54b3019 	strb	r3, [fp, #-25]	@ 0xffffffe7
  5a3588:	e5d43006 	ldrb	r3, [r4, #6]
  5a358c:	e54b3018 	strb	r3, [fp, #-24]	@ 0xffffffe8
  5a3590:	e5d43007 	ldrb	r3, [r4, #7]
  5a3594:	e54b3017 	strb	r3, [fp, #-23]	@ 0xffffffe9
  5a3598:	e5d43008 	ldrb	r3, [r4, #8]
  5a359c:	e54b3016 	strb	r3, [fp, #-22]	@ 0xffffffea
  5a35a0:	e5d43009 	ldrb	r3, [r4, #9]
  5a35a4:	e54b3015 	strb	r3, [fp, #-21]	@ 0xffffffeb
  5a35a8:	e59f3038 	ldr	r3, [pc, #56]	@ 5a35e8 <IMamb_Fms_SetAlignments+0xb0>
  5a35ac:	e5930000 	ldr	r0, [r3]
  5a35b0:	e3500000 	cmp	r0, #0
  5a35b4:	03a00001 	moveq	r0, #1
  5a35b8:	0a000008 	beq	5a35e0 <IMamb_Fms_SetAlignments+0xa8>
  5a35bc:	e5d43000 	ldrb	r3, [r4]
  5a35c0:	e55b1015 	ldrb	r1, [fp, #-21]	@ 0xffffffeb
  5a35c4:	e51b201d 	ldr	r2, [fp, #-29]	@ 0xffffffe3
  5a35c8:	e58d3004 	str	r3, [sp, #4]
  5a35cc:	e5cd1000 	strb	r1, [sp]
  5a35d0:	e1a01005 	mov	r1, r5
  5a35d4:	e51b3019 	ldr	r3, [fp, #-25]	@ 0xffffffe7
  5a35d8:	ebfffffe 	bl	597f34 <amb_setAlignments>
			5a35d8: R_ARM_CALL	amb_setAlignments
  5a35dc:	e3a00000 	mov	r0, #0
  5a35e0:	e24bd014 	sub	sp, fp, #20
  5a35e4:	e89da830 	ldm	sp, {r4, r5, fp, sp, pc}
  5a35e8:	000c4e88 	andeq	r4, ip, r8, lsl #29
			5a35e8: R_ARM_ABS32	.bss

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:


work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

0059e74c <IMamb_Eng_SetArchitecture>:
  59e74c:	e1a0c00d 	mov	ip, sp
  59e750:	e59f10c0 	ldr	r1, [pc, #192]	@ 59e818 <IMamb_Eng_SetArchitecture+0xcc>
  59e754:	e92dd830 	push	{r4, r5, fp, ip, lr, pc}
  59e758:	e24cb004 	sub	fp, ip, #4
  59e75c:	e24dd010 	sub	sp, sp, #16
  59e760:	e1a04000 	mov	r4, r0
  59e764:	e5d02001 	ldrb	r2, [r0, #1]
  59e768:	e5d03000 	ldrb	r3, [r0]
  59e76c:	e59f50a8 	ldr	r5, [pc, #168]	@ 59e81c <IMamb_Eng_SetArchitecture+0xd0>
  59e770:	e58d2000 	str	r2, [sp]
  59e774:	e5d02002 	ldrb	r2, [r0, #2]
  59e778:	e58d2004 	str	r2, [sp, #4]
  59e77c:	e5d02003 	ldrb	r2, [r0, #3]
  59e780:	e58d2008 	str	r2, [sp, #8]
  59e784:	e1d020b4 	ldrh	r2, [r0, #4]
  59e788:	e59f0090 	ldr	r0, [pc, #144]	@ 59e820 <IMamb_Eng_SetArchitecture+0xd4>
  59e78c:	e58d200c 	str	r2, [sp, #12]
  59e790:	e1a02001 	mov	r2, r1
  59e794:	ebfffffe 	bl	0 <printk>
			59e794: R_ARM_CALL	printk
  59e798:	e5d43001 	ldrb	r3, [r4, #1]
  59e79c:	e1a02004 	mov	r2, r4
  59e7a0:	e5d41000 	ldrb	r1, [r4]
  59e7a4:	e0811003 	add	r1, r1, r3
  59e7a8:	e5953008 	ldr	r3, [r5, #8]
  59e7ac:	e0811003 	add	r1, r1, r3
  59e7b0:	e5d43002 	ldrb	r3, [r4, #2]
  59e7b4:	e0811003 	add	r1, r1, r3
  59e7b8:	e5d43003 	ldrb	r3, [r4, #3]
  59e7bc:	e0811003 	add	r1, r1, r3
  59e7c0:	e1d430b4 	ldrh	r3, [r4, #4]
  59e7c4:	e0811003 	add	r1, r1, r3
  59e7c8:	e3a03000 	mov	r3, #0
  59e7cc:	e0840003 	add	r0, r4, r3
  59e7d0:	e1d2c7de 	ldrsb	ip, [r2, #126]	@ 0x7e
  59e7d4:	e1d000f6 	ldrsh	r0, [r0, #6]
  59e7d8:	e2833002 	add	r3, r3, #2
  59e7dc:	e3530078 	cmp	r3, #120	@ 0x78
  59e7e0:	e2822001 	add	r2, r2, #1
  59e7e4:	e08c0000 	add	r0, ip, r0
  59e7e8:	e0801001 	add	r1, r0, r1
  59e7ec:	1afffff6 	bne	59e7cc <IMamb_Eng_SetArchitecture+0x80>
  59e7f0:	e1a00004 	mov	r0, r4
  59e7f4:	e5851008 	str	r1, [r5, #8]
  59e7f8:	ebfffffe 	bl	5a3394 <IMamb_Fms_SetArchitecture>
			59e7f8: R_ARM_CALL	IMamb_Fms_SetArchitecture
  59e7fc:	e1a00004 	mov	r0, r4
  59e800:	ebfffffe 	bl	5a5958 <IMamb_Frc_SetArchitecture>
			59e800: R_ARM_CALL	IMamb_Frc_SetArchitecture
  59e804:	e5950008 	ldr	r0, [r5, #8]
  59e808:	ebfffffe 	bl	5a62c0 <IMamb_Frc_SetChecksum>
			59e808: R_ARM_CALL	IMamb_Frc_SetChecksum
  59e80c:	e3a00000 	mov	r0, #0
  59e810:	e24bd014 	sub	sp, fp, #20
  59e814:	e89da830 	ldm	sp, {r4, r5, fp, sp, pc}
  59e818:	00085921 	andeq	r5, r8, r1, lsr #18
			59e818: R_ARM_ABS32	.rodata
  59e81c:	000c28b8 			@ <UNDEFINED> instruction: 0x000c28b8
			59e81c: R_ARM_ABS32	.bss
  59e820:	000f64d4 	ldrdeq	r6, [pc], -r4
			59e820: R_ARM_ABS32	.rodata.str1.1

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:


work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

005a3394 <IMamb_Fms_SetArchitecture>:
  5a3394:	e1a0c00d 	mov	ip, sp
  5a3398:	e3a01000 	mov	r1, #0
  5a339c:	e92dd810 	push	{r4, fp, ip, lr, pc}
  5a33a0:	e24cb004 	sub	fp, ip, #4
  5a33a4:	e24ddf47 	sub	sp, sp, #284	@ 0x11c
  5a33a8:	e1a04000 	mov	r4, r0
  5a33ac:	e3a02f41 	mov	r2, #260	@ 0x104
  5a33b0:	e24b0f46 	sub	r0, fp, #280	@ 0x118
  5a33b4:	ebfffffe 	bl	0 <memset>
			5a33b4: R_ARM_CALL	memset
  5a33b8:	e5d40002 	ldrb	r0, [r4, #2]
  5a33bc:	e24bec02 	sub	lr, fp, #512	@ 0x200
  5a33c0:	e5d41003 	ldrb	r1, [r4, #3]
  5a33c4:	e1d420b4 	ldrh	r2, [r4, #4]
  5a33c8:	e5d4c001 	ldrb	ip, [r4, #1]
  5a33cc:	e50b110c 	str	r1, [fp, #-268]	@ 0xfffffef4
  5a33d0:	e1ce2fb8 	strh	r2, [lr, #248]	@ 0xf8
  5a33d4:	e98d0007 	stmib	sp, {r0, r1, r2}
  5a33d8:	e59f1088 	ldr	r1, [pc, #136]	@ 5a3468 <IMamb_Fms_SetArchitecture+0xd4>
  5a33dc:	e5d43000 	ldrb	r3, [r4]
  5a33e0:	e1a02001 	mov	r2, r1
  5a33e4:	e50b0110 	str	r0, [fp, #-272]	@ 0xfffffef0
  5a33e8:	e58dc000 	str	ip, [sp]
  5a33ec:	e59f0078 	ldr	r0, [pc, #120]	@ 5a346c <IMamb_Fms_SetArchitecture+0xd8>
  5a33f0:	e50b3118 	str	r3, [fp, #-280]	@ 0xfffffee8
  5a33f4:	e50bc114 	str	ip, [fp, #-276]	@ 0xfffffeec
  5a33f8:	ebfffffe 	bl	0 <printk>
			5a33f8: R_ARM_CALL	printk
  5a33fc:	e24b3f46 	sub	r3, fp, #280	@ 0x118
  5a3400:	e24b0f42 	sub	r0, fp, #264	@ 0x108
  5a3404:	e1a02003 	mov	r2, r3
  5a3408:	e1a01004 	mov	r1, r4
  5a340c:	e3a03000 	mov	r3, #0
  5a3410:	e084c003 	add	ip, r4, r3
  5a3414:	e2833002 	add	r3, r3, #2
  5a3418:	e1dcc0b6 	ldrh	ip, [ip, #6]
  5a341c:	e3530078 	cmp	r3, #120	@ 0x78
  5a3420:	e2811001 	add	r1, r1, #1
  5a3424:	e2822001 	add	r2, r2, #1
  5a3428:	e1e0c0b2 	strh	ip, [r0, #2]!
  5a342c:	e5d1c07d 	ldrb	ip, [r1, #125]	@ 0x7d
  5a3430:	e5c2c089 	strb	ip, [r2, #137]	@ 0x89
  5a3434:	e5d1c0b9 	ldrb	ip, [r1, #185]	@ 0xb9
  5a3438:	e5c2c0c5 	strb	ip, [r2, #197]	@ 0xc5
  5a343c:	1afffff3 	bne	5a3410 <IMamb_Fms_SetArchitecture+0x7c>
  5a3440:	e59f3028 	ldr	r3, [pc, #40]	@ 5a3470 <IMamb_Fms_SetArchitecture+0xdc>
  5a3444:	e5930000 	ldr	r0, [r3]
  5a3448:	e3500000 	cmp	r0, #0
  5a344c:	03a00001 	moveq	r0, #1
  5a3450:	0a000002 	beq	5a3460 <IMamb_Fms_SetArchitecture+0xcc>
  5a3454:	e24b1f46 	sub	r1, fp, #280	@ 0x118
  5a3458:	ebfffffe 	bl	597988 <amb_setArchitecture>
			5a3458: R_ARM_CALL	amb_setArchitecture
  5a345c:	e3a00000 	mov	r0, #0
  5a3460:	e24bd010 	sub	sp, fp, #16
  5a3464:	e89da810 	ldm	sp, {r4, fp, sp, pc}
  5a3468:	000870e3 	andeq	r7, r8, r3, ror #1
			5a3468: R_ARM_ABS32	.rodata
  5a346c:	000f6f4d 	andeq	r6, pc, sp, asr #30
			5a346c: R_ARM_ABS32	.rodata.str1.1
  5a3470:	000c4e88 	andeq	r4, ip, r8, lsl #29
			5a3470: R_ARM_ABS32	.bss

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:


work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

00597988 <amb_setArchitecture>:
  597988:	e1a0c00d 	mov	ip, sp
  59798c:	e92dd830 	push	{r4, r5, fp, ip, lr, pc}
  597990:	e2505000 	subs	r5, r0, #0
  597994:	e24cb004 	sub	fp, ip, #4
  597998:	e24dde11 	sub	sp, sp, #272	@ 0x110
  59799c:	e1a04001 	mov	r4, r1
  5979a0:	0a00003b 	beq	597a94 <amb_setArchitecture+0x10c>
  5979a4:	e5953004 	ldr	r3, [r5, #4]
  5979a8:	e3530000 	cmp	r3, #0
  5979ac:	0a000038 	beq	597a94 <amb_setArchitecture+0x10c>
  5979b0:	e3510000 	cmp	r1, #0
  5979b4:	0a000036 	beq	597a94 <amb_setArchitecture+0x10c>
  5979b8:	e5912000 	ldr	r2, [r1]
  5979bc:	e5911004 	ldr	r1, [r1, #4]
  5979c0:	e5940008 	ldr	r0, [r4, #8]
  5979c4:	e0821001 	add	r1, r2, r1
  5979c8:	e2411001 	sub	r1, r1, #1
  5979cc:	e0811000 	add	r1, r1, r0
  5979d0:	e594000c 	ldr	r0, [r4, #12]
  5979d4:	e0811000 	add	r1, r1, r0
  5979d8:	e3510023 	cmp	r1, #35	@ 0x23
  5979dc:	83a00004 	movhi	r0, #4
  5979e0:	8a00002c 	bhi	597a98 <amb_setArchitecture+0x110>
  5979e4:	e58320a8 	str	r2, [r3, #168]	@ 0xa8
  5979e8:	e284100c 	add	r1, r4, #12
  5979ec:	e5953004 	ldr	r3, [r5, #4]
  5979f0:	e1a0000d 	mov	r0, sp
  5979f4:	e5942004 	ldr	r2, [r4, #4]
  5979f8:	e58320ac 	str	r2, [r3, #172]	@ 0xac
  5979fc:	e5953004 	ldr	r3, [r5, #4]
  597a00:	e5942008 	ldr	r2, [r4, #8]
  597a04:	e58320b0 	str	r2, [r3, #176]	@ 0xb0
  597a08:	e5953004 	ldr	r3, [r5, #4]
  597a0c:	e594200c 	ldr	r2, [r4, #12]
  597a10:	e58320b4 	str	r2, [r3, #180]	@ 0xb4
  597a14:	e5953004 	ldr	r3, [r5, #4]
  597a18:	e1d421b0 	ldrh	r2, [r4, #16]
  597a1c:	e1c32bb8 	strh	r2, [r3, #184]	@ 0xb8
  597a20:	e3a020f8 	mov	r2, #248	@ 0xf8
  597a24:	ebfffffe 	bl	0 <memcpy>
			597a24: R_ARM_CALL	memcpy
  597a28:	e894000e 	ldm	r4, {r1, r2, r3}
  597a2c:	e5950004 	ldr	r0, [r5, #4]
  597a30:	ebfffffe 	bl	59a384 <amb_driv_setArchitecture>
			597a30: R_ARM_CALL	amb_driv_setArchitecture
  597a34:	e5940000 	ldr	r0, [r4]
  597a38:	e595c000 	ldr	ip, [r5]
  597a3c:	e5850024 	str	r0, [r5, #36]	@ 0x24
  597a40:	e5941004 	ldr	r1, [r4, #4]
  597a44:	e35c0000 	cmp	ip, #0
  597a48:	e5851028 	str	r1, [r5, #40]	@ 0x28
  597a4c:	e5943008 	ldr	r3, [r4, #8]
  597a50:	e585302c 	str	r3, [r5, #44]	@ 0x2c
  597a54:	e594200c 	ldr	r2, [r4, #12]
  597a58:	e5852030 	str	r2, [r5, #48]	@ 0x30
  597a5c:	0a00000a 	beq	597a8c <amb_setArchitecture+0x104>
  597a60:	e50b3020 	str	r3, [fp, #-32]	@ 0xffffffe0
  597a64:	e24b3014 	sub	r3, fp, #20
  597a68:	e5232008 	str	r2, [r3, #-8]!
  597a6c:	e50b0028 	str	r0, [fp, #-40]	@ 0xffffffd8
  597a70:	e50b1024 	str	r1, [fp, #-36]	@ 0xffffffdc
  597a74:	e8930003 	ldm	r3, {r0, r1}
  597a78:	e24b3028 	sub	r3, fp, #40	@ 0x28
  597a7c:	e88d0003 	stm	sp, {r0, r1}
  597a80:	e1a0000c 	mov	r0, ip
  597a84:	e893000e 	ldm	r3, {r1, r2, r3}
  597a88:	ebfffffe 	bl	59a7fc <amb_halo_setConfiguration>
			597a88: R_ARM_CALL	amb_halo_setConfiguration
  597a8c:	e3a00000 	mov	r0, #0
  597a90:	ea000000 	b	597a98 <amb_setArchitecture+0x110>
  597a94:	e3a00002 	mov	r0, #2
  597a98:	e24bd014 	sub	sp, fp, #20
  597a9c:	e89da830 	ldm	sp, {r4, r5, fp, sp, pc}

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:


work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

0059a384 <amb_driv_setArchitecture>:
  59a384:	e24dd010 	sub	sp, sp, #16
  59a388:	e3500000 	cmp	r0, #0
  59a38c:	e92d47f0 	push	{r4, r5, r6, r7, r8, r9, sl, lr}
  59a390:	e28dc024 	add	ip, sp, #36	@ 0x24
  59a394:	e88c000e 	stm	ip, {r1, r2, r3}
  59a398:	e59de030 	ldr	lr, [sp, #48]	@ 0x30
  59a39c:	0a00002c 	beq	59a454 <amb_driv_setArchitecture+0xd0>
  59a3a0:	e3a03000 	mov	r3, #0
  59a3a4:	e1a02000 	mov	r2, r0
  59a3a8:	e28d6034 	add	r6, sp, #52	@ 0x34
  59a3ac:	e1a04000 	mov	r4, r0
  59a3b0:	e1a01003 	mov	r1, r3
  59a3b4:	e1a08003 	mov	r8, r3
  59a3b8:	e3a09001 	mov	r9, #1
  59a3bc:	e5dc508a 	ldrb	r5, [ip, #138]	@ 0x8a
  59a3c0:	e6af7075 	sxtb	r7, r5
  59a3c4:	e3570000 	cmp	r7, #0
  59a3c8:	ba000007 	blt	59a3ec <amb_driv_setArchitecture+0x68>
  59a3cc:	e5c25132 	strb	r5, [r2, #306]	@ 0x132
  59a3d0:	e35e0000 	cmp	lr, #0
  59a3d4:	e1f650b2 	ldrh	r5, [r6, #2]!
  59a3d8:	e5dca0c6 	ldrb	sl, [ip, #198]	@ 0xc6
  59a3dc:	e1c45bba 	strh	r5, [r4, #186]	@ 0xba
  59a3e0:	e5c2a16e 	strb	sl, [r2, #366]	@ 0x16e
  59a3e4:	1a00000b 	bne	59a418 <amb_driv_setArchitecture+0x94>
  59a3e8:	ea000012 	b	59a438 <amb_driv_setArchitecture+0xb4>
  59a3ec:	e28dc020 	add	ip, sp, #32
  59a3f0:	e0802003 	add	r2, r0, r3
  59a3f4:	e08c1083 	add	r1, ip, r3, lsl #1
  59a3f8:	e0800083 	add	r0, r0, r3, lsl #1
  59a3fc:	e5c25132 	strb	r5, [r2, #306]	@ 0x132
  59a400:	e08c3003 	add	r3, ip, r3
  59a404:	e1d111b6 	ldrh	r1, [r1, #22]
  59a408:	e5d330ca 	ldrb	r3, [r3, #202]	@ 0xca
  59a40c:	e1c01bba 	strh	r1, [r0, #186]	@ 0xba
  59a410:	e5c2316e 	strb	r3, [r2, #366]	@ 0x16e
  59a414:	ea00000d 	b	59a450 <amb_driv_setArchitecture+0xcc>
  59a418:	e3150902 	tst	r5, #32768	@ 0x8000
  59a41c:	1a000005 	bne	59a438 <amb_driv_setArchitecture+0xb4>
  59a420:	e2811001 	add	r1, r1, #1
  59a424:	e0807007 	add	r7, r0, r7
  59a428:	e151000e 	cmp	r1, lr
  59a42c:	81a05008 	movhi	r5, r8
  59a430:	91a05009 	movls	r5, r9
  59a434:	e5c7586d 	strb	r5, [r7, #2157]	@ 0x86d
  59a438:	e2833001 	add	r3, r3, #1
  59a43c:	e28cc001 	add	ip, ip, #1
  59a440:	e353003c 	cmp	r3, #60	@ 0x3c
  59a444:	e2822001 	add	r2, r2, #1
  59a448:	e2844002 	add	r4, r4, #2
  59a44c:	1affffda 	bne	59a3bc <amb_driv_setArchitecture+0x38>
  59a450:	e3a00001 	mov	r0, #1
  59a454:	e8bd47f0 	pop	{r4, r5, r6, r7, r8, r9, sl, lr}
  59a458:	e28dd010 	add	sp, sp, #16
  59a45c:	e12fff1e 	bx	lr

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:


work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

000d61c4 <_AmbilightProcThread_Body>:
   d61c4:	e1a0c00d 	mov	ip, sp
   d61c8:	e92dd818 	push	{r3, r4, fp, ip, lr, pc}
   d61cc:	e24cb004 	sub	fp, ip, #4
   d61d0:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
   d61d4:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			d61d4: R_ARM_CALL	__gnu_mcount_nc
   d61d8:	e59f4028 	ldr	r4, [pc, #40]	@ d6208 <_AmbilightProcThread_Body+0x44>
   d61dc:	e59f0028 	ldr	r0, [pc, #40]	@ d620c <_AmbilightProcThread_Body+0x48>
   d61e0:	ebfffffe 	bl	0 <printk>
			d61e0: R_ARM_CALL	printk
   d61e4:	e59f0024 	ldr	r0, [pc, #36]	@ d6210 <_AmbilightProcThread_Body+0x4c>
   d61e8:	ebfffffe 	bl	5932a8 <IMambP_GetMode>
			d61e8: R_ARM_CALL	IMambP_GetMode
   d61ec:	e5943010 	ldr	r3, [r4, #16]
   d61f0:	e3530008 	cmp	r3, #8
   d61f4:	1a000000 	bne	d61fc <_AmbilightProcThread_Body+0x38>
   d61f8:	ebfffffe 	bl	592d04 <IMambP_BackgroundTask>
			d61f8: R_ARM_CALL	IMambP_BackgroundTask
   d61fc:	e3a00014 	mov	r0, #20
   d6200:	ebfffffe 	bl	32cec4 <x_thread_delay>
			d6200: R_ARM_CALL	x_thread_delay
   d6204:	eafffff6 	b	d61e4 <_AmbilightProcThread_Body+0x20>
   d6208:	0004d1b8 			@ <UNDEFINED> instruction: 0x0004d1b8
			d6208: R_ARM_ABS32	.bss
   d620c:	000310a8 	andeq	r1, r3, r8, lsr #1
			d620c: R_ARM_ABS32	.rodata.str1.1
   d6210:	0004d1c8 	andeq	sp, r4, r8, asr #3
			d6210: R_ARM_ABS32	.bss

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:


work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

000dd8d4 <DRVCUST_VideoMainloop>:
   dd8d4:	e1a0c00d 	mov	ip, sp
   dd8d8:	e92dd818 	push	{r3, r4, fp, ip, lr, pc}
   dd8dc:	e24cb004 	sub	fp, ip, #4
   dd8e0:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
   dd8e4:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			dd8e4: R_ARM_CALL	__gnu_mcount_nc
   dd8e8:	e59f40d8 	ldr	r4, [pc, #216]	@ dd9c8 <DRVCUST_VideoMainloop+0xf4>
   dd8ec:	ebfffffe 	bl	dd614 <_DRVCUST_DBLProc>
			dd8ec: R_ARM_CALL	_DRVCUST_DBLProc
   dd8f0:	ebfffffe 	bl	610758 <IMsrcmeterP_RunSrcAutoMeter>
			dd8f0: R_ARM_CALL	IMsrcmeterP_RunSrcAutoMeter
   dd8f4:	ebfffffe 	bl	610558 <IMsrcmeterP_UpdateSrcAutoMeterVSync>
			dd8f4: R_ARM_CALL	IMsrcmeterP_UpdateSrcAutoMeterVSync
   dd8f8:	e5d43693 	ldrb	r3, [r4, #1683]	@ 0x693
   dd8fc:	e3530000 	cmp	r3, #0
   dd900:	0a000000 	beq	dd908 <DRVCUST_VideoMainloop+0x34>
   dd904:	ebfffffe 	bl	613d94 <IMvideoP_BgTaskBackLightControl>
			dd904: R_ARM_CALL	IMvideoP_BgTaskBackLightControl
   dd908:	ebfffffe 	bl	d7c1c <vDrvCheckBLDBlackPic>
			dd908: R_ARM_CALL	vDrvCheckBLDBlackPic
   dd90c:	e5d42692 	ldrb	r2, [r4, #1682]	@ 0x692
   dd910:	e59f30b0 	ldr	r3, [pc, #176]	@ dd9c8 <DRVCUST_VideoMainloop+0xf4>
   dd914:	e3120002 	tst	r2, #2
   dd918:	0a000007 	beq	dd93c <DRVCUST_VideoMainloop+0x68>
   dd91c:	e5930738 	ldr	r0, [r3, #1848]	@ 0x738
   dd920:	e3a0100c 	mov	r1, #12
   dd924:	e2802001 	add	r2, r0, #1
   dd928:	e5832738 	str	r2, [r3, #1848]	@ 0x738
   dd92c:	ebfffffe 	bl	6563a0 <__aeabi_uidivmod>
			dd92c: R_ARM_CALL	__aeabi_uidivmod
   dd930:	e3510000 	cmp	r1, #0
   dd934:	1a000000 	bne	dd93c <DRVCUST_VideoMainloop+0x68>
   dd938:	ebfffffe 	bl	4ad4 <IMvideoP_WBCGamma_Event>
			dd938: R_ARM_CALL	IMvideoP_WBCGamma_Event
   dd93c:	e594073c 	ldr	r0, [r4, #1852]	@ 0x73c
   dd940:	e3a0100c 	mov	r1, #12
   dd944:	e2803001 	add	r3, r0, #1
   dd948:	e584373c 	str	r3, [r4, #1852]	@ 0x73c
   dd94c:	ebfffffe 	bl	6563a0 <__aeabi_uidivmod>
			dd94c: R_ARM_CALL	__aeabi_uidivmod
   dd950:	e3510000 	cmp	r1, #0
   dd954:	1a000000 	bne	dd95c <DRVCUST_VideoMainloop+0x88>
   dd958:	ebfffffe 	bl	5a85c0 <pqsoccontrolP_Event>
			dd958: R_ARM_CALL	pqsoccontrolP_Event
   dd95c:	e59f0068 	ldr	r0, [pc, #104]	@ dd9cc <DRVCUST_VideoMainloop+0xf8>
   dd960:	ebfffffe 	bl	5932a8 <IMambP_GetMode>
			dd960: R_ARM_CALL	IMambP_GetMode
   dd964:	e5943740 	ldr	r3, [r4, #1856]	@ 0x740
   dd968:	e3530008 	cmp	r3, #8
   dd96c:	0a000000 	beq	dd974 <DRVCUST_VideoMainloop+0xa0>
   dd970:	ebfffffe 	bl	592d04 <IMambP_BackgroundTask>
			dd970: R_ARM_CALL	IMambP_BackgroundTask
   dd974:	e3a00000 	mov	r0, #0
   dd978:	ebfffffe 	bl	1a8368 <bDrvVideoSignalStatus>
			dd978: R_ARM_CALL	bDrvVideoSignalStatus
   dd97c:	e3500003 	cmp	r0, #3
   dd980:	1a000000 	bne	dd988 <DRVCUST_VideoMainloop+0xb4>
   dd984:	ebfffffe 	bl	d9f5c <vDrvAutoNRProc>
			dd984: R_ARM_CALL	vDrvAutoNRProc
   dd988:	e3a00000 	mov	r0, #0
   dd98c:	ebfffffe 	bl	1a8368 <bDrvVideoSignalStatus>
			dd98c: R_ARM_CALL	bDrvVideoSignalStatus
   dd990:	e3500003 	cmp	r0, #3
   dd994:	1a000006 	bne	dd9b4 <DRVCUST_VideoMainloop+0xe0>
   dd998:	e59f3030 	ldr	r3, [pc, #48]	@ dd9d0 <DRVCUST_VideoMainloop+0xfc>
   dd99c:	e5933000 	ldr	r3, [r3]
   dd9a0:	e5d33902 	ldrb	r3, [r3, #2306]	@ 0x902
   dd9a4:	e3130004 	tst	r3, #4
   dd9a8:	089da818 	ldmeq	sp, {r3, r4, fp, sp, pc}
   dd9ac:	ebfffffe 	bl	d745c <vDrvPQModuleOnOffProc>
			dd9ac: R_ARM_CALL	vDrvPQModuleOnOffProc
   dd9b0:	e89da818 	ldm	sp, {r3, r4, fp, sp, pc}
   dd9b4:	e3a00001 	mov	r0, #1
   dd9b8:	ebfffffe 	bl	1a8368 <bDrvVideoSignalStatus>
			dd9b8: R_ARM_CALL	bDrvVideoSignalStatus
   dd9bc:	e3500003 	cmp	r0, #3
   dd9c0:	189da818 	ldmne	sp, {r3, r4, fp, sp, pc}
   dd9c4:	eafffff3 	b	dd998 <DRVCUST_VideoMainloop+0xc4>
   dd9c8:	0004d1b8 			@ <UNDEFINED> instruction: 0x0004d1b8
			dd9c8: R_ARM_ABS32	.bss
   dd9cc:	0004d8f8 	strdeq	sp, [r4], -r8
			dd9cc: R_ARM_ABS32	.bss
   dd9d0:	00000000 	andeq	r0, r0, r0
			dd9d0: R_ARM_ABS32	SW_DRAM_BASE

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:


work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

0059ee50 <IMamb_Eng_Execute>:
  59ee50:	e1a0c00d 	mov	ip, sp
  59ee54:	e92dd830 	push	{r4, r5, fp, ip, lr, pc}
  59ee58:	e24cb004 	sub	fp, ip, #4
  59ee5c:	e59f410c 	ldr	r4, [pc, #268]	@ 59ef70 <IMamb_Eng_Execute+0x120>
  59ee60:	e24dd008 	sub	sp, sp, #8
  59ee64:	e5d4300d 	ldrb	r3, [r4, #13]
  59ee68:	e3530000 	cmp	r3, #0
  59ee6c:	0a000001 	beq	59ee78 <IMamb_Eng_Execute+0x28>
  59ee70:	ebfffffe 	bl	5a2f88 <IMamb_Fms_Execute_ProjectionAL>
			59ee70: R_ARM_CALL	IMamb_Fms_Execute_ProjectionAL
  59ee74:	ea00003a 	b	59ef64 <IMamb_Eng_Execute+0x114>
  59ee78:	e5d4300e 	ldrb	r3, [r4, #14]
  59ee7c:	e3530000 	cmp	r3, #0
  59ee80:	0a000037 	beq	59ef64 <IMamb_Eng_Execute+0x114>
  59ee84:	e24b0018 	sub	r0, fp, #24
  59ee88:	e59f50e4 	ldr	r5, [pc, #228]	@ 59ef74 <IMamb_Eng_Execute+0x124>
  59ee8c:	ebfffffe 	bl	5a3764 <IMamb_Fms_GetMode>
			59ee8c: R_ARM_CALL	IMamb_Fms_GetMode
  59ee90:	e51b3018 	ldr	r3, [fp, #-24]	@ 0xffffffe8
  59ee94:	e3530005 	cmp	r3, #5
  59ee98:	1a00000a 	bne	59eec8 <IMamb_Eng_Execute+0x78>
  59ee9c:	ebfffffe 	bl	1b20 <IMamb_IsSplashScreenOn>
			59ee9c: R_ARM_CALL	IMamb_IsSplashScreenOn
  59eea0:	e3500000 	cmp	r0, #0
  59eea4:	0a000007 	beq	59eec8 <IMamb_Eng_Execute+0x78>
  59eea8:	ebfffffe 	bl	1b20 <IMamb_IsSplashScreenOn>
			59eea8: R_ARM_CALL	IMamb_IsSplashScreenOn
  59eeac:	e3500000 	cmp	r0, #0
  59eeb0:	1a000004 	bne	59eec8 <IMamb_Eng_Execute+0x78>
  59eeb4:	e59f10bc 	ldr	r1, [pc, #188]	@ 59ef78 <IMamb_Eng_Execute+0x128>
  59eeb8:	e5850004 	str	r0, [r5, #4]
  59eebc:	e59f00b8 	ldr	r0, [pc, #184]	@ 59ef7c <IMamb_Eng_Execute+0x12c>
  59eec0:	e1a02001 	mov	r2, r1
  59eec4:	ebfffffe 	bl	0 <printk>
			59eec4: R_ARM_CALL	printk
  59eec8:	e5953004 	ldr	r3, [r5, #4]
  59eecc:	e30f1fff 	movw	r1, #65535	@ 0xffff
  59eed0:	e59f209c 	ldr	r2, [pc, #156]	@ 59ef74 <IMamb_Eng_Execute+0x124>
  59eed4:	e1530001 	cmp	r3, r1
  59eed8:	0a000005 	beq	59eef4 <IMamb_Eng_Execute+0xa4>
  59eedc:	e3530000 	cmp	r3, #0
  59eee0:	12433001 	subne	r3, r3, #1
  59eee4:	15823004 	strne	r3, [r2, #4]
  59eee8:	1a000001 	bne	59eef4 <IMamb_Eng_Execute+0xa4>
  59eeec:	e5821004 	str	r1, [r2, #4]
  59eef0:	ebfffffe 	bl	59e624 <IMamb_Eng_StartActiveMode>
			59eef0: R_ARM_CALL	IMamb_Eng_StartActiveMode
  59eef4:	e5953000 	ldr	r3, [r5]
  59eef8:	e3530004 	cmp	r3, #4
  59eefc:	0a000017 	beq	59ef60 <IMamb_Eng_Execute+0x110>
  59ef00:	e5940010 	ldr	r0, [r4, #16]
  59ef04:	e3003177 	movw	r3, #375	@ 0x177
  59ef08:	e2800001 	add	r0, r0, #1
  59ef0c:	e1500003 	cmp	r0, r3
  59ef10:	e5840010 	str	r0, [r4, #16]
  59ef14:	0a000005 	beq	59ef30 <IMamb_Eng_Execute+0xe0>
  59ef18:	e3500f7d 	cmp	r0, #500	@ 0x1f4
  59ef1c:	0a000005 	beq	59ef38 <IMamb_Eng_Execute+0xe8>
  59ef20:	e3500032 	cmp	r0, #50	@ 0x32
  59ef24:	03a00001 	moveq	r0, #1
  59ef28:	1a000004 	bne	59ef40 <IMamb_Eng_Execute+0xf0>
  59ef2c:	ea00000a 	b	59ef5c <IMamb_Eng_Execute+0x10c>
  59ef30:	e3a00002 	mov	r0, #2
  59ef34:	ea000008 	b	59ef5c <IMamb_Eng_Execute+0x10c>
  59ef38:	ebfffffe 	bl	59ee28 <IMamb_Eng_SetSunsetFinished>
			59ef38: R_ARM_CALL	IMamb_Eng_SetSunsetFinished
  59ef3c:	ea000007 	b	59ef60 <IMamb_Eng_Execute+0x110>
  59ef40:	e1500003 	cmp	r0, r3
  59ef44:	9a000005 	bls	59ef60 <IMamb_Eng_Execute+0x110>
  59ef48:	e3a01005 	mov	r1, #5
  59ef4c:	ebfffffe 	bl	6563a0 <__aeabi_uidivmod>
			59ef4c: R_ARM_CALL	__aeabi_uidivmod
  59ef50:	e3510000 	cmp	r1, #0
  59ef54:	1a000001 	bne	59ef60 <IMamb_Eng_Execute+0x110>
  59ef58:	e3a00003 	mov	r0, #3
  59ef5c:	ebfffffe 	bl	5a0d3c <IMamb_App_SunsetFSM>
			59ef5c: R_ARM_CALL	IMamb_App_SunsetFSM
  59ef60:	ebfffffe 	bl	5a2ea4 <IMamb_Fms_Execute>
			59ef60: R_ARM_CALL	IMamb_Fms_Execute
  59ef64:	e3a00000 	mov	r0, #0
  59ef68:	e24bd014 	sub	sp, fp, #20
  59ef6c:	e89da830 	ldm	sp, {r4, r5, fp, sp, pc}
  59ef70:	000c28b8 			@ <UNDEFINED> instruction: 0x000c28b8
			59ef70: R_ARM_ABS32	.bss
  59ef74:	00089484 	andeq	r9, r8, r4, lsl #9
			59ef74: R_ARM_ABS32	.data
  59ef78:	00085a87 	andeq	r5, r8, r7, lsl #21
			59ef78: R_ARM_ABS32	.rodata
  59ef7c:	000f6768 	andeq	r6, pc, r8, ror #14
			59ef7c: R_ARM_ABS32	.rodata.str1.1

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:


work/philips-ambilight/dtv_driver.ko:     file format elf32-littlearm


Disassembly of section .text:

001a6c58 <vVdoOutISR>:
  1a6c58:	e1a0c00d 	mov	ip, sp
  1a6c5c:	e92dd9f8 	push	{r3, r4, r5, r6, r7, r8, fp, ip, lr, pc}
  1a6c60:	e24cb004 	sub	fp, ip, #4
  1a6c64:	e52de004 	push	{lr}		@ (str lr, [sp, #-4]!)
  1a6c68:	ebfffffe 	bl	0 <__gnu_mcount_nc>
			1a6c68: R_ARM_CALL	__gnu_mcount_nc
  1a6c6c:	e59f3218 	ldr	r3, [pc, #536]	@ 1a6e8c <vVdoOutISR+0x234>
  1a6c70:	e5935000 	ldr	r5, [r3]
  1a6c74:	e2155b01 	ands	r5, r5, #1024	@ 0x400
  1a6c78:	189da9f8 	ldmne	sp, {r3, r4, r5, r6, r7, r8, fp, sp, pc}
  1a6c7c:	e59f820c 	ldr	r8, [pc, #524]	@ 1a6e90 <vVdoOutISR+0x238>
  1a6c80:	e59f420c 	ldr	r4, [pc, #524]	@ 1a6e94 <vVdoOutISR+0x23c>
  1a6c84:	e5d83000 	ldrb	r3, [r8]
  1a6c88:	e3530000 	cmp	r3, #0
  1a6c8c:	0a00000f 	beq	1a6cd0 <vVdoOutISR+0x78>
  1a6c90:	e59f3200 	ldr	r3, [pc, #512]	@ 1a6e98 <vVdoOutISR+0x240>
  1a6c94:	e5d36000 	ldrb	r6, [r3]
  1a6c98:	e3560001 	cmp	r6, #1
  1a6c9c:	1a00000b 	bne	1a6cd0 <vVdoOutISR+0x78>
  1a6ca0:	ebfffffe 	bl	167b6c <u2PscGetPanelVCNTStatus>
			1a6ca0: R_ARM_CALL	u2PscGetPanelVCNTStatus
  1a6ca4:	e35000c8 	cmp	r0, #200	@ 0xc8
  1a6ca8:	e1c400be 	strh	r0, [r4, #14]
  1a6cac:	9a000008 	bls	1a6cd4 <vVdoOutISR+0x7c>
  1a6cb0:	ebfffffe 	bl	145cb8 <vDrvSetScanPWMSW_SETDATA>
			1a6cb0: R_ARM_CALL	vDrvSetScanPWMSW_SETDATA
  1a6cb4:	e1a00005 	mov	r0, r5
  1a6cb8:	e1a01005 	mov	r1, r5
  1a6cbc:	e1a02006 	mov	r2, r6
  1a6cc0:	e1a05006 	mov	r5, r6
  1a6cc4:	ebfffffe 	bl	144dd4 <vDrvSetScanPWMLatchMode>
			1a6cc4: R_ARM_CALL	vDrvSetScanPWMLatchMode
  1a6cc8:	ebfffffe 	bl	144e54 <vDrvScanPWMDataFire>
			1a6cc8: R_ARM_CALL	vDrvScanPWMDataFire
  1a6ccc:	ea000000 	b	1a6cd4 <vVdoOutISR+0x7c>
  1a6cd0:	e3a05002 	mov	r5, #2
  1a6cd4:	ebfffffe 	bl	156940 <OD_OnOutputVSync>
			1a6cd4: R_ARM_CALL	OD_OnOutputVSync
  1a6cd8:	ebfffffe 	bl	164d9c <vScpipOnVdoOutputVSync>
			1a6cd8: R_ARM_CALL	vScpipOnVdoOutputVSync
  1a6cdc:	ebfffffe 	bl	14a290 <OSTG_OnOutputVSync>
			1a6cdc: R_ARM_CALL	OSTG_OnOutputVSync
  1a6ce0:	ebfffffe 	bl	1d19c8 <PMX_OnOutputVSync>
			1a6ce0: R_ARM_CALL	PMX_OnOutputVSync
  1a6ce4:	e3a00000 	mov	r0, #0
  1a6ce8:	e3a06001 	mov	r6, #1
  1a6cec:	e1a01000 	mov	r1, r0
  1a6cf0:	e5c46010 	strb	r6, [r4, #16]
  1a6cf4:	ebfffffe 	bl	1b6d30 <OSD_BaseDisplayFor4K2K>
			1a6cf4: R_ARM_CALL	OSD_BaseDisplayFor4K2K
  1a6cf8:	e3a00000 	mov	r0, #0
  1a6cfc:	ebfffffe 	bl	108934 <vApiApplyVideoEvent>
			1a6cfc: R_ARM_CALL	vApiApplyVideoEvent
  1a6d00:	ebfffffe 	bl	1888ec <vDrvMeterISR>
			1a6d00: R_ARM_CALL	vDrvMeterISR
  1a6d04:	ebfffffe 	bl	173598 <vDrvADLProc>
			1a6d04: R_ARM_CALL	vDrvADLProc
  1a6d08:	ebfffffe 	bl	450afc <vDrvTTDSetQualityISR>
			1a6d08: R_ARM_CALL	vDrvTTDSetQualityISR
  1a6d0c:	ebfffffe 	bl	d7d34 <DRVCUST_PostOutVSyncISR>
			1a6d0c: R_ARM_CALL	DRVCUST_PostOutVSyncISR
  1a6d10:	ebfffffe 	bl	dc804 <DRVCUST_OutVSyncISR>
			1a6d10: R_ARM_CALL	DRVCUST_OutVSyncISR
  1a6d14:	ebfffffe 	bl	171db8 <vDrvSCEFindColor>
			1a6d14: R_ARM_CALL	vDrvSCEFindColor
  1a6d18:	e5d43011 	ldrb	r3, [r4, #17]
  1a6d1c:	e3530000 	cmp	r3, #0
  1a6d20:	1a000002 	bne	1a6d30 <vVdoOutISR+0xd8>
  1a6d24:	ebfffffe 	bl	149200 <vDrvVideoDitherInit>
			1a6d24: R_ARM_CALL	vDrvVideoDitherInit
  1a6d28:	e59f3164 	ldr	r3, [pc, #356]	@ 1a6e94 <vVdoOutISR+0x23c>
  1a6d2c:	e5c36011 	strb	r6, [r3, #17]
  1a6d30:	e3a00000 	mov	r0, #0
  1a6d34:	ebfffffe 	bl	165dc4 <bScpipIsNeedSetUpdate>
			1a6d34: R_ARM_CALL	bScpipIsNeedSetUpdate
  1a6d38:	e3500001 	cmp	r0, #1
  1a6d3c:	1a00000c 	bne	1a6d74 <vVdoOutISR+0x11c>
  1a6d40:	e59f6154 	ldr	r6, [pc, #340]	@ 1a6e9c <vVdoOutISR+0x244>
  1a6d44:	e3a00000 	mov	r0, #0
  1a6d48:	e5961238 	ldr	r1, [r6, #568]	@ 0x238
  1a6d4c:	e596223c 	ldr	r2, [r6, #572]	@ 0x23c
  1a6d50:	ebfffffe 	bl	15d7d4 <vScpipSetOutputResolution>
			1a6d50: R_ARM_CALL	vScpipSetOutputResolution
  1a6d54:	e3a03f5f 	mov	r3, #380	@ 0x17c
  1a6d58:	e3a00000 	mov	r0, #0
  1a6d5c:	e19610b3 	ldrh	r1, [r6, r3]
  1a6d60:	e2833002 	add	r3, r3, #2
  1a6d64:	e19620b3 	ldrh	r2, [r6, r3]
  1a6d68:	ebfffffe 	bl	15e490 <vScpipSetMaskStart>
			1a6d68: R_ARM_CALL	vScpipSetMaskStart
  1a6d6c:	e3a00000 	mov	r0, #0
  1a6d70:	ebfffffe 	bl	165dfc <vScpipClearNeedUpdateFlag>
			1a6d70: R_ARM_CALL	vScpipClearNeedUpdateFlag
  1a6d74:	e5d40012 	ldrb	r0, [r4, #18]
  1a6d78:	e3500001 	cmp	r0, #1
  1a6d7c:	1a000008 	bne	1a6da4 <vVdoOutISR+0x14c>
  1a6d80:	e59f310c 	ldr	r3, [pc, #268]	@ 1a6e94 <vVdoOutISR+0x23c>
  1a6d84:	e3a02000 	mov	r2, #0
  1a6d88:	e5c32012 	strb	r2, [r3, #18]
  1a6d8c:	e3a02ff5 	mov	r2, #980	@ 0x3d4
  1a6d90:	e59f3104 	ldr	r3, [pc, #260]	@ 1a6e9c <vVdoOutISR+0x244>
  1a6d94:	e19310b2 	ldrh	r1, [r3, r2]
  1a6d98:	e2822002 	add	r2, r2, #2
  1a6d9c:	e19320b2 	ldrh	r2, [r3, r2]
  1a6da0:	ebfffffe 	bl	15e490 <vScpipSetMaskStart>
			1a6da0: R_ARM_CALL	vScpipSetMaskStart
  1a6da4:	e3a00001 	mov	r0, #1
  1a6da8:	ebfffffe 	bl	165dc4 <bScpipIsNeedSetUpdate>
			1a6da8: R_ARM_CALL	bScpipIsNeedSetUpdate
  1a6dac:	e3500001 	cmp	r0, #1
  1a6db0:	e1a06000 	mov	r6, r0
  1a6db4:	1a00000b 	bne	1a6de8 <vVdoOutISR+0x190>
  1a6db8:	e59f70dc 	ldr	r7, [pc, #220]	@ 1a6e9c <vVdoOutISR+0x244>
  1a6dbc:	e5c40012 	strb	r0, [r4, #18]
  1a6dc0:	e5971490 	ldr	r1, [r7, #1168]	@ 0x490
  1a6dc4:	e5972494 	ldr	r2, [r7, #1172]	@ 0x494
  1a6dc8:	ebfffffe 	bl	15d7d4 <vScpipSetOutputResolution>
			1a6dc8: R_ARM_CALL	vScpipSetOutputResolution
  1a6dcc:	e30033d6 	movw	r3, #982	@ 0x3d6
  1a6dd0:	e1a00006 	mov	r0, r6
  1a6dd4:	e3001fff 	movw	r1, #4095	@ 0xfff
  1a6dd8:	e19720b3 	ldrh	r2, [r7, r3]
  1a6ddc:	ebfffffe 	bl	15e490 <vScpipSetMaskStart>
			1a6ddc: R_ARM_CALL	vScpipSetMaskStart
  1a6de0:	e1a00006 	mov	r0, r6
  1a6de4:	ebfffffe 	bl	165dfc <vScpipClearNeedUpdateFlag>
			1a6de4: R_ARM_CALL	vScpipClearNeedUpdateFlag
  1a6de8:	ebfffffe 	bl	149020 <vVdoOutISRCheckApplyPanelTiming>
			1a6de8: R_ARM_CALL	vVdoOutISRCheckApplyPanelTiming
  1a6dec:	ebfffffe 	bl	148e94 <vDrvVB1VideoMuteTiming>
			1a6dec: R_ARM_CALL	vDrvVB1VideoMuteTiming
  1a6df0:	ebfffffe 	bl	e1ed0 <PANEL_GetControlWord>
			1a6df0: R_ARM_CALL	PANEL_GetControlWord
  1a6df4:	e2106301 	ands	r6, r0, #67108864	@ 0x4000000
  1a6df8:	0a000003 	beq	1a6e0c <vVdoOutISR+0x1b4>
  1a6dfc:	ebfffffe 	bl	1a44d8 <vMLoopUnlockVSyncSem>
			1a6dfc: R_ARM_CALL	vMLoopUnlockVSyncSem
  1a6e00:	e3a03001 	mov	r3, #1
  1a6e04:	e5c43013 	strb	r3, [r4, #19]
  1a6e08:	ea000007 	b	1a6e2c <vVdoOutISR+0x1d4>
  1a6e0c:	ebfffffe 	bl	149988 <vDrvGetLCDFreq>
			1a6e0c: R_ARM_CALL	vDrvGetLCDFreq
  1a6e10:	e350004c 	cmp	r0, #76	@ 0x4c
  1a6e14:	9afffff8 	bls	1a6dfc <vVdoOutISR+0x1a4>
  1a6e18:	e5d43013 	ldrb	r3, [r4, #19]
  1a6e1c:	e3530000 	cmp	r3, #0
  1a6e20:	0afffff5 	beq	1a6dfc <vVdoOutISR+0x1a4>
  1a6e24:	e59f3068 	ldr	r3, [pc, #104]	@ 1a6e94 <vVdoOutISR+0x23c>
  1a6e28:	e5c36013 	strb	r6, [r3, #19]
  1a6e2c:	e59f206c 	ldr	r2, [pc, #108]	@ 1a6ea0 <vVdoOutISR+0x248>
  1a6e30:	e5d23000 	ldrb	r3, [r2]
  1a6e34:	e3530000 	cmp	r3, #0
  1a6e38:	0a000005 	beq	1a6e54 <vVdoOutISR+0x1fc>
  1a6e3c:	e2433001 	sub	r3, r3, #1
  1a6e40:	e6ef3073 	uxtb	r3, r3
  1a6e44:	e3530000 	cmp	r3, #0
  1a6e48:	e5c23000 	strb	r3, [r2]
  1a6e4c:	1a000000 	bne	1a6e54 <vVdoOutISR+0x1fc>
  1a6e50:	ebfffffe 	bl	151fa8 <vDrvLVDS7To4FifoEnable>
			1a6e50: R_ARM_CALL	vDrvLVDS7To4FifoEnable
  1a6e54:	e3550001 	cmp	r5, #1
  1a6e58:	189da9f8 	ldmne	sp, {r3, r4, r5, r6, r7, r8, fp, sp, pc}
  1a6e5c:	e59f3040 	ldr	r3, [pc, #64]	@ 1a6ea4 <vVdoOutISR+0x24c>
  1a6e60:	e5d33000 	ldrb	r3, [r3]
  1a6e64:	e3530000 	cmp	r3, #0
  1a6e68:	0a000005 	beq	1a6e84 <vVdoOutISR+0x22c>
  1a6e6c:	ebfffffe 	bl	14579c <u1DrvGetScanPWMStruct_Ready>
			1a6e6c: R_ARM_CALL	u1DrvGetScanPWMStruct_Ready
  1a6e70:	e3500000 	cmp	r0, #0
  1a6e74:	13a03000 	movne	r3, #0
  1a6e78:	1a000001 	bne	1a6e84 <vVdoOutISR+0x22c>
  1a6e7c:	ebfffffe 	bl	145b9c <vDrvSetScanPWMSW_StepControl>
			1a6e7c: R_ARM_CALL	vDrvSetScanPWMSW_StepControl
  1a6e80:	e89da9f8 	ldm	sp, {r3, r4, r5, r6, r7, r8, fp, sp, pc}
  1a6e84:	e5c83000 	strb	r3, [r8]
  1a6e88:	e89da9f8 	ldm	sp, {r3, r4, r5, r6, r7, r8, fp, sp, pc}
	...
			1a6e8c: R_ARM_ABS32	_u4BypassNptvMloop
			1a6e90: R_ARM_ABS32	fgApplyScanPWMSetData
  1a6e94:	00059558 	andeq	r9, r5, r8, asr r5
			1a6e94: R_ARM_ABS32	.bss
	...
			1a6e98: R_ARM_ABS32	u1ScanPwmCrossFlg
			1a6e9c: R_ARM_ABS32	_arScalePrm
			1a6ea0: R_ARM_ABS32	_Lvds7To4FifoReset
			1a6ea4: R_ARM_ABS32	fgScanPWMSetpControl

Disassembly of section .text.unlikely:

Disassembly of section .init.text:

Disassembly of section .exit.text:
