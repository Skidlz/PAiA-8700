;8782 Digitally Encoded Keyboard Test
KBD		=$0810
DISP	=$0820

	org $0000
KTEST
	inx			; increment counter
	stx DISP	; show counter
LOOP0
	bit KBD		; check keybaord
	bmi LOOP0	; no scan, loop
LOOP1
	lda KBD		; get keyboard
	bmi KTEST	; scan done, no keys
	rol a		; prepate-check for trigger
	bpl LOOP1	; no triiger, coninute
	ror a		; trigger-restore key #
	sta DISP	;	and shwo it
LOOP2
	bit KBD		; check keyboard
	bpl LOOP2	; wait for scan end
	bmi LOOP0	; branch always for more
	end