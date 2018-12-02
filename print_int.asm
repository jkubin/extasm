; 2009/07/20 Josef Kubin
;
; asmsyntax=pic18

#include <p18cxxx.inc>

; functions to print integers

; void print_uint8(char *bfr, unsigned char *num, unsigned char format);
; void print_uint16(char *bfr, unsigned int *num, unsigned char format);
; void print_uint24(char *bfr, unsigned short long *num, unsigned char format);
; void print_uint32(char *bfr, unsigned long *num, unsigned char format);

; three cases of `format':
; +format	<--- prefix padded with ' ' char
; 0		<--- automatic number width (no left hand side padding)
; -format	<--- prefix padded with '0' char

#define WIDTH		0x00
#define PTRL		0x01
#define PTRH		0x02
#define BFRL		0x03
#define BFRH		0x04
#define FRAMEL		0x05
#define FRAMEH		0x06
#define NUM0		0x07
#define NUM1		0x08
#define NUM2		0x09
#define NUM3		0x0a
#define BCD0		0x0b
#define BCD1		0x0c
#define BCD2		0x0d
#define BCD3		0x0e
#define BCD4		0x0f
#define TMP		0x10

	extern	_find_width
	extern	_print_bcd
	global	print_uint8
	global	print_uint16
	global	print_uint24
	global	print_uint32
	radix	dec

	code

init
	movff	FSR2L, POSTINC1
	movff	FSR2H, POSTINC1
	movff	FSR1L, FSR2L
	movff	FSR1H, FSR2H
	subfsr	2, FRAMEH + 1
	addfsr	1, TMP - FRAMEH - 1

	movsf	[PTRL], FSR0L
	movsf	[PTRH], FSR0H

	; clrf	[NUM0]
	clrf	[NUM1]
	clrf	[NUM2]
	clrf	[NUM3]
	return

print_uint24
	rcall	init
	addfsr	0, 2
	bra	print3

print_uint16
	rcall	init
	addfsr	0, 1
	bra	print2

print_uint8
	rcall	init
	bra	print1

print_uint32
	rcall	init
	addfsr	0, 3

	movf	POSTDEC0, W
	movwf	[NUM3]

print3
	movf	POSTDEC0, W
	movwf	[NUM2]

print2
	movf	POSTDEC0, W
	movwf	[NUM1]

print1
	movf	POSTDEC0, W
	movwf	[NUM0]

	clrf	[BCD0]
	clrf	[BCD1]
	clrf	[BCD2]
	clrf	[BCD3]
	clrf	[BCD4]

	movlw	32
	movwf	[TMP]
int_to_bcd
	rlcf	[NUM0], F
	rlcf	[NUM1], F
	rlcf	[NUM2], F
	rlcf	[NUM3], F

	movf	[BCD0], W
	addwfc	[BCD0], W
	daw
	movwf	[BCD0]

	movf	[BCD1], W
	addwfc	[BCD1], W
	daw
	movwf	[BCD1]

	movf	[BCD2], W
	addwfc	[BCD2], W
	daw
	movwf	[BCD2]

	movf	[BCD3], W
	addwfc	[BCD3], W
	daw
	movwf	[BCD3]

	movf	[BCD4], W
	addwfc	[BCD4], W
	daw
	movwf	[BCD4]

	decfsz	[TMP], F
	bra	int_to_bcd

	; set bcd bfr
	movlw	BCD4
	movff	FSR2L, FSR0L
	movff	FSR2H, FSR0H

	addwf	FSR0L, F
	movlw	0
	addwfc	FSR0H, F

	; set max width
	movlw	(BCD4 - BCD0 + 1) * 2
	movwf	INDF1

	rcall	_find_width

	movsf	[BFRL], FSR0L
	movsf	[BFRH], FSR0H

	; |width|
	movf	[WIDTH], W
	bz	auto_width

	btfsc	WREG, 7
	negf	WREG

	movwf	PRODL

	subwf	[TMP], W
	bc	cut_width

	movwf	PRODL
	negf	PRODL

	; set leading char
	movlw	'0'
	btfss	[WIDTH], 7
	movlw	' '

print_prefix
	movwf	POSTINC0
	decfsz	PRODL, F
	bra	print_prefix

auto_width
	movsf	[TMP], PRODL

print_num
	movff	FSR2L, PCLATH
	movff	FSR2H, PCLATU

	decf	[TMP], W
	bcf	STATUS, C
	rrcf	WREG, W
	addlw	BCD0

	rcall	_print_bcd

	subfsr	1, TMP - FRAMEH
	movff	POSTDEC1, FSR2H
	movff	INDF1, FSR2L
	return

cut_width
	movf	PRODL, W
	movwf	[TMP]
	bra	print_num

	end
