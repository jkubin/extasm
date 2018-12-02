; 2014/06/19 Josef Kubin
;
; asmsyntax=pic18
;
; superfast memset functions

#include <p18cxxx.inc>

	global _memset
	global _memset_0x00
	global _memset_0x00_float
	global _memset_0xff
	global _memset2
	global _memset_nan
	global _memset_nan_float
	radix dec

	code
_memset_0x00_float
	subfsr	0, 4
	movlw	4
_memset_0x00
	movwf	PRODL
	movlw	0

_memset
	clrf	PRODH
_memset2
	bcf	STATUS, C
	rrcf	PRODH, F
	rrcf	PRODL, F
	btfsc	STATUS, C
	movwf	POSTINC0

	bcf	STATUS, C
	rrcf	PRODH, F
	rrcf	PRODL, F
	bnc	zero_tst
	movwf	POSTINC0
	movwf	POSTINC0

zero_tst
	movwf	INDF1
	movf	PRODL, W
	iorwf	PRODH, W
	bz	exit

	movlw	0
	negf	PRODL
	comf	PRODH, F
	addwfc	PRODH, F

	movf	INDF1, W

loop
	movwf	POSTINC0
	movwf	POSTINC0
	movwf	POSTINC0
	movwf	POSTINC0
	incfsz	PRODL, F
	bra	loop
	incfsz	PRODH, F
	bra	loop

exit
	return

_memset_nan_float
	subfsr	0, 4
_memset_nan
	setf	POSTINC0
	setf	POSTINC0
	setf	POSTINC0
	setf	POSTINC0
	return

_memset_0xff
	movwf	PRODL
	movlw	0xff
	bra	_memset

	end
