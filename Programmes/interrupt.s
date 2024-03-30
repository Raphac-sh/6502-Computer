PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003
PCR = $600c
IFR = $600d
IER = $600e

value = $0200     ; 2 bytes -> value to divide/print
mod10 = $0202     ; Remainders of the val's divisions
message = $0204   ; 6 bytes
counter = $020a   ; 2 bytes

E = %10000000
RW = %01000000
RS = %00100000

  .org $8000 

reset:
  ldx #$ff       ; Start value of the stack at the top (01ff)
  txs
  cli            ; Enable interrupt requests

  lda #$82
  sta IER
  lda #$00
  sta PCR

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

  lda #0
  sta counter
  sta counter + 1

loop:
  lda #%00000010 ; Cursor at the start 
  jsr lcd_instruction

  lda #0
  sta message

  ; Initialize the value (number to convert)
  sei            ; Disabling interrupts
  lda counter 
  sta value
  lda counter + 1
  sta value + 1
  cli            ; Re-enabling interrupts

divide:
  ; Initialize the remainder
  lda #0
  sta mod10
  sta mod10 + 1
  clc

  ldx #16
divloop:
  ; Rotate the quotient (carry bit) and remainder
  rol value
  rol value + 1
  rol mod10
  rol mod10 + 1

  ; a,y = dividend - divisor
  sec
  lda mod10
  sbc #10
  tay               ; Save low byte in Y register 
  lda mod10 + 1
  sbc #0
  bcc ignore_result ; Branch if dividend < divisor
  sty mod10
  sta mod10 + 1
  
ignore_result:
  dex
  bne divloop
  rol value         ; shift in the last bit of the quotient (carry bit)
  rol value + 1

  lda mod10
  clc
  adc #"0"
  jsr push_car    

  ; if value != 0, then continue dividing
  lda value
  ora value + 1
  bne divide        ; Branch if not 0 (-> convert the next digit)

  ldx #0
print:
  lda message,x  ; Load each letter's binary representation 
  beq loop
  jsr print_char 
  inx 
  jmp print
 

  jmp loop

; Add the char in the A register to the begining of message
; (null terminated string)
push_car:
  pha            ; Push new first char onto stack
  ldy #0

char_loop:
  lda message,y  ; Get char on string and put into X
  tax
  pla
  sta message,y  ; Pull char off stack and add it to the string
  iny
  txa
  pha            ; push char from string onto the stack
  bne char_loop

  pla
  sta message,y  ; pull the null of the stack and put it end of string

  rts


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

nmi:             ; Intrttupy handlers
irq:
  pha
  txa
  pha
  tya
  pha            ; Save X and Y values on stack

  inc counter
  bne exit_irq
  inc counter + 1
exit_irq:

  ldx #$ff
  ldy #$ff
delay:
  dex
  bne delay
  dey
  bne delay      ; Delay to prevent bouncing

  bit PORTA      ; Clear interrupt (interface adapter)

  pla
  tay
  pla
  tax
  pla            ; Get X and Y values back

  rti

  .org $fffa
  .word nmi
  .word reset
  .word irq
