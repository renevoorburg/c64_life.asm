

*=$0801
.byte $0c,$08,$b5,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00
jmp main

// .const CHROUT = $ffd2
// .const PLOT   = $fff0

.const SCREEN_WIDTH  = 40
.const SCREEN_HEIGHT = 25

.const ROW = $fb
.const COL = $fc

.const  SCRPTRL = $fd
.const  SCRPTRH = $fe

.const CURCHAR = $ff

.const  SCREEN = $0400

.const CRSRCHR = 160
.const SPACECHR = 32

main:
    // blank screen
    // lda #$93
    // jsr $ffd2

    // prepare keyboard
    lda #1
    sta $0289  //  disable keyboard buffer
    lda #127
    sta $028a  // disable key repeat

    // initial position
    lda #5
    sta ROW
    sta COL

print:
    ldx ROW
    ldy COL
    jsr get_char
    sta CURCHAR
    lda #CRSRCHR
    jsr plot_char

readkey:   
    jsr $ff9f
    jsr $ffe4
    beq readkey
    cmp #$41         // 'A' in PETSCII
    beq left
    cmp #$53         // 'S' in PETSCII
    beq right
    cmp #$57         // 'W' in PETSCII
    beq up
    cmp #$5A         // 'Z' in PETSCII
    beq down
    cmp #$51         // 'Q' in PETSCII
    beq end

    jmp readkey
    
left:
    lda COL
    beq readkey
    lda CURCHAR
    jsr plot_char
    dec COL
    jmp print

right: 
    lda COL
    cmp #(SCREEN_WIDTH-1)
    beq readkey
    lda CURCHAR
    jsr plot_char
    inc COL
    jmp print   

up: 
    lda ROW
    beq readkey
    lda CURCHAR
    jsr plot_char
    dec ROW
    jmp print

down: 
    lda ROW
    cmp #(SCREEN_HEIGHT-1)
    beq readkey
    lda CURCHAR
    jsr plot_char
    inc ROW
    jmp print

end:
    rts


rowlo:
    .fill 25, <(SCREEN + i*40)
rowhi:
    .fill 25, >(SCREEN + i*40)

plot_char:
    pha
    ldx ROW
    lda rowlo,x
    sta SCRPTRL
    lda rowhi,x
    sta SCRPTRH
    ldy COL
    pla
    sta (SCRPTRL),y
    rts

get_char:
    ldx ROW
    lda rowlo,x
    sta SCRPTRL
    lda rowhi,x
    sta SCRPTRH
    ldy COL
    lda (SCRPTRL),y
    rts