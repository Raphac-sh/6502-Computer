PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

E = %10000000
RW = %01000000
RS = %00100000

  .org $8000 

reset:
  ldx #$ff       ; Start value of the stack at the top (01ff)
  txs

  lda #%11111111 ; Set all pins on port B to output
  sta DDRB
  
  lda #%11100000 ; Set top 3 pins on port A to output
  sta DDRA
 
  lda #%00111000 ; Set 8-bit mode, 2-line display, 5x8 font
  jsr lcd_instruction
 
  lda #%00001110 ; Display on, cursor on, blink off
  jsr lcd_instruction

  lda #%00000110 ; Increment and shift cursor, don't shift display
  jsr lcd_instruction

  lda #%00000001 ; Clear display
  jsr lcd_instruction

 
  ldx #0

print:
  lda message,x  ; Load each letter's binary representation 
  beq loop
  jsr print_char 
  inx 
  jmp print
  
loop:
  jmp loop

message: .asciiz "DOOM !!!"

lcd_wait:
  pha            ; Remember A value 

  lda #%00000000 ; Port B is input
  sta DDRB
lcd_busy:
  lda #RW        ; Set RW bit (reading)
  sta PORTA
  lda #(RW | E)  ; Set E bit to read data
  sta PORTA
  lda PORTB      ; Read data from port B (data lines)

  and #%10000000 ; Focus just on the busy flag
  bne lcd_busy   ; Wait if the lcd is busy
 
  lda #RW        ; Clear E bit (finished)
  sta PORTA
  lda #%11111111 ; Port B is output
  sta DDRB

  pla            ; Get back A value
  rts

lcd_instruction:
  jsr lcd_wait   ; Wait if the lcd is busy

  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  lda #E         ; Set E bit to send instruction
  sta PORTA
  lda #0         ; Clear E bit (finished)
  sta PORTA
  rts

print_char:
  jsr lcd_wait   ; Wait if the lcd is busy

  sta PORTB
  lda #RS        ; Set RS bit (data)  
  sta PORTA
  lda #(RS | E)  ; Set E bit to send data
  sta PORTA
  lda #RS        ; Clear E bit (finished)
  sta PORTA
  rts


  .org $fffc
  .word reset
  .word $0000
