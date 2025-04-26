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
KBD		=$0810
DISP	=$0820
INIT	=$0D21
NOTE	=$0D2B
DECD	=$0F00
BRAK	=$FFC0		;BREAK ROUTINE IN PIEBUG

TIME	=$0087
MASK	=$008B
CLCK	=$00BF
NTB7	=$00BF
NTBB	=$00C3
NTMP	=$00CF
NT0B	=$00db
KTBL	=$00DF
OUTS	=$00EA
OUTT	=$00EB
TEMP	=$00EC		;TEMPORARY STORAGE

	org	$0000
;
;FIRST ATTEND TO HOUSKEEPING--
;
BEG		jmp BRAK		;BREAK VECTOR
STAR    jsr INIT		;SETUP SYNTH - MUS1
        lda KBD			;INITIALIZE RANDOM
        sta NTMP+01		;NUMBER GENERATOR
LOOP    jsr SET1		;INIT PINK TUNES
LP0     jsr NOTE		;PLAY NOTE, READ AGO
;
;CHECK FOR ADDITION TO CANDIDATE
;NOTE TABLE
;
MAIN    lda KTBL+08		;ANY KEYS DOWN?
        beq OUT1		;NO-CHECK FOR TIME OUT
        cmp TEMP		;YES-A NEW KEY?
OUT1    sta TEMP		;SAVE FOR NEXT TIME
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
        jsr SET1		;IF ZERO, REINIT
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
TST3    sta NT0B,x  	;OUTPUT BUFFERS
		;db $9D, $db, $00 ;STA     >NT0B,x
        dex
        bne TST3		;NOT DONE-LOOP
        beq LP0			;BRANCH ALWAYS
TST4    cmp #$02		;COMMAND 2, STOP
        bne LP0			;NO COMMAND - LOOP
        jsr SET1		;CALL TO ZERO OUT-BUFFS
        jsr NOTE		;THEN MUTE SYNTHESIZER
        brk				;AND RETURN TO PIEBUG

        org     $0088
TIMED   db      $02		;$0088
TIMEC   db      $04
TIMEB   db      $01
TIMEA   db      $01

MASKD   db      $F2		;$008C
MASKC   db      $F0
MASKB   db      $F3
MASKA   db      $F3

NBUF	db      $5A		;$0090 - CANDIDATE ARRAY
		db      $5D
        db      $5F
        db      $62
        db      $64
        db      $62
        db      $5F
        db      $5D
        db      $5A
        db      $58
        db      $56
        db      $53
		db		$51
		db		$53
        db      $56
        db      $58
		
RND0    db      $00		;$00A0 - 5 DICE/RANDOM NUMBERS
        db      $00		;$00A1
        db      $00		;$00A2
        db      $00		;$00A3
NOIS    db      $00		;$00A4

		db      $00		;$00A5
        db      $00
        db      $00

LNTH    db      $00		;$00A8 - CYCLE LENGTH

TMPO    db      $FA

        org     $00E8
CTRL	db		$00		;MUS-1 VARIABLES
ODLY	db		$20

        org     $0100
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
        lda <OUTS		;GET COPY OF PINKING
        dec <OUTS		;COUNTER, DEC ORIGINAL
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
        and MASK,y		;MASK DURATION VAL.
        adc TIME,y		;ADD MINIMUM VAL.
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
ALOC    ldx #$04		;DO 4 NOTE CHANNELS
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
;            SET1
;
;PREPARES KNOWN START POINT FOR
;CYCLIC TUNES.
;
;
SET1    lda #$00		;TO ZERO THINGS WITH
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

		end
		