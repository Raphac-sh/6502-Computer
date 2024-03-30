  .org $8000

reset:
  lda #$ff
  sta $6002

  lda #$00
  sta $6000

loop:
  adc #$01
  sta $6000

  jmp loop

  .org $fffc
  .word reset
  .word $0000
