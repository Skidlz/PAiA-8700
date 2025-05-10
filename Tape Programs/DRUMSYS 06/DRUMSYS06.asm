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
STBL	= $00D1
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
PAR1	db	$F6, $F7, $F8, $F9, $FA, $FB, $FC, $FD, $FF, $00
;*********************************
		org $1000
;*********************************
;
SPHK	lda	#$86		;SPARE HOOK KEYS 8-F3
		sta	<lo ACTN+01	;USED ONLY TO RE-START
		nop				;SYTEM.  IN LATER VERSIONS
		nop				;WILL PROVIDE ADDITTIONAL
;						 FEATURES
;
STAR	lda	#$00		;PREPARE ACCUMULATOR AND
		sta	<lo PNTR	;ZERO SCORE POINTER
 		sta	DSP			;AND DISPLAYS
		tax				;PREPARE X REG AS POINTER
SLP0	sta	SCOR,x		;AND USE IT TO CLEAR SCORE
		inx
		bne	SLP0		;LOOP UNTIL DONE
SLP1	jsr	RDKY		;GO READ THE KEYBOARD, ETC.
		bcs	ACTN		;AND IF NO NEW KEYS, BRAND
		cmp	#$10		;NEW KEY - A "CONTROL" KEY?
		bcs	CTRL		;YES - BRANCH TO CONTROL
		cmp	#$08		;ONE OF "SPARE" KEYS?
		bcs	SPHK		;YES- BRANCH
; 		**
NTRY	lda	#$86		;DRUM ENTRY MODE, GET LINK
		sta	<lo ACTN+01	;SET LINK
 		lda	DSIG,y		;GET DRUM SIGNATURE
		ldx	<lo PNTR	;GET SCORE POINTER
 		sta	SCOR,x		;SAVE DRUM SIG IN SCORE
 		jsr	PLAY		;PLAY THE DRUM BEAT
 		jmp	SLP1		;LOOP FOR MORE
CTRL	lda	STBL,y		;GET COMMAND ADDRESS LINK
		sta	<lo ACTN+01;AND SET LINK IN JSR DUMY
ACTN	jsr	DUMY		;AND GO TO COMMAND SUBROUTINE
 		jmp	SLP1		;THEN LOOP FOR MORE
;
;PLAY SUBROUTINE
;
PLAY	ldy	<lo EXP		;GET EXPRESSION VARIABLE
		sta	OUTP		;OUTPUT CONTROL TO EK-2
		and	#$7F		;RESET STROBE BIT
PLA0	dey				;DELAY FOR THE EXP. TIME
		bne	PLA0		;LOOP UNTIL DONE
 		sta	OUTP		;AND TURN DRUM "OFF"
		inc	<lo PNTR	;INCREMENT SCORE POINTER
		ldx	<lo PNTR	;PLACE IN X REGISTER
 		stx	DSP			;AND SHOW IN DISPLAYS
		rts				;THEN RETURN
;
;READ KEY-ALSO IMPORTANT TO TEMPO
;
RDKY	jsr	DECD		;PIEBUG KEYBOARD SUBROUTINE
		bcs	DLY			;SAME KEY - JUST DELAY
		ldx	#$00
		stx	<lo CNTR	;ZERO TEMPO COUNTER
		rts
DLY		ldx	#$20		;SET X AN Y REGISTER
NXTX	ldy	#$3F		;DELAY PARAMETERS
DELY	dey				;AND DO DELAY
		bne	DELY
		dex
		bne	NXTX		;LOOP UNTIL DONE
		inc	<lo CNTR	;INCREMENT TEMPO COUNTER
		rts				;AND RETURN
;
;RUN SUBROUTINE
;
;		**
RUN		lda	#lo WAIT	;COMMAND LINK TO "WAIT"
		sta	<lo ACTN+01	;SET COMMAND LINK
CYCL	lda	#$00		;PREPARE AND SET
		sta	<lo PNTR	;SCORE POINTER TO 0
CONT	ldx	<lo PNTR	;GET CURRENT SCORE POINTER
 		lda	SCOR,x		;GET CURRENT DRUM SIGNATURE
		beq	CYCL		;ZERO, END OF SCORE-BRANCH
		jsr	PLAY		;GO PLAY DRUM SOUND, ETC.
WAIT	lda	<lo CNTR	;GET TEMPO COUNTER AND
		eor	<lo TMPO	;COMPARE TO TEMPO VARIABLE
		bne	RETN		;IF NOT TIMED OUT, RETURN
OCNT	sta	<lo CNTR	;TIMED OUT - ZERO COUNTER
		beq	CONT		;BRANCH ALWAYS TO PLAY, ETC
RETN	rts				;RETURN
;
;SINGLE STEP SUBROUTINE
;
;		**
STEP	lda	#lo RETN	;COMMAND LINK TO "RETN"
		sta	<lo ACTN+01	;SET COMMAND LINK
		bne	CONT		;BRANCH ALWAYS TO PLAY, ETC.
;
;BACKSPACE SUBROUTINE
;
;		**
BACK	lda	#lo NEXT	;COMMAND LINK TO "NEXT"
		sta	<lo ACTN+01	;SET COMMAND LINK
		dec	<lo PNTR	;SCORE POINTER BACK ONE
		bne	CONT		;GO PLAY SCORE, ETC.
		rts				;AND RETURN
;		**
NEXT	lda	#lo RETN	;COMMAND LINK TO "RETN"
		sta	<lo ACTN+01	;SET COMMAND LINK
		dec	<lo PNTR	;SCORE POINTER BACK ONE
		rts				;RETURN
;
;TEMPO
;
;		**
TMP		lda	#lo NXT2	;COMMAND LINK TO "NXT2"
		sta	<lo ACTN+01	;SET COMMAND LINK
		lda	#$00		;INITIALIZE TEMPO COUNTER
		sta	<lo TMPO	;AND START COUNTIN
NXT2	inc <lo TMPO	;UNTIL NEXT COMMAND
		rts				;RETURN
;
;SET UP FOR TAPE TRANSFER
;
STTP	ldx	#$07		;TRANSFER SEVEN BYTES
STP		lda	<lo TAPE,x 	;GET PARAMETER
		sta	BUFF,x		;PLACE PARAMETER
		dex				;POINT TO NEXT
		bne	STP			;LOOP UNTIL ALL TRANSFERED
		rts				;THEN RETURN
;
;TAPE IN AND OUT ROUTINES
;
TOUT	jsr	STTP		;SET UP PARAMETERS
		lda	#$DD		;SET DUMP "SWITCH"
		bne	DO			;BRANCH ALWAYS
TIN		jsr	STTP		;SET UP PARAMETERS
		lda	#$11		;SET LOAD "SWITCH"
DO		jsr	SNBT		;TURN ON RELAYS
 		jsr	CASS		;DO CASSETTE ROUTINE
;		**
		lda	#lo RETN	;COMMAND LINK TO "RETN"
		sta	<lo ACTN+01	;SET LINK
		clc				;PREPARE FOR BEEP
 		jsr	BEEP		;TURN OFF RELAYS AND BEEP
		rts				;AND RETURN
;
;STROBE DRUM EFFECT
;
STRB	dec	<lo PNTR	;PREPARE TO GET SAME DRUM
 		jmp	CONT		;PLAY DRUM
;
;
;
;
	end