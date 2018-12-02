; 2018/12/02 Josef Kubin
;
; asmsyntax=pic18
;
; common ASM functions to print integers or floating point numbers

#include <p18cxxx.inc>

	global	_bin_to_bcd
	global	_find_width
	global	_print_bcd
	radix	dec

	code

_bin_to_bcd
	movwf	INDF1
	swapf	INDF1, W
	addwf	INDF1, W
	andlw	0xf
	btfsc	STATUS, DC
	addlw	0x16
	daw
	btfsc	INDF1, 4
	addlw	0x15
	btfsc	INDF1, 5
	addlw	0x30
	btfsc	INDF1, 6
	addlw	0x60
	btfsc	INDF1, 7
	addlw	0x20
	daw

	; movwf   PRODL

	; set hundreds
	;clrf	PRODH
	;rlcf	PRODH, F
	;btfsc	INDF1, 7
	;incf	PRODH, F

	; WREG with ones
	return

_find_width
	swapf	INDF0, W
	btfsc	INDF1, 0
	movf	POSTDEC0, W
	andlw	0xf
	bnz	nz_digit
	decfsz	INDF1, F
	bra	_find_width

	; number is zero
	incf	INDF1, F

nz_digit
	return

_print_bcd
	addwf	FSR2L, F
	movlw	0
	addwfc	FSR2H, F
print_bcd_loop
	swapf	INDF2, W
	btfsc	INDF1, 0
	movf	POSTDEC2, W
	andlw	0xf
	addlw	'0'
	movwf	POSTINC0
	incf	INDF1, F
	decfsz	PRODL, F
	bra	print_bcd_loop

;restore_frame_ptr
	movff	PCLATH, FSR2L
	movff	PCLATU, FSR2H
	return
	end
