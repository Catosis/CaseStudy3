LIST P=16F747
title "Solenoid Control"

#include <P16F747.INC> ; include file for the device

__CONFIG _CONFIG1, _FOSC_HS & _CP_OFF & _DEBUG_OFF & _VBOR_2_0 & _BOREN_0 & _MCLR_ON & _PWRTE_ON & _WDT_OFF
__CONFIG _CONFIG2, _BORSEN_0 & _IESO_OFF & _FCMEN_OFF

;Variable Declarations
	
		mode equ 20h
		modeInput equ 21h
		porteComf equ 22h
	
		Timer0 equ 23h
		Timer1 equ 24h
		Timer2 equ 25h
		Seconds equ 26h
		
		org 00h
		goto initPort
	
		org 04h
		goto isrService
	
		org 10h

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
; Port Initialization

    initPort
		clrf mode
		clrf PORTE	; Clear Port E input latches (Modes)
		clrf PORTC	; Clear Port C input latches (red = 1, green = 0)
		clrf PORTB	; LED lights
		clrf PORTD	; Clear Port D Solenoid output latches + sensor output
		bcf STATUS,RP1
		bsf STATUS,RP0 ; Set bit in STATUS register for bank 1
		movlw B'11111111' ; move hex value FF into W register (maybe no need)
		movwf TRISE ; Configure Port E as all inputs
		movwf TRISC ; Configure port C as all inputs
		movlw B'11111100' ; move hex value FC into W register (maybe no need)
		movwf TRISD ; Configure D, 1 is Main, 0 is Reduced, 2 = Sensor input
		movlw B'11110000' ; move hex value FF into W register (maybe no need)
		movwf TRISB ; Config B as all outputs
		movlw B'00001110' ; move hex value 0E into W register
		movwf ADCON1 ; Config the pins of Port B to be digital and pin Port A 0 to be analog
		
		bcf STATUS,RP0 ; Clear bit in STATUS register for bank 0
		clrf  PORTB ; Set the LED to be '0000' at first

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
; Mode Selector
	
		call WaitGreenPress
		call WaitGreenRelease

	GreenPressed ; Green button pressed and debounce process done
		movf PORTE, W ;(hopefully) moves values in port E to register W
		movwf porteComf
		comf porteComf, 1 ; Complement the input from Port E
		movlw B'00000111'
	 	andwf porteComf, 0 ; Clear the higher bits of input
		movwf modeInput ; Move the input of octal switch into the modeInput register
		goto Bit2Test ; Starting mode selection

    WaitGreenPress ; check if green button is pressed
		btfss PORTC, 0 
		goto WaitGreenPress 
		return	
	
	WaitGreenRelease ; check if the green button is released
		btfsc PORTC, 0
		goto WaitGreenRelease		
		return	
		
	Bit2Test ; Test Bit 2 of the Mode
		btfsc modeInput, 2
		goto Bit2Set
		goto Bit2Clear
	
    Bit2Set ; if the input bit 2 is set
		btfsc modeInput, 1
		goto SetError
		btfsc modeInput, 0
		goto SetError
		goto SetMode4

    Bit2Clear ; if the input bit 2 is clear
		btfsc modeInput, 1 
		goto Mode2or3
		goto Mode1orE

    Mode2or3 ; Test if the mode is 2 or 3
		btfsc modeInput, 0
		goto SetMode3
		goto SetMode2

    Mode1orE ; Test if the mode is 1 or Error
		btfsc modeInput,0
		goto SetMode1
		goto SetError
	
    SetError ; Set the mode to be error
		movlw B'00000001'
		movwf mode
		bsf PORTB, 3; Set the highest LED to be 1
		btfsc modeInput, 2
		bsf PORTB, 2
		btfsc modeInput, 1
		bsf PORTB, 1
		btfsc modeInput, 0
		bsf PORTB, 0
	 	goto ModeError

    SetMode1 ; Set the mode to be 1
		movlw B'00000010'
		movwf mode
		movlw B'00000001'
		movwf PORTB
		goto Mode1
	
	SetMode2 ; Set the mode to be 2
		movlw B'00000100'
		movwf mode
		movlw B'00000010'
		movwf PORTB
		goto Mode2

	SetMode3 ; Set the mode to be 3
		movlw B'00001000'
		movwf mode
		movlw B'00000011'
		movwf PORTB
		goto Mode3

    SetMode4 ; Set the mode to be 4
		movlw B'00010000'
		movwf mode
		movlw B'00000100'
		movwf PORTB
		goto Mode4

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
; Working Mode 1

	Mode1 ; Working Mode 1	
		call WaitRedPress
		call WaitRedRelease
		movlw B'11111110' ; turns on
		btfsc PORTD, 1 ; testing if currently engaged, skips if off		
		movlw B'11111100' ; turns off
		nop
		movwf PORTD	; move on/off to port
		goto Mode1 ;return back to start of Mode

	MainOn ; Turn on the main transistor
		movlw B'11111110' ; turns on
		movwf PORTD	
		return

	MainOff ; Turn off the main transistor
		movlw B'11111100' ; turns off
		movwf PORTD	
		return
		
	WaitRedPress ; check if red button is pressed when mode starts
		btfsc PORTC, 0 ; check green button
		goto ReMode
		btfss PORTC, 1 ; check red button
		goto WaitRedPress
		return	

	ReMode ; Turn off main transistor and read in mode again when in Mode 1
		btfsc mode, 1
		call MainOff
		goto GreenPressed
	
	WaitRedRelease ; check if the red button is released
		btfsc PORTC, 1
		goto WaitRedRelease		
		return

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
; Working Mode 2

	Mode2 ; Working Mode 2
		bcf STATUS, RP0
		movlw B'01000001'
		movwf ADCON0 ; move special function A/D register
		bsf ADCON0, GO

		call WaitRedPress

	ResetRed ; Come to here when hit the red button during the timer
		call WaitRedRelease

		call WaitConversion
		bcf STATUS, C
		rrf W, 0 ; move one bits left
		bcf STATUS, C
		rrf W, 0 ;
		movwf Seconds ; Store the time from the control pot

		xorlw B'00000000'
		btfsc STATUS, Z
		goto SetError
		call MainOn

	Timer ; The timer for total time
		decfsz Seconds, F
		call Timer1s
		goto Timer

	WaitConversion
		btfsc ADCON0, GO
		goto WaitConversion
		movf ADRESH, W
		return

	Timer1s ; Set the timer to be 1 sec
		movlw 06h ; get most significant hex value + 1
		movwf Timer2 ; store it in count register
		movlw 16h ; get next most significant hex value
		movwf Timer1 ; store it in count register
		movlw 15h ; get least significant hex value
		movwf Timer0 ; store it in count register

	Delay 
		decfsz Timer0, F
		
		goto Delay
		decfsz Timer1, F
		goto Delay
		decfsz Timer2, F
		goto Delay
		return 

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
; Working Mode 3
	
	Mode3 ; Working Mode 3

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
; Working Mode 4

	Mode4 ; Working Mode 4

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
; Error Mode

	ModeError; Error Mode

	

	isrService
		goto isrService
    
	end