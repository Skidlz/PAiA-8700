;*********************************
;*                               *
;*         PINK TUNES            *
;*                               *
;*     A COMPOSING PROGRAM       *
;*    FOR FOUR PART HARMONIES    *
;*                               *
;*     BY JOHN S SIMONTON, JR    *
;*(C) 1978 PAIA ELECTRONICS, INC *
;*********************************
;
KBD		= $0810
DISP	= $0820
INIT	= $0D21
NOTE	= $0D2B
DECD	= $0F00
BRAK	= $FFC0		;BREAK ROUTINE IN PIEBUG

	org	$0000
;
;FIRST ATTEND TO HOUSKEEPING--
;
BEG		jmp BRAK		;BREAK VECTOR
STAR    jsr INIT		;SETUP SYNTH - MUS1
        lda KBD			;INITIALIZE RANDOM
        sta <NTMP+01	;NUMBER GENERATOR
LOOP    jsr SET			;INIT PINK TUNES
LP0     jsr NOTE		;PLAY NOTE, READ AGO
;
;CHECK FOR ADDITION TO CANDIDATE
;NOTE TABLE
;
MAIN    lda <KTBL+08	;ANY KEYS DOWN?
        beq OUT1		;NO-CHECK FOR TIME OUT
        cmp <TEMP		;YES-A NEW KEY?
OUT1    sta <TEMP		;SAVE FOR NEXT TIME
        beq OUT			;BRANCH IS SAME KEY
;
        ldx #$10		;IF NEW KEY SHIFT
LP3     ldy <NBUF-1,x	;ALL 16 CANDIDATES
        sta <NBUF-1,x	;DOWN BY ONE
        tya
        dex
        bne LP3			;NOT DONE-LOOP
;
;NOW CHECK FOR CLOCK TIME OUT
;
OUT     lda <CLCK		;GET MASTER CLOCK
        bne TEST		;AND IF TIMES OUT
        lda <TMPO		;SET TO TEMPO VALUE
        sta <CLCK		;CALL SUB FOR NEW
        jsr ALOC		;NOTES (IF NEEDED)
        lda <LNTH		;GET CYCLE STATUS
        sta DISP		;SHOW IT AND IF ZERO
        beq TEST		;CYCLE IS COMPLETE
        dec <LNTH		;IF NOT DONE, DCRMNT
        bne TEST		;IF NOT ZERO NOWLEAVE
        jsr SET			;IF ZERO, REINIT
        jsr ALOC		;GET FIRST NOTES AND
        beq LP0			;BRANCH ALWAYS TO PLAY
TEST    jsr DECD		;GET A COMMAND - MUS-1
        bne TST2		;NOT ZERO, NEXT TEST
        ldx #$03		;COMMAND 0, NEW TUNE
                        ;SET POINTER/COUNTER
TST1    jsr RNDM		;GET RANDOM NUMBER
        sta <NTMP,x		;NEW INITIAL RANDOM
        dex				;POINT TO NEXT
        bne TST1		;NOT DONE - LOOP
        beq LOOP		;BRANCH ALWAYS
TST2    cmp #$01		;COMMAND 1, TUNEING
        bne TST4		;NOT 1, TEST NEXT
        ldx #$04		;4 OUTPUT BUFFERS
        lda #$5C		;PUT MIDDLE C IN ALL
TST3    ;sta NT0B,x  	;OUTPUT BUFFERS
		db $9D, $DB, $00 ;force addressing mode
        dex
        bne TST3		;NOT DONE-LOOP
        beq LP0			;BRANCH ALWAYS
TST4    cmp #$02		;COMMAND 2, STOP
        bne LP0			;NO COMMAND - LOOP
        jsr SET			;CALL TO ZERO OUT-BUFFS
        jsr NOTE		;THEN MUTE SYNTHESIZER
        brk				;AND RETURN TO PIEBUG
;
;RAM contents start----------------------------------------
;
		db	$08, $3A, $BF, $0C, $0C, $BF, $BF, $0C
		db	$08, $BF, $BF, $0C, $18, $BF, $BF, $20
		db	$08, $B7, $C9, $D0, $F1, $85, $A0, $EA
		db	$EA
TIME	db	$02, $04, $01, $01
MASK	db	$F2, $F0, $F3, $F3
NBUF	db	$5A, $5D, $5F, $62, $64, $62, $5F, $5D
		db	$5A, $58, $56, $53, $51, $53, $56, $58
		
RND0	db	$00, $00, $00, $00
NOIS	db	$00, $00, $00, $00
LNTH	db	$FA
TMPO	db	$FA
;MUS-1-----------------------------------------------------
LAST	db	$80, $80, $80, $80, $80, $80, $80, $80
		db	$80, $80, $80, $80, $80, $80, $80, $80
ATCK	db	$A2
DCY		db	$3F
SUST	db	$20
RLS		db	$21
PEAK	db	$01
NTB7
CLCK	db	$AE
TTBL	db 	$00, $00, $00
NTBB	db	$00, $00, $00, $00, $00, $00, $00, $00
		db	$00, $00, $00, $00
NTMP	db	$00, $00, $00, $00, $00, $00, $00, $00
		db	$00, $00, $00, $00
NT0B	db	$00, $00, $00, $00
KTBL	db	$00, $00, $00, $00, $00, $00, $00, $00
		db	$00
CTRL	db	$00
ODLY	db	$20
OUTS	db	$04
OUTT	db	$04
TEMP	db	$00
MSTACK	db	$FF
;POTSHOT---------------------------------------------------
CHKSUM	db	$B3
STATUS	db	$FF
COMAND	db	$DD
IDENT	db	$02
ENDADR	db	$FF, $01
BEGADR	db	$00, $00
PNTER	db	$F6, $00
;PIEBUG----------------------------------------------------
LASTKE	db	$16
ACC		db	$82
YREG	db	$00
XREG	db	$00
PC		db	$6E, $00	;Program counter
STACKP	db	$FF			;Stack pointer (user)
PREG	db	$00			;Stack register
;
;      RANDOM NUMBER GENERATOR
;
;ESSENTIALLY A 22 BIT LONG SHIFT
;REGISTER WITH EX-0R TAPS AT
;STAGES 22 AND 21 FED BACK TO
;INPUT.
;
RNDM    txa				;SAVE X
        pha
        lda <NOIS+1		;LAST BYTE S/R
        asl a			;ALIGN BITS 22 &
        eor <NOIS+1		;21 AND DO EX-OR
        asl a			;THEN SHIFT RE-
        asl a			;SULT TO CARRY
        asl a
        ldx #$03		;SET UP PNT/CNT
LP1     rol <NOIS,x		;AND SHIFT 3 BYTE
        dex				;SHIFT REGISTER
        bne LP1			;BY ONE BIT LEFT
        pla				;WHEN DONE RE-
        tax				;STORE X REG.
        lda <NOIS+03	;AND LEAVE WITH
        rts				;WITH NO. IN ACC.
;
;      NEW NOTE
;
;TAKES CARE OF PICKING PINK NOTE
;FROM CANDIDATE NOTE TABLE AND
;CALCULATES AND UPDATES NOTE TIMERS
;NOTE THAT Y POINTS TO CHANNEL FOR
;UPDATE
;
NWNT    ldx #$05		;SET UP PNT/CNT
        lda <OUTS		;GET COPY PINKING
        dec <OUTS		;COUNTER,DEC ORIGINAL
        eor <OUTS		;PATTERN OF CHANGED
        sta <OUTT		;BITS - SAVE CHANGES
        lda #$00		;PREPARE TO SUM DICE
NW1     lsr <OUTT		;CHECK FOR CHANGED
        bcc NW2			;BIT - IF CHANGED
        pha				;SAVE CURRENT TOTAL
        jsr RNDM		;GET RANDOM NUBMER
        and #$03		;MAKE RANGE FROM 0 T0 3
        sta <RND0-1,x	;SAVE VALUE FOR NEXT
        pla				;RECOVER TOTAL
        clc				;PREPARE ADDITION
NW2     adc <RND0-1,x	;ADD VALUE OF DIE
        dex				;POINT TO NEXT
        bne NW1			;LOOP IF NOT DONE
        tax				;USE TOTAL AS POINTER
        lda <NBUF,x		;GET CANDIDATE
        beq DURA		;ZERO, DO NOTE CHANGE
        sta NTB7,y		;PLACE IN TEMP BUFFER
DURA    lda <NOIS+01	;A CHEAP RANDOM NUMBER
        clc				;PREPARE
        and MASK-1,y	;MASK DURATION VAL.
        adc TIME-1,y	;ADD MINIMUM VAL.
        and #$0F		;AND MASK RESULT
        tax				;USE AS COUNTER AND
        lda #$01		;DO DURATIONS AS
NT2     rol a			;POWERS OF 2. CARRY
        dex				;SET DOTS NOTE
        bne NT2			;NOT DONE - LOOP
        sta NTBB,y		;PUT RESULT IN NOTES
        rts				;TIMER AND RETURN
;
;      ALLOCATION 0151
;SEES IF NEW NOTES ARE NEED AND IF
;SO GETS THEM.  ALSO CLEARS TRIGGER
;OF NOTE OUTPUT ONCE IT is PLAYED.
;
ALOC	ldx #$04		;DO 4 NOTE CHANNELS
LP6     dec <NTBB,x		;DECREMENT NOTE TIMER
        bne LP5			;AND IF TIME OUT
        txa				;TRANSFER X REG. TO
        tay				;TO Y
        jsr NWNT		;AND GET NEW NOTE
        tya				;AND DURATION AND
        tax				;RESTORE X
LP5     dex				;DECRIMENT COUNTER
        bne LP6			;IF NOT DONE - LOOP
        ldx #$04		;AGAIN, FOUR CHANNELS
AL1     lda <NTB7,x		;GET NOTE FROM TEMP
        sta <NT0B,x		;BUFFER, SAVE IN OUT
        and #$3F		;BUFFER, CLEAR FLAG
        sta <NTB7,x		;PUT BACK IN TEMP.
        dex				;POINT TO NEXT
        bne AL1			;NOT DONE - LOOP
        rts				;DONE, RETURN
;
;            SET
;
;PREPARES KNOWN START POINT FOR
;CYCLIC TUNES.
;
;
SET		lda #$00		;TO ZERO THINGS WITH
        ldy #$01		;PRESET FOR NOTE CNTRS
        ldx #$04		;DO 4 CHANNLES
LP10    sta <NT0B,x		;ZERO OUT-BUFFERS
        sta <RND0,x		;ZERO 4 DICE
        sty <NTBB,x		;PRESET NOTE TIMERS
        pha				;SAVE THE ZERO
        lda <NTMP,x		;SET UP RNDM'S S/R
        sta <NOIS,x		;AND CYCLE COUNTER
        pla				;RECOVER ZERO
        dex				;POINT TO NEXT
        bne LP10		;NOT DONE - LOOP
        sta <RND0		;ZERO 5TH DIE
        sta <OUTS		;ZERO PINKING COUNTER
        rts				;AND RETURN
;
;RAM contents start----------------------------------------
		db	$04, $B7, $B7, $04, $04, $B7, $B7, $04
		db	$04, $B7, $B7, $04, $04, $B7, $B7, $04
		db	$04, $B7, $B7, $04, $04, $B7, $00, $B5
		db	$F7, $00, $B5, $F7, $00, $B5, $F7, $00
		db	$B5, $F7, $00, $B5, $F7, $00, $B5, $F7
		db	$00, $B5, $F7, $00, $B5, $F7, $00, $B5
		db	$F7, $00, $B5, $F7, $00, $B5, $F7, $00
		db	$B5, $F7, $00, $B5, $F7, $00, $B5, $F7
		db	$00, $B5, $F7, $00, $B5, $F7, $00, $B5
		db	$F7, $00, $B5, $F7, $00, $B5, $F7, $00
		db	$B5, $F7, $00, $B5, $F7, $00, $B5, $F7
		db	$00, $B5, $F7, $00, $B5, $F7, $00, $B5
		db	$F7, $00, $B5, $F7, $00, $B5, $00, $0B
		db	$3D, $21, $0E, $41, $0E, $01, $01, $79
		db	$0E, $C3, $0E, $14, $0E
		
		end
		