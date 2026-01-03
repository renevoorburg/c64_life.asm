

*=$0801
.byte $0c,$08,$b5,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00
jmp main

// .const CHROUT = $ffd2
// .const PLOT   = $fff0

.const SCREEN_WIDTH  = 40
.const SCREEN_HEIGHT = 25

.const ROW = $fd
.const COL = $fe

main:
    lda #$93
    jsr $ffd2

    lda #0
    sta COL

new_column:
    lda #0
    sta ROW

column_print:
    ldx ROW
    ldy COL
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

rowlo:
    .fill 25, <(SCREEN + i*40)
rowhi:
    .fill 25, >(SCREEN + i*40)

plot_char:
    ldx ROW
    lda rowlo,x
    sta SCRPTRL
    lda rowhi,x
    sta SCRPTRH
    ldy COL
    lda #'1'
    sta (SCRPTRL),y
    rts