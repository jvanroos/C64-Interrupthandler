!cpu 6502
!to "main.prg", cbm 

				* = $0801
				
				!word next
				!word 10
				!byte $9e
				!text "4096"
				!byte 0
next    		!word 0

				*=$1000
; ----------------------------------------------------------
; Code start
; ----------------------------------------------------------

; --- KERNAL & BASIC uitschakelen ---
				sei
				lda #$35
				sta $01           ; %00110101 = RAM in plaats van KERNAL/BASIC ROM

; --- IRQ vector instellen op $FFFE/$FFFF ---
				lda #<irq
				sta $fffe
				lda #>irq
				sta $ffff

; --- VIC-II initialisatie ---
				lda #$7f
				sta $dc0d         ; CIA interrupts uit
				sta $dd0d
					
					;      o-- Sprite - Sprite Interrupt 
					;      |o-- Sprite - Background Interrupt 
					;      ||o- Raster Interrupt
					;      |||
				lda #%00000111
				sta $d01a         ; Raster interrupt inschakelen (bit 0)

				lda $d011
				and #$7f
				sta $d011         ; bit7=0, dus raster < 256
		
				lda #100
				sta $d012         ; Rasterlijn 100

				lda #$0e
				sta $d020         ; Borderkleur = cyaan
				lda #$06
				sta $d021         ; Achtergrondkleur = cyaan
				
				lda #%00000011
				sta $d015
				
; Sprite 1 and 2 or enabled and colliding on 1 pixel		
				lda #$1c
				sta $d000
				lda #$96
				sta $d001

				lda #$32
				sta $d002
				lda #$aa
				sta $d003
				
				lda #$2a
				sta $05e0
				
				cli               ; Interrupts weer aan

; --- Eindeloze hoofdloop ---
mainloop:
				inc $0400
				jmp mainloop				
				
irq				pha
				txa
				pha
				tya
				pha
			;-----------------------------------
			; Raster Interrupt Check
			;-----------------------------------
				lda #$01
				and $d01a								; Raster interrupt enabled.
				bit $d019
				beq +
			;-----------------------------------
			; Raster interrupt
			;-----------------------------------	
				inc $07e7
				lda #$07
				sta $d020

				ldx #$08
-				dex
				bne -

				lda #$0e
				sta $d020
				
				lda #$01
				sta $d019
			;-----------------------------------
			; Sprite-Background Interrupt Check
			;-----------------------------------
+				lda #$02
				and $d01a								;  Sprite-Background collision interrupt enabled.
				bit $d019
				beq +
			;-----------------------------------
			; Sprite <> Background Interrupt
			;-----------------------------------
				inc $07c0
				lda #$02
				sta $d019
			;-----------------------------------
			; Sprite Collision Interrupt Check
			;-----------------------------------
+				lda #$04
				and $d01a								;  Sprite-Sprite collision interrupt enabled.
				bit $d019
				beq +
			;-----------------------------------
			; Sprite Collision Interrupt
			;-----------------------------------
				inc $0427
				inc $d827
				lda #$04
				sta $d019
			;-----------------------------------
			; Reset Sprite Collision Registers
			;-----------------------------------
+				lda $d01e								;	$D01E = Sprite-sprite collision register (per bit welke sprites).
				lda $d01f								;	$D01F = Sprite-background collision register.
				pla
				tay
				pla
				tax
				pla
				rti
				