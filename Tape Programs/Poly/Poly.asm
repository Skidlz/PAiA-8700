;POLY 1.0
;By John S. Simonton, Jr.
;1978 PAiA Electronics, Inc

DECODE	=$FF00 ;PIEBUG

DAC		=$0900 ;MUS-1
KBD		=$0810 ;MUS-1
DISP	=$0820 ;MUS-1
NTBL	=$CF ;MUS-1
KTBL	=$DF ;MUS-1
CTRL	=$E8 ;MUS-1
ODLY	=$E9 ;MUS-1
OUTS	=$EA ;MUS-1
OUTT	=$EB ;MUS-1

	org $0006

START
	lda #$00
L008
	ldx #$18
L00A
	sta NTBL,x
	dex
	bne L00A
L00F
	ldx #$08
L011
	lda $D7,x
	clc
	adc KTBL,x
	sta DAC
	sta $09F7,x ;?
	ldy #$04
L01E
	dey
	bne L01E
	dex
	bne L011
	ldx #$08
	lda #$00
L028
	sta NTBL,x
	dex
	bne L028
	ldx #$08
L02F
	bit KBD
	bmi L02F
L034
	bit KBD
	bmi L048
	bvc L034
	lda KBD
	sta NTBL,x
L040
	cmp KBD
	beq L040
	dex
	bne L034
L048
	inc	CTRL
	lda CTRL
	sta DISP
	nop
	nop
	nop
	lda OUTS
	sta OUTT
	ldx #$08
L058
	lda #$BF
	and $D7,x
	sta $D7,x
	dex
	bne L058
	lda #$09
	sta ODLY
L065
	dec ODLY
	beq L08C
	ldx	ODLY
	ldy NTBL,x
	beq L08C
	ldx #$09
L071
	dex
	beq L065
	tya
	eor $D7,x
	asl a
	asl a
	bne L071
	tya
	ora $D7,x
	sta $D7,x
	dec OUTT
	beq L0B5
	ldx ODLY
	lda #$00
	sta NTBL,x
	beq L065
L08C
	lda #$00
	ldx #$09
L090
	dex
	beq L0B5
	ldy NTBL,x
	beq L090
	sta NTBL,x
	ldx #$09
L09B
	dex
	beq L0B5
	lda #$40
	and $D7,x
	bne L09B
	lda #$80
	and $D7,x
	sta $D7,x
	tya
	ora $D7,x
	sta $D7,x
	dec OUTT
	beq L0B5
	bne L08C
L0B5
	jsr DECODE ;PIEBUG
	cmp #$04
	bcs L0BF
	jmp START
L0BF
	cmp #$08
	bcs L0C8
	lda #$2E
	jmp L008
L0C8
	jmp L00F
	