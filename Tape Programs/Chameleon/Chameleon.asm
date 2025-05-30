; CHAMELEON 0.25
; Control System For 8700 Based Synthesizers
; By Jon Ballera
; July 1979

	org $0200
KTBL	=$CF	;MUS1 NTBL variable
OUTS	=$EA	;MUS1 variable
DSPY	=$0820	;LED DISPLAY

POLY	=$0D71	;MUS1 function
INIT	=$0D21	;MUS1 function
TRNGN	=$0DC3	;MUS1 TRGN function
NOTES	=$0D2B	;MUS1 NOTE function
FILL	=$0D52	;MUS1 function
DECD	=$0F00	;PIEBUG DECODE function


INIT0	jsr INIT	;CLEAR KTBL,NTBL,TTBL
		bcc POLY1	;BRANCH ALWAYS POLY
INIT1	lda #$00	;PREP TO ZERO
		ldx #$10	;SET POINTER
ZBUF	sta KTBL,x	;ZERO BUFFER
		dex			;POINT TO NEXT
		bne ZBUF	;LOOP IF NOT DONE
		rts			;BACK TO VOXTS
		
POLY1	jsr POLY	;ASSIGN NOTES
		jsr TRNGN	;CALL STG's, IF ON
		jsr NOTES	;PLAY NOTES
		jsr DECD	;READ 8700 KBD
		cmp #$01	;IT TUNE DOWN?
		bcc INIT0	;NO,IT'S LESS,GO CLEAR
		bne VOXT1	;GO TO VOXT 1
		ldy #$5C	;PREP FOR TUNE
		jsr FILL	;PUT NOTE IN ALL VOXT
		beq POLY1	;PLAY TUNING NOTE
VOXT1	cmp #$04	;IS $04 DOWN?
		bne VOXT2	;NO, GO TO VOXT 2
		lda #$01	;YES, PREP 1 VOXT
		sta OUTS	;PUT IN OUTS
		sta DSPY	;SHOW VOX NUMBER
		jsr INIT1	;CLEAR NTBL
VOXT2	cmp #$05	;IS $05 DOWN?
		bne VOXT3	;NO,TO VOXT 3
		lda #$02	;YES, PREP 2 VOX
		sta OUTS	;PUT IN OUTS
		sta DSPY	;SHOW VOX NUMBER
		jsr INIT1	;CLEAR NTBL
VOXT3	cmp #$06	;IS $06 DOWN?
		bne VOXT4	;NO, TO VOXT 4
		lda #$03	;YES, PREP 3 VOX
		sta OUTS	;PUT IN OUTS
		sta DSPY	;SHOW VOX NUMBER
		jsr INIT1	;CLEAR NTBL
VOXT4	cmp #$07	;IS $07 DOWN?
		bne GLDT1	;NO, TO GLDT 1
		lda #$04	;YES, PREP 4 VOX
		sta OUTS	;PUT IN OUTS
		sta DSPY	;SHOW VOX NUMBER
		jsr INIT1	;CLEAR NTBL
GLDT1	cmp #$08	;IS $08 DOWN?
		bne GLDT2	;NO, TO GLDT 2
		lda #$80	;YES, PREP GLIDE
		sta $CF		;PUT IN XPOSE CH 1
GLDT2	cmp #$09	;IS $09 DOWN?
		bne GLDT3	;NO, TO GLDT 3
		lda #$80	;YES, PREP GLIDE
		sta $CE		;PUT IN XPOSE CH 2
GLDT3	cmp #$0A	;IS $0A DOWN?
		bne GLDT4	;NO, TO GLDT 4
		lda #$80	;YES, PREP GLIDE
		sta $CD		;PUT IN XPOSE CH 3
GLDT4	cmp #$0B	;IS $0B DOWN?
		bne TTST1	;NO, TO TTST 1
		lda #$80	;YES, PREP GLIDE
		sta $CC		;PUT IN XPOSE CH 4
TTST1	cmp #$0C	;IS $0C DOWN?
		bne TTST2	;NO, TO TTST 2
		lda #$0C	;YES, PREP XPOSE
		sta $CF		;PUT IN XPOSE CH 1
TTST2	cmp #$0D	;IS $0D DOWN?
		bne TTST3	;NO, TO TTST 3
		lda #$0C	;YES, PREP XPOSE
		sta $CE		;PUT IN XPOSE CH 2
TTST3	cmp #$0E	;IS $0E DOWN?
		bne TTST4	;NO, TO TTST 4
		lda #$0C	;YES, PREP XPOSE
		sta $CD		;PUT IN XPOSE CH 3
TTST4	cmp #$0F	;IS $0F DOWN?
		bne RETURN	;NO, TO RETURN
		lda #$0C	;YES, PREP XPOSE
		sta $CC		;PUT IN XPOSE CH 4
RETURN	jmp POLY1	;DO IT AGAIN
