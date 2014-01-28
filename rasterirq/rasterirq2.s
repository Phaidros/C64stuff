VIC=$d000
FRAME=$d020
BACK=$d021
CURSOR=646
VIC_IRQr=$d019
VIC_IRQm=$d01a
VIC_RASTER=$d012

RASTER1=66
RASTER2=180

.DATA

color:
  .byte $00
  
status:
  .byte $00

.CODE
  SEI		; Interrupts aus
  
  LDA #$00	; eigenen Status initialisieren
  STA status

  LDA #$7f	; Timer-IRQs der CIA ausschalten
  STA $DC0D
  STA $DD0D
  
  LDA $DC0D	; möglicherweise wartende CIA-IRQs
  LDA $DD0D	; löschen
  
  LDA #$01
  STA VIC_IRQm	; VIC-RasterIRQ einschalten
  
  LDA #RASTER1	; erste Rasterzeile laden
  STA VIC_RASTER
  
  LDA #$1B	; Bit 8 der Rasterzeile löschen
  STA $D011
  
  LDA #$35	; BASIC und KERNEL ausschalten
  STA $01
  
		; neuen IRQ-Handler installieren
  LDA #<irqhandler
  STA $fffe
  LDA #>irqhandler
  STA $ffff
  
  CLI		; Interrupts wieder an
loop:
  JMP loop	; Endlosschleife

irqhandler:
  PHA		; Register retten
  TXA
  PHA
  TYA
  PHA
  
  LDA #$ff	; VIC-IRQs bestätigen
  STA VIC_IRQr
  
  LDA status	; eigenen Status ermitteln
  BNE status1
  
status0:
  LDA #$01	; neuen Status speichern
  STA status
  LDA #RASTER2	; neue Rasterzeile einstellen
  STA VIC_RASTER
  
  JMP exit_irq
status1:
  LDA #$00	; neuen Status speichern
  STA status
  LDA #RASTER1	; neue Rasterzeile einstellen
  STA VIC_RASTER

exit_irq:  
  LDA color
  STA FRAME
  EOR #$01
  STA color
  
  PLA		; Register wiederherstellen
  TAY
  PLA
  TAX
  PLA
  RTI		; IRQhandler beenden