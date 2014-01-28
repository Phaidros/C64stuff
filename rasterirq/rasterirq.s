VIC=$d000
FRAME=$d020
BACK=$d021
CURSOR=646
VIC_IRQr=$d019
VIC_IRQm=$d01a
VIC_RASTER=$d012

.macro print addr
 LDA #<addr
 LDY #>addr
 JSR $AB1E
.endmacro

.macro print_int addr
  LDX #<addr
  LDA #>addr
  JSR $BDCD
.endmacro

.DATA
raster0:	; Rasterzeile für Beginn Status 0
  .byte 100
  
raster1:	; Rasterzeile für Beginn Status 1
  .byte 105
  
color0:		; Rahmenfarbe für Status 0
  .byte $00
  
color1:		; Rahmenfarbe für Status 1
  .byte $01
  
status:
  .byte $00
  
raster_final:
  .byte 200
  
raster0_str:
  .asciiz "raster0: "
  .byte 0
  
raster1_str:
  .asciiz "raster1: "
  .byte 0 

color0_str:
  .asciiz "color0 : "
  .byte 0

color1_str:
  .asciiz "color1 : "
  .byte 0
  
cr_str:
  .byte $0D, $00
  
.CODE
  SEI		; Interrupts aus
  
  LDA #$00	; eigenen Status initialisieren
  STA status

  LDA #$01
  STA VIC_IRQm	; VIC-RasterIRQ einschalten
  
  LDA raster1	; erste Rasterzeile laden
  STA VIC_RASTER
  
  LDA #$1B	; Bit 8 der Rasterzeile löschen
  STA $D011
  
		; neuen IRQ-Handler installieren
  LDA #<irqhandler
  STA $0314
  LDA #>irqhandler
  STA $0315
  
  CLI		; Interrupts wieder an

  print raster0_str
  print_int raster0
  print cr_str
  print raster1_str
  print_int raster1
  print cr_str
  print color0_str
  print_int color0
  print cr_str
  print color1_str
  print_int color1
  print cr_str

begin_loop:
  LDY #$10
midloop:
  LDX #$00
loop:
  DEX
  CPX #$00
  BNE loop
  DEY
  CPY #$00
  BNE midloop
  LDA raster1
  CLC
  ADC #$01
  STA raster1
  CMP raster_final
  BEQ ende
  JMP begin_loop
ende:  
  
  RTS		; Programmende

kernel:
  JMP $EA31	; zurück in den Kernel (normaler IRQ)
  
irqhandler: 	; Der Kernel sichert die Register für uns
  LDA VIC_IRQr	; IRQ durch VIC ausgelöst?
  AND #$80	
  BEQ kernel	; wenn nein -> zurück zum kernel
  
  LDA #$ff	; VIC-IRQs bestätigen
  STA VIC_IRQr
  
  LDA status	; eigenen Status ermitteln
  BNE status1
  
status0:
  LDA color0
  STA FRAME

  LDA #$01	; neuen Status speichern
  STA status
  LDA raster1	; Rasterzeile für neuen Status einstellen
  STA VIC_RASTER
  
  JMP finally
status1:
  LDA color1
  STA FRAME

  LDA #$00	; neuen Status speichern
  STA status
  LDA raster0	; Rasterzeile für neuen Status einstellen
  STA VIC_RASTER
finally:  
  INC BACK
  DEC BACK
exit_irq:
  JMP $EA7E	; zurück in den Kernel