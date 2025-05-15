;POLY 1.0
;written by John S. Simonton, Jr.
;(c) 1978 PAiA Electronics, Inc.
;All rights reserved.

DECODE	= $FF00 ;PIEBUG function

SH		= $09F7	;QuASH
DAC		= $0900 ;8780/8781 DAC
KBD		= $0810 ;8782 or EK-3 Keyboard
DISP	= $0820 ;hex display

KTABLE	= $D0	;input buffer D0-D7
NTABLE 	= $D8	;output buffer D8-DF
TTABLE	= $E0	;transpose table E0-E7

CLK		= $E8
TEMP1	= $E9
OUTS	= $EA 	;number of synth chans (max 8)
OUTTEMP	= $EB

	org $0006
;
;INIT clears input buffer KTABLE, OUTPUT
;buffer NTABLE and traspose BUFFER
;TTABLE
;
INIT	lda #$00		;prepare
INIT1	ldx #$18
INIT0	sta KTABLE-1,x	;clear everything
		dex
		bne INIT0		;loop until done
		
;
;NOTEOUT adds together corresponding
;entries in TTABLE and NTABLE and
;reads the result into the control channels
;in descending order.  Also takes care
;of timing to D/A
;
NOTEOUT	ldx #$08		;initialize pointer
LOOP	lda NTABLE-1,x	;get note
		clc				;prepare
		adc TTABLE-1,x	;add transpose
		sta DAC			;write to D/A, settle
		sta SH,x 		;write control channel
		ldy #$04		;prepare delay time
LOOP1	dey				;delay
		bne LOOP1
		dex				;done?
		bne LOOP		;no, continue
;
;LOOK clears input buffer and waits for
;keyboard scan to begin.  Places keys down
;in the input buffer.  This routine Also
;serves to make the keyboard's encoder
;clock the tempo clock for the entire
;system.
;
LOOK	ldx #$08		;set pointer/counter
		lda #$00		;prepare accum.
LK0		sta KTABLE-1,x	;zero input buffer
		dex				;point to next
		bne LK0			;done?  no-loop
		ldx #$08		;yes set pointer
LK1		bit KBD			;scan started?
		bmi LK1			;no D7 high, loop
LK2		bit KBD			;yes-look again
		bmi LOUT		;when scan done, leave
		bvc LK2			;if key not down, loop
		lda KBD			;get the key
		sta KTABLE-1,x	;put it in input buffer
LK3		cmp KBD			;still same key?
		beq LK3			;yes,loop
		dex				;advance pointer
		bne LK2			;if some buffer left, loop
LOUT	inc	CLK			;increment clock
		lda CLK			;get it
		sta DISP		;show it
		nop				;hook
		nop
		nop
;
;POLY first half of allocation algorythm
;as explained in text.  In this block de-
;activated channels are re-activate if the
;data they contain appears in the INPUT
;buffer.
;
POLY	lda OUTS		;number of output
		sta OUTTEMP		;channels to counter
		ldx #$08		;set up a counter
LOOPY0	lda #$BF		;prepare for following:
		and NTABLE-1,x	;clear trigger bit of note
		sta NTABLE-1,x	;and put it back
		dex				;pointer to next note
		bne LOOPY0		;if not yet done, loop
		lda #$09		;prepare
		sta TEMP1		;set up pointer to
						;KTABLE
LOOPY1	dec TEMP1		;decrement the pointer
		beq NEWKEY		;if done go to newkey
		ldx	TEMP1		;prepare x pointer
		ldy KTABLE-1,x	;get key in Y register
		beq NEWKEY		;no keys left, place new
						;keys
		ldx #$09		;initialize pointer to
						;NTABLE
LOOPY2	dex				;decrement pointer
		beq LOOPY1		;if all NTABLE done,
						;get new key
		tya				;copy of next ket to ac.
		eor NTABLE-1,x	;compare to NTABLE
		asl a			;and shift high order
		asl a			;bits out to ignore
		bne LOOPY2		;if diff., get next NTABLE
		tya				;if same, key to ac.
		ora NTABLE-1,x	;and preserve glide
		sta NTABLE-1,x	;and save note
		dec OUTTEMP		;one less output available
		beq OUT			;if none remain, leave
		ldx TEMP1
		lda #$00		;prepare accumulator
		sta KTABLE-1,x	;(and then zero this key
		beq LOOPY1		;then branch always
						;for more
;
;KEWKEY second half of allocation algorhythm.
;Keys down are allocated to output BUFFER
;locations wich are currently de-activated.
;NOTE that both this routine and POLY
;preserve the status of D7 in the OUTPUT
;buffer locations.
;
NEWKEY	lda #$00		;prepare accum.
		ldx #$09		;prepare pointer
NK3		dex				;to KTABLE, decrement
		beq OUT			;if done, leave
		ldy KTABLE-1,x	;key to Y-reg.
		beq NK3			;if key zero, get next key
		sta KTABLE-1,x	;a key that needs a
						;home
						;zero the key in KTABLE
		ldx #$09		;prepare pointer
NK4		dex				;decrement
		beq OUT			;if zero, no NTABLE
						;left
		lda #$40		;otherwise prepare a
						;mask
		and NTABLE-1,x	;and check for free
						;NTABLE entry (D6 0)
		bne NK4			;not this one
		lda #$80		;yes-now prepare a mask
		and NTABLE-1,x	;D7 set on clear
		sta NTABLE-1,x	;put back in NTABLE
		tya				;copy key to accum,
		ora NTABLE-1,x	;set/clear D7
		sta NTABLE-1,x	;and back to NTABLE
		dec OUTTEMP		;one less output avail-
						;able
		beq OUT			;if none remaining, out.
		bne NEWKEY		;otherwise, branch always
						;for more
;
;OPTION uses PIEBUG's DECODE sub-
;routine to read computer keyboard and
;take appropriate action as required.
;
OUT
OPTION	jsr DECODE 		;get command
		cmp #$04		;greater than 4?
		bcs OP1			;yes test next
		jmp INIT		;no-clear all
OP1		cmp #$08		;greater than 8?
		bcs OP2			;yes test next
		lda #$2E		;no prepare
		jmp INIT1		;go to tune
OP2		jmp NOTEOUT		;run full poly
