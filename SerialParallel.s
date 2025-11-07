#include <xc.inc>
	
psect	code, abs
	
main:
	org	0x0
	goto	SPI_MasterInit
	org	0x100

SPI_MasterInit:
    bcf		CKE2
    movlw	(SSP2CON1_SSPEN_MASK)|(SSP2CON1_CKP_MASK)|(SSP2CON1_SSPM1_MASK)
    movwf	SSP2CON1, A
    bcf		TRISD, PORTD_SDO2_POSN, A
    bcf		TRISD, PORTD_SCK2_POSN, A

myTable:
	db	0x01, 0x01, 0x02, 0x03, 0x05, 0x08, 0x0D, 0x15, 0x22, 0x37, 0x59, 0x90
	myArray EQU 0x400	; Address in RAM for data
	listCounter EQU 0x0D	; Address of list counter variable
	align	2

start:
	lfsr	0, myArray	; Load FSR0 with address in RAM	
	movlw	low highword(myTable)	; address of data in PM
	movwf	TBLPTRU, A	; load upper bits to TBLPTRU
	movlw	high(myTable)	; address of data in PM
	movwf	TBLPTRH, A	; load high byte to TBLPTRH
	movlw	low(myTable)	; address of data in PM
	movwf	TBLPTRL, A	; load low byte to TBLPTRL
	movlw	12		; 13 bytes to read
	movwf 	listCounter, A	; our counter register for running through the list

loop:
	call	delayTimer
	call	delayTimer
	call	delayTimer
	call	delayTimer
	call	delayTimer
	call	delayTimer
	tblrd*+			; move one byte from PM to TABLAT, increment TBLPRT
	movf	TABLAT, W, A
	call	SPI_MasterTransmit
	movff	TABLAT, POSTINC0	; move read data from TABLAT to (FSR0), increment FSR0
	decfsz	listCounter, A	; count down to zero
	bra	loop		; keep going until finished	
	
SPI_MasterTransmit:
    movwf	SSP2BUF, A
Wait_Transmit:
    btfss	PIR2, 5, A
    bra		Wait_Transmit
    bcf		PIR2, 5, A
    return


delayTimer:
	movlw	high(0xFFFF)	
	movwf	0x20, A		; FR 0x10
	movlw	low(0xFFFF)
	movwf	0x21, A
	movlw	0x00		; W=0
dLoop:	decf	0x21, f, A
	subwfb	0x20, f, A
	;call delayTimer2
	bc	dLoop
	return
/*	
;delayTimer2:
	;movlw	high(0xFFFF)	
	;movwf	0x22, A		; FR 0x10
	;movlw	low(0xFFFF)
	;movwf	0x23, A
	;movlw	0x00		; W=0
;dLoop2:	decf	0x22, f, A
	;subwfb	0x23, f, A
	;bc	dLoop2
	;return
*/
    
end main