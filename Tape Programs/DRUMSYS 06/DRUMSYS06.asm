;
;
;*********************************
;*                               *
;*          DRUMSYS 0.6          *
;*                               *
;*   8700/EK-2 DRUM OPERATING    *
;*            SYSTEM             *
;*              BY               *
;*         JOHN SIMONTON         *
;*                               *
;*(C) 1978 - PAIA ELECTRONICS,INC*
;*                               *
;*********************************
;
BUFF	= $00F0
CNTR	= $00EC
EXP		= $00EB
TMPO	= $00EA
PNTR	= $00E9
DSP		= $0820
DECD	= $FF00
BEEP	= $0F22
SCOR	= $0100
DUMY	= $0086
OUTP	= $0840
SNBT	= $0E25
CASS	= $0EAA
;---------------------
;00E8
;    S-TABLE (CONTROL CODES)
;00E1
;---------------------
STBL	=$00D1
;---------------------
;00E0
;    DRUM SIGNATURES
;00D9
;---------------------
;*********************************
		org $10D2 ;org $10D1
;*********************************
;
TAPE	db	$FF, $00, $80, $01, $00, $01, $00, $01
DSIG	db	$FF, $FE, $FD, $F3, $F7, $EF, $DF, $BF
CRL		db	$6A, $9D, $8D, $87, $7C, $B2, $B9, $CD, $00, $08, $20
;
		org $10ED
PARM	db	$FF
		org $10F6
PAR1	db $F6, $F7, $F8, $F9, $FA, $FB, $FC, $FD, $FF, $00
;*********************************
		org $1000
;*********************************
;
SPHK	lda	#$86	;SPARE HOOK KEYS 8-F3
		sta	<ACTN+01;USED ONLY TO RE-START
		nop			;SYTEM.  IN LATER VERSIONS
		nop			;WILL PROVIDE ADDITTIONAL
;					 FEATURES
;
STAR	lda	#$00	;PREPARE ACCUMULATOR AND
		sta	<PNTR	;ZERO SCORE POINTER
 		sta	DSP		;AND DISPLAYS
		tax			;PREPARE X REG AS POINTER
SLP0	sta	SCOR,x	;AND USE IT TO CLEAR SCORE
		inx
		bne	SLP0	;LOOP UNTIL DONE
SLP1	jsr	RDKY	;GO READ THE KEYBOARD, ETC.
		bcs	ACTN	;AND IF NO NEW KEYS, BRAND
		cmp	#$10	;NEW KEY - A "CONTROL" KEY?
		bcs	CTRL	;YES - BRANCH TO CONTROL
		cmp	#$08	;ONE OF "SPARE" KEYS?
		bcs	SPHK	;YES- BRANCH
; 		**
NTRY	lda	#$86	;DRUM ENTRY MODE, GET LINK
		sta	<ACTN+01
 		lda	DSIG,y
		ldx	<PNTR
 		sta	SCOR,x
 		jsr	PLAY
 		jmp	SLP1
CTRL	lda	STBL,y
		sta	<ACTN+01
ACTN	jsr	DUMY
 		jmp	SLP1
;
;PLAY SUBROUTINE
;
PLAY	ldy	<EXP
		sta	OUTP
		and	#$7F
PLA0	dey
		bne	PLA0
 		sta	OUTP
		inc	<PNTR
		ldx	<PNTR
 		stx	DSP
		rts
;
;READ KEY-ALSO IMPORTANT TO TEMPO
;
RDKY	jsr	DECD
		bcs	DLY
		ldx	#$00
		stx	<CNTR
		rts
DLY		ldx	#$20
NXTX	ldy	#$3F
DELY	dey
		bne	DELY
		dex
		bne	NXTX
		inc	<CNTR
		rts
;
;RUN SUBROUTINE
;
;		**
RUN		lda	#$7C		;WAIT pointer
		sta	lo ACTN+01
CYCL	lda	#$00
		sta	<PNTR
CONT	ldx	<PNTR
 		lda	SCOR,x
		beq	CYCL
		jsr	PLAY
		lda	<CNTR
		eor	<TMPO
		bne	RETN
		sta	<CNTR
		beq	CONT
RETN	rts
;
;SINGLE STEP SUBROUTINE
;
;		**
STEP	lda	#$86		;RETN pointer
		sta	lo ACTN+01
		bne	CONT
;
;BACKSPACE SUBROUTINE
;
;		**
BACK	lda	#$96		;NEXT pointer
		sta	lo ACTN+01
		dec	<PNTR
		bne	CONT
		rts
;
NEXT	lda	#$86		;RETN pointer
		sta	lo ACTN+01
		dec	<PNTR
		rts
;
;TEMPO;
;
;
TMP		lda	#$A5		;NXT2 pointer
		sta	lo ACTN+01
		lda	#$00
		sta	<TMPO
NXT2	inc <TMPO
		rts
;
;SET UP FOR TAPE TRANSFER
;
STTP	ldx	#$07
STP		lda	$D2,x ;TAPE
		sta	BUFF,x
		dex
		bne	STP
		rts
;
;TAPE IN AND OUT ROUTINES
;
TOUT	jsr	STTP
		lda	#$DD
		bne	DO
TIN		jsr	STTP
		lda	#$11
DO		jsr	SNBT
 		jsr	CASS
		;		**
		lda	#$86		;RETN pointer
		sta	lo ACTN+01
		clc
 		jsr	BEEP
		rts
;
;STROBE DRUM EFFECT
;
STRB	dec	<PNTR
 		jmp	CONT
				;
				;
				;
				;
				end