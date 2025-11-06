#include <xc.inc>
	
psect	code, abs
	
main:
	org	0x0
	goto	start
	org	0x100
	
start:
	movlw	0x0
	movwf	TRISJ, A	; signal input from port J
	movwf	TRISC, A	; clock input from port C
	movlw	0x01		; set W to 0x01
	movwf	PORTC		; set port C (clock) to 0x01
	movlw	0x0
	bra	test
	
loop: 
	movff	0x06, PORTJ	; output the current count value to port J
	movlw	0x00		; set W to 0x00
	movwf	PORTC		; set write to 0x00
	call	delayTimer	; delay to stretch signal
	movlw	0x01		; set W to 0x01
	movwf	PORTC		; set port C (write) to 0x01
	incf	0x06, W, A	; increment value of 0x06 by 1 and move it to W

test: 
	movwf   0x06, A		; move value from W into 0x06
	movlw   0x70		; set W to the max value - 1 we want to count to
	cpfsgt  0x06, A		; compare 0x06 to W and skip the next line if 0x06 is greater than W
	bra	loop		; if end condition not fulfilled, keep looping
	call	countdown	; if end condition fulfilled, start counting down
   
countdown:
	movff	0x06, PORTJ	; output the current count value to port J
	movlw	0x00		; set W to 0x00
	movwf	PORTC		; set write to 0x00
	call	delayTimer	; delay to stretch signal
	movlw	0x01		; set W to 0x01
	movwf	PORTC		; set port C (write) to 0x01
	decf	0x06, W, A	; decrement value of 0x06 by 1 and move it to W
	movwf   0x06, A		; move value from W into 0x06
	movlw   0x01		; set W to the min value + 1 we want to count to
	cpfslt  0x06, A		; compare 0x06 to W and skip the next line if 0x06 is smaller than W
	bra	countdown	; loop back over countdown
	goto	loop		; start counting up again
	
delayTimer:
	movlw	0x10		; set delay length (countdown delay)
	movwf	0x20		; prepare 0x20 to be used as a countdown 
dLoop:	decfsz	0x20, f, A	; decrement 0x20 value by 1, skip if zero
	bc dLoop		; repeat dLoop
	return			; return to the point delayTimer was called from
	
end main