#include <xc.inc>
	
psect	code, abs
	
main:
    
	org	0x0
	goto	start
	org	0x100
	
start:
	movlw	0x0
	movwf	TRISJ, A
	movwf	TRISC, A
	movlw	0x0
	bra	test
	
loop: 
	movff	0x06, PORTJ
	call	delayTimer
	incf	0x06, W, A


test: 
	movwf   0x06, A
	movlw   0xFE
	cpfsgt  0x06, A
	bra	loop
	call	countdown
   
countdown:
	movff	0x06, PORTJ
	call	delayTimer
	decf	0x06, W, A
	movwf   0x06, A
	movlw   0x01
	cpfslt  0x06, A
	bra	countdown
	goto	0x0
	
delayTimer:
	movff	0x20, 0xFF
	movlw	0x01
	movwf	PORTC
dLoop:	decfsz	0x20, f, A
	bc dLoop
	movlw	0x00
	movwf	PORTC
	return
	
end main