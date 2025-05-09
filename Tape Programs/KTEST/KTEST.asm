;8782 Digitally Encoded Keyboard Test
KBD		=$0810
DISP	=$0820

	org $0000
KTEST
	inx			; increment counter
	stx DISP	; show counter
LOOP0
	bit KBD		; check keyboard
	bmi LOOP0	; no scan, loop
LOOP1
	lda KBD		; get keyboard
	bmi KTEST	; scan done, no keys
	rol a		; prepare-check for trigger
	bpl LOOP1	; no trigger, continue
	ror a		; trigger-restore key #
	sta DISP	; and show it
LOOP2
	bit KBD		; check keyboard
	bpl LOOP2	; wait for scan end
	bmi LOOP0	; branch always for more
	end