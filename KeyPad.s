#include <xc.inc>
    
global  KeyPad_Setup, KeyPad_Read, KeyPad_Check, KeyPad_Evaluate

psect	udata_acs   ; reserve data space in access ram
KP_cnt_l:	ds 1   ; reserve 1 byte for variable LCD_cnt_l
KP_cnt_h:	ds 1   ; reserve 1 byte for variable LCD_cnt_h
KP_cnt_ms:	ds 1   ; reserve 1 byte for ms counter
KP_output:	ds 1

psect	KeyPad_code,class=CODE
KeyPad_Setup:
    movlb   0xF
    bsf	    PADCFG1,  7	; set pull-ups to on for PORTE
    movlb   0x0
    clrf    LATE, A
    movlw   0x0
    movwf   TRISF, A
    return

KeyPad_Read:
    ; row read section
    movlw   0x0F
    movwf   TRISE, A	; read row inputs (PORTE bits 4-7)
    movlw   0x10
    call    Delay_x4us	; give voltage time to settle
    movf    PORTE, W, A
    movlw   0x0F
    andwf   PORTE, W, A	; keep top 4 bits and write to 0x06
    movwf   0x06, A
    
    ; column read section
    movlw   0xF0
    movwf   TRISE, A	; read column inputs (PORTE bits 0-3)
    movlw   0x10
    call    Delay_x4us	; give voltage time to settle
    movlw   0xF0
    andwf   PORTE, W, A ; keep bottom 4 bits and write to 0x07
    movwf   0x07, A
    movf    0x06, W, A ; move value from 0x06 to W
    iorwf   0x07, W, A	; combine values from 0x06 and 0x07 into byte at W that should tell us which number has been pressed
    movwf   0x06    ; move the byte into 0x06 to be read out
    
    
    return
  
KeyPad_Check:
    movf    0x06, W, A
    movwf   PORTF, A
    return
    
KeyPad_Evaluate:
    return
    

Delay_ms:		    ; delay given in ms in W
	movwf	KP_cnt_ms, A
lp2:	movlw	250	    ; 1 ms delay
	call	Delay_x4us	
	decfsz	KP_cnt_ms, A
	bra	lp2
	return
    
Delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	KP_cnt_l, A	; now need to multiply by 16
	swapf   KP_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	KP_cnt_l, W, A ; move low nibble to W
	movwf	KP_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	KP_cnt_l, F, A ; keep high nibble in LCD_cnt_l
	call	Delay
	return

Delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
lp1:	decf 	KP_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	KP_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	lp1		; carry, then loop again
	return			; carry reset so return

end

