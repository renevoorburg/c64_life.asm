

*=$0801
.byte $0c,$08,$b5,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00
jmp main

// .const CHROUT = $ffd2
// .const PLOT   = $fff0

.const SCREEN_WIDTH  = 40
.const SCREEN_HEIGHT = 19

.const ROW = $fd
.const COL = $fe

main:
    lda #0
    sta COL

new_column:
    lda #0
    sta ROW

column_print:
    ldx ROW
    ldy COL
    // clc
    // jsr PLOT

    // lda #'*'
    // jsr CHROUT
    jsr plot_char

    inc ROW
    lda ROW
    cmp #SCREEN_HEIGHT
    bne column_print

    inc COL
    lda COL
    cmp #SCREEN_WIDTH
    bne new_column
    rts

.const  SCRPTRL = $fb
.const  SCRPTRH = $fc
.const  SCREEN = $0400

plot_char:
    lda #<SCREEN
    sta SCRPTRL
    lda #>SCREEN
    sta SCRPTRH

    ldx ROW  
    beq doneRow

add40:
    clc
    lda SCRPTRL
    adc #40
    sta SCRPTRL
    bcc noc
    inc SCRPTRH
noc:
    dex
    bne add40

doneRow:
    lda #'1'
    ldy COL
    sta (SCRPTRL),y
    rts