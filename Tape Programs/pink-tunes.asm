;
;   pink tunes
;
;   a composing program
;   for four part harmonies
;
;   by john s simonton, jr
;   (c) 1978 paia electronics, inc
;
kbd		=$0810
disp	=$0820
init	=$0d21
note	=$0d2b
decd	=$0f00
break	=$ffc0		;break routine in PIEBUG

time	=$0087
mask	=$008b
clck	=$00bf
ntb7	=$00bf
ntbb	=$00c3
ntmp	=$00cf
nt0b	=$00db
ktbl	=$00df
outs	=$00ea
outt	=$00eb
temp	=$00ec		;temporary storage

	code
	org	0

;first attend to houskeeping--

beg     jmp     break    ; break vector $FFC0
star    jsr     init    ; setup synth - mus1
        lda     kbd     ; initialize random
        sta     ntmp+01 ; number generator
loop    jsr     set1     ; init pink tunes
lp0     jsr     note    ; play note, read ago
;
; check for addition to candidate
; note table
;
main    lda     ktbl+08 ; any keys down
        beq     out1    ; no-check for time out
        cmp     temp   ; yes-a new key?
out1    sta     temp   ; save for next time
        beq     out     ; branch is same key
;
        ldx     #$10      ; if new key shift
lp3     ldy     <nbuf-1,x ; all 16 candidates
        sta     <nbuf-1,x ; down by one
        tya
        dex
        bne     lp3     ; not done-loop
;
; now check for clock time out
;
out     lda     <clck   ; get master clock
        bne     test    ; and if times out
        lda     <tmpo   ; set to tempo value
        sta     <clck   ; call sub for new
        jsr     aloc    ; notes (if needed)
        lda     <lnth   ; get cycle status
        sta     disp    ; show it and if zero
        beq     test    ; cycle is complete
        dec     <lnth   ; if note done, decrement
        bne     test    ; if note zero now leave
        jsr     set1     ; if zero, re-init
        jsr     aloc    ; get first notes and
        beq     lp0     ; branch always to play
test    jsr     decd    ; get a command - mus-1
        bne     tst2    ; not zero, next test
        ldx     #$03      ; command0, new tune
                        ; set pointer/counter
tst1    jsr     rndm    ; get random number
        sta     <ntmp,x ; new initial random
        dex             ; point to next
        bne     tst1    ; not done - loop
        beq     loop    ; branch always
tst2    cmp     #$01	; command 1, tunning
        bne     tst4	; not 1, test next
        ldx     #$04	; 4 output buffers
        lda     #$5c	; put middle c in all
tst3    ;sta     nt0b,x  ; output buffers
		db $9d, $db, $00 ;sta     >nt0b,x
        dex
        bne     tst3    ; not done-loop
        beq     lp0     ; branch always
tst4    cmp     #$02		; command 2 stop
        bne     lp0     ; no command - loop
        jsr     set1	; call to zero out-buffs
        jsr     note	; then mute synthesizer
        brk				;and return to piebug

        org     $0088
timed   db      $02      ; 0x0088
timec   db      $04
timeb   db      $01
timea   db      $01

maskd   db      $f2      ; 0x008c
maskc   db      $f0
maskb   db      $f3
maska   db      $f3

nbuf	db      $5a      ; 0x0090 - candidate array
		db      $5d
        db      $5f
        db      $62
        db      $64
        db      $62
        db      $5f
        db      $5d
        db      $5a
        db      $58
        db      $56
        db      $53
		db		$51
		db		$53
        db      $56
        db      $58
		
rnd0    db      $00      ; 0x00a0 - 5 dice/random numbers
        db      $00		 ; 0x00a1
        db      $00		 ; 0x00a2
        db      $00		 ; 0x00a3
nois    db      $00		 ; 0x00a4

		db      $00      ; 0x00a5
        db      $00
        db      $00

lnth    db      $00      ; 0x00a8 - cycle length

tmpo    db      $fa

        org     $00E8
ctrl	db		$00		;MUS-1 variables
odly	db		$20

        org     $0100
;
;       random number generator
;
; essentially a 22 bit long shift
; register with ex-0r taps at
; stages 22 and 21 fed back to
; input.
;
rndm    txa             ; save x
        pha
        lda     <nois+1	; last byte s/r
        asl		a       ; align bits 22 &
        eor     <nois+1	; 21 and do ex-or
        asl		a
        asl		a
        asl		a
        ldx     #$03      ; set up pnt/cnt
lp1     rol     <nois,x ; and shift 3 byte
        dex             ; shift register
        bne     lp1     ; by one bit left
        pla             ; when done re-
        tax             ; x reg
        lda     <nois+03 ; and leave with
        rts             ; with no. in acc
;
;       new note
;
; takes care of picking pink note
; from candidate note table and
; calculates and updates note timers
; note that y points to channel for
; update
;
nwnt    ldx     #$05	; set up pnt/cnt
        lda     <outs	; get copy of pinking
        dec     <outs	; counter, dec original
        eor     <outs	; pattern of changed
        sta     <outt	; bits - save changes
        lda     #$00	; prepare to sum dice
nw1     lsr     <outt	; check for changed
        bcc     nw2     ; bit - if changed
        pha             ; save current total
        jsr     rndm	; get random nubmer
        and     #$03	; make range from 0 t0 3
        sta     <rnd0-1,x	; save value for next
        pla             ; recover total
        clc             ; prepare addition
nw2     adc    <rnd0-1,x	; add value of die
        dex             ; point to next
        bne     nw1     ; loop if not done
        tax             ; use total as pointer
        lda     <nbuf,x ; get candidate
        beq     dura    ; zero, do note change
        sta     ntb7,y  ; place in temp buffer
dura    lda     <nois+01 ; a cheap random number
        clc             ; prepare
        and     mask,y  ; mask duration value
        adc     time,y  ; add minimum value
        and     #$0f      ; and mask result
        tax             ; use as counter and
        lda     #$01      ; do durations as
nt2     rol		a             ; powers of 2. carry
        dex             ; set dots note
        bne     nt2     ; not done - loop
        sta     ntbb,y  ; timer and return
        rts

;       allocation 0151
; sees if new notes are needed and if
; so gets them. also clears trigger
; of note output once it has played
;
aloc    ldx     #$04      ; do 4 note channels
lp6     dec     <ntbb,x ; decrement note timer
        bne     lp5     ; and if time out
        txa             ; transfer x reg. to
        tay             ; y reg.
        jsr     nwnt     ; and get new note
        tya             ; and duration and
        tax             ; restore x
lp5     dex             ; decriment counter
        bne     lp6     ; if note done - loop
        ldx     #$04      ; again, four channels
al1     lda     <ntb7,x ; get note from temp
        sta     <nt0b,x ; buffer, save in out
        and     #$3f      ; buffer, clear flag
        sta     <ntb7,x ; put back in temp.
        dex             ; point to next
        bne     al1     ; not done - loop
        rts
;
;       set1
; prepares known start point for
; cyclic tunes
;
set1    lda     #$00      ; to zero things with
        ldy     #$01      ; preset for note cntrs
        ldx     #$04      ; do 4 channles
lp10    sta     <nt0b,x ; zero out buffers
        sta     <rnd0,x ; zero 4 dice
        sty     <ntbb,x ; preset note timers
        pha             ; save the zero
        lda     <ntmp,x ; set up rndm's s/r
        sta     <nois,x ; and cycle counter
        pla             ; recover zero
        dex             ; point to next
        bne     lp10    ; not done - loop
        sta     <rnd0   ; zero 5th die
        sta     <outs   ; zero pinking counter
        rts             ; and return
