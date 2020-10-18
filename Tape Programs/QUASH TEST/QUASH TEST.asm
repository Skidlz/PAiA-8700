;8781 QuaSH Test
DISP	=$0820
SH		=$09EF

	org $0000
TEST
	lda #$10		; set up note
REPEAT
	ldx #$10		; set up S/H pointer
LOOP1
	sta SH,x	; update S/H
	stx DISP	; show in display
	ldy #$10
LOOP2
	dey			; delay
	bne LOOP2
	dex			; point to next S/H
	bne LOOP1	; if not done, loop
	beq REPEAT	; branch always
	end