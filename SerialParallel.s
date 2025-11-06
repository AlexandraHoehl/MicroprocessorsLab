#include <xc.inc>
	
psect	code, abs
	
main:
	org	0x0
	goto	SPI_Master_Init
	org	0x100

SPI_MasterInit:
    bcf		CKE2
    movlw	(SSP2CON1_SSPEN_MASK)|(SSPCON1_CKP_MASK)|(SSP2CON1_SSPM1_MASK)
    movwf	SSP2CON1, A
    bcf		TRISD, PORTD_SDO2_POSN, A
    bcf		TRISD, PORTD_SCK2_POSN, A
    return
    
myTable:
	db	0x01, 0x01, 0x02, 0x03, 0x05, 0x08, 0x0D, 0x15, 0x22, 0x37, 0x59, 0x90
	db	0xE9
	myArray EQU 0x400	; Address in RAM for data
	listCounter EQU 0x0D	; Address of list counter variable
	align	2		; ensure alignment of subsequent instructions 

start:
	lfsr	0, myArray	; Load FSR0 with address in RAM	
	movlw	low highword(myTable)	; address of data in PM
	movwf	TBLPTRU, A	; load upper bits to TBLPTRU
	movlw	high(myTable)	; address of data in PM
	movwf	TBLPTRH, A	; load high byte to TBLPTRH
	movlw	low(myTable)	; address of data in PM
	movwf	TBLPTRL, A	; load low byte to TBLPTRL
	movlw	13		; 13 bytes to read
	movwf 	listCounter, A	; our counter register for running through the list

loop:
	tblrd*+			; move one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, W
	call	SPI_MasterTransmit
	movff	TABLAT, POSTINC0	; move read data from TABLAT to (FSR0), increment FSR0
	decfsz	listCounter, A	; count down to zero
	bra	loop		; keep going until finished	
	
SPI_MasterTransmit:
    movwf	SSP2BUF, A
Wait_Transmit:
    btfss	PIR2, 5
    bra		Wait_Transmit
    bcf		PIR2, 5
    return

end main