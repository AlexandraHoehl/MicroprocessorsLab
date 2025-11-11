#include <xc.inc>
    
global  KeyPad_Setup, KeyPad_Transmit_Message

psect	udata_acs   ; reserve data space in access ram
KeyPad_counter: ds    1	    ; reserve 1 byte for variable KeyPad_counter

psect	KeyPad_code,class=CODE
KeyPad_Setup:
    return

KeyPad_Read:
    movlw   0x0F
    movwf   TRISE, A	; read row inputs (PORTE bits 4-7)
    movlw   0xF0
    andwf   PORTE, 0x06, A	; keep top 4 bits and write to 0x06
    movlw   0xF0
    movwf   TRISE, A	; read column inputs (PORTE bits 0-3)
    movlw   0x0F
    andwf   PORTE, 0x06, A ; keep bottom 4 bits and write to 0x06

KeyPad_Transmit_Message:	    ; Message stored at FSR2, length stored in W
    movwf   KeyPad_counter, A
KeyPad_Loop_message:
    movf    POSTINC2, W, A
    call    KeyPad_Transmit_Byte
    decfsz  KeyPad_counter, A
    bra	    KeyPad_Loop_message
    return

KeyPad_Transmit_Byte:	    ; Transmits byte stored in W
    btfss   TX1IF	    ; TX1IF is set when TXREG1 is empty
    bra	    KeyPad_Transmit_Byte
    movwf   TXREG1, A
    return


