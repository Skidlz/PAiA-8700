;
;	**************************************
;	*  piebug			  version 1.0	 *
;	*  paia interactive editor-debugger  *
;	*  written by roger walton			 *
;	*  copyright 1977 by paia			 *
;	*  electronics, inc.				 *
;	**************************************
;
;
;
	org $0f00
;
key		=$0800			;base addr of key ports
temp	=$ee			;temporary storage
lastke	=$f8			;previous key decoded
buffer	=$f0			;key entry buffer
disp	=$0820			;led display
mstack	=$ed			;monitor stack pointer
pnter	=$f6			;16 bit addr pointer
tape1	=$0e00			;start of tape system
cass	=$0900			;cassette port
;
acc		=$f9			;reg storage
yreg	=$fa
xreg	=$fb
pc		=$fc
stackp	=$fe
preg	=$ff			;reg storage
;
;	decode key subroutine
;	this sub scans the entire keybaord and
;	returns with decoded key value in a and y.
;	carry is clear if new key. x is
;	destroyed. $18 is "no key" code.
;
decode  ldy #0			;clear result reg
        ldx #$21		;x is port reg
loop	lda #1
        sta temp		;set up mask
next    lda key,x		;read current key port
        and temp		;use mask to select key
        bne result		;branch if key down
        iny				;set result to next key
result  asl temp		;shift mask to next key
        bcc next		;br if more keys on port
        txa
        asl a			;select next port
        tax
        bcc loop		;branch if not last port
        cpy lastke		;clear carry if new key
        sty lastke		;update lastkey
        tya				;move key to acc
        rts				;return
;
;
;
;	getkey subroutine
;	this sub waits for a new key to be
;	touched and then returns with the
;	key value in the accumulator.   
;	x and y are cleared.
;
;	beep subroutine (embedded in get key sub)
;	this sub produces a short beep at
;	the cassette port. carry must be
;	clear before entering. x and y
;	are clear.
;
getkey	jsr decode		;get a key
beep	ldx #20			;enter here for beep sub
nxtx	ldy #$3f
delay	bcs dly			;skip tone if carry set
        sty cass		;generate tone
dly		dey				;delay
        bne delay
        dex				;delay some more
        bne nxtx		;next x
        bcs getkey		;branch if not new key
        rts				;return
;
;
;
;
;	shift buffer subroutine
;	this sub shifts the lower 4 bits of
;	the accumlator into the least
;	significant position of buffer. the
;	entire buffer is shifted 4 times and
;	the most significant 4 bits are lost.
;	x and y are cleared. if on return,
;	a single "rol a" is performed,
;	the lower 4 bits of the accumulator
;	will contain the 4 bits that were
;	shifted out of buffer
;
shift   asl a			;shift key information
        asl a			;to upper 4 bits of acc
        asl a
        asl a
        ldy #4
rotate  rol a			;shift bit to carry
        ldx #$fa		;wrap around to $fd
rotnxt  rol buffer+6,x	;carry to buffer to carry
        inx				;and so on
        bne rotnxt		;until end of buffer
        dey				;done 4 bits?
        bne rotate		;branch if not
        rts				;return
;
;	reset entry point
;
reset   lda #0
        sta $08e0		;clear display and ports
        beq comand		;branch always
;
;
;
shftd   jsr shift		;shift key into buffer
dspbuf  lda buffer		;get buffer
see     sta disp		;update display
;
comand  ldx mstack
        txs				;set monitor stack
        jsr getkey		;wait for key
        cmp #$10		;is it control key
        bcc shftd		;branch if not
        tay				;control key into y
        ldx table-16,y	;get command addr low
        stx temp		;save it
        ldx #$ff		;get command addr high
        stx temp+1		;assemble command addr
        inx				;clr x
        jmp (temp)		;execute command
;
;
        
phigh   clc
        lda pnter		;move pointer to buffer
        sta buffer
        lda pnter+1
        sta buffer+1
        bcs dspbuf		;branch if pointer low
        bcc see			;branch if pointer high
;
;
displa  lda buffer		;move buffer to pointer
        sta pnter
        lda buffer+1
        sta pnter+1
        bcs load		;branch always
;
;
backsp  lda pnter		;dec 16 bit pointer
        bne skip		;branch if no borrow
        dec pnter+1
skip    dec pnter
        bcs load		;branch always
;
;
enter	lda buffer		;get byte in buffer
        sta (pnter,x)	;store it in active cell
        inc pnter		;inc 16 bit pointer
        bne load		;branch if no carry
        inc pnter+1
load    lda (pnter,x)	;get byte in active cell
stabuf  sta buffer		;store it in buffer
        bcs dspbuf		;branch always
;
;
reladr  cld
        clc				;this adds 1 to pointer
        lda buffer		;get buffer low
        sbc pnter		;subtract pointer low + 1
        sta buffer		;save results
        lda buffer+1	;get buffer high
        sbc pnter+1		;subtract pointer high
        tay				;save results in y
        lda buffer		;get results low
        bcs pos			;br if total result pos
        bpl bad			;br if result low pos
        iny				;in result high
chk     tya				;check result high
        bne bad			;br if not zero
        beq dspbuf		;br always, disp rel addr
pos     bmi bad			;br if result low neg
        bpl chk			;br always
bad     txa				;clear acc
        sec
        bcs stabuf		;branch always
;
;
        nop
;
;
;
;	break routine entry point
;
break   sta acc			;save accumulator
        sty yreg		;save y
        stx xreg		;save x
        pla				;get status reg
        sta preg		;save it
        pla				;get pc low
        cld
        sec
        sbc #2			;correct pc low
        sta pc			;save it
        pla				;get pc high
        sbc #0			;subtract carry
        sta pc+1		;save it
        tsx				;get user stack pointer
        stx stackp		;save it
        lda #$bb		;break indication
        bcs stabuf		;branch always
;
;
run     ldx stackp		;get user stac pointer
        txs				;init stack
        lda buffer+1	;get pc high
        pha				;put it on stack
        lda buffer		;get pc low
        pha				;put it on stack
        lda preg		;get status reg
        pha				;put it on stack
        ldx xreg		;restore x
        ldy yreg		;restore y
        lda acc			;restore accumulator
        rti				;restore pc & status reg
;						from stack and execute
;						user's program
;
;
tape    jmp tape1		;execute tape option
;
;
;				command address table
;				stores low byte only of entry
;				address for each command
;
;run, displa, backsp, enter, phigh, plow, tape, reladr
table  db  $dc, $7a, $84, $8e, $6d, $6e, $ef, $9e 
	db $03, $00 					;nmi vector
	db $46, $0f 					;reset vector
	db $00, $00					;irq vector
	