LIST P=16F747
title "A/D Demo Program"

#include <P16F747.INC> ; include file for the device

__CONFIG _CONFIG1, _FOSC_HS & _CP_OFF & _DEBUG_OFF & _VBOR_2_0 & _BOREN_0 & _MCLR_ON & _PWRTE_ON & _WDT_OFF
__CONFIG _CONFIG2, _BORSEN_0 & _IESO_OFF & _FCMEN_OFF

    initPort
	clrf PORTE	; Clear Port E output latches
	bsf STATUS,RP0 ; Set bit in STATUS register for bank 1
	movlw B'11111111' ; move hex value FF into W register (maybe no need)
	movwf TRISC ; Configure Port C as all inputs

	bcf STATUS,RP0 ; Clear bit in STATUS register for bank 0
	
    GreenPress

    Mode1RedPress
    
    