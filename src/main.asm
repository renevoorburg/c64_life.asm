// conway's game of life
// rv

*=$0801
.byte $0c,$08,$b5,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00
jmp setup_board

.const SCREEN_WIDTH  = 40
.const SCREEN_HEIGHT = 25
.const SCREEN = $0400

.const ALIVE = $2a // '*'
.const EMPTY = $20 // ' '
.const DYING = $2d // '-'
.const BORN  = $2b // '+'

.const ROW = $fb
.const COL = $fc
.const SCRPTRL = $fd
.const SCRPTRH = $fe

CURCHAR:
    .byte 0

rowlo:
    .fill 25, <(SCREEN + i*40)
rowhi:
    .fill 25, >(SCREEN + i*40)

setup_board:
    // blank screen
    lda #$93
    jsr $ffd2

    // prepare keyboard
    lda #1
    sta $0289  //  disable keyboard buffer
    lda #127
    sta $028a  // disable key repeat

    // set initial cursor position
    lda #5
    sta ROW
    sta COL

edit_loop:
    // get CURCHAR : character at current position
    ldx ROW
    ldy COL
    jsr get_char
    sta CURCHAR

draw_cursor:
    // draw_cursor as inversed character   
    eor #$80
    jsr plot_char

readkey:   
    jsr $ff9f
    jsr $ffe4
    beq readkey
    cmp #$41         // 'A'
    beq cursor_left
    cmp #$53         // 'S'
    beq cursor_right
    cmp #$57         // 'W'
    beq cursor_up
    cmp #$5A         // 'Z'
    beq cursor_down
    cmp #$51         // 'Q'
    beq calculate_next_gen
    cmp #$20         // ' '
    beq toggle_cell
    jmp readkey  


cursor_left:
    lda COL
    beq readkey
    lda CURCHAR
    jsr plot_char
    dec COL
    jmp edit_loop


cursor_right: 
    lda COL
    cmp #(SCREEN_WIDTH-1)
    beq readkey
    lda CURCHAR
    jsr plot_char
    inc COL
    jmp edit_loop   


cursor_up: 
    lda ROW
    beq readkey
    lda CURCHAR
    jsr plot_char
    dec ROW
    jmp edit_loop


cursor_down: 
    lda ROW
    cmp #(SCREEN_HEIGHT-1)
    beq readkey
    lda CURCHAR
    jsr plot_char
    inc ROW
    jmp edit_loop


toggle_cell:
    lda CURCHAR
    cmp #ALIVE
    beq _remove_cell
    lda #ALIVE
_set_curchar:
    sta CURCHAR
    jmp draw_cursor
_remove_cell:
    lda #EMPTY
    jmp _set_curchar


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

COUNTER:
    .byte

calculate_next_gen:
    ldy #0
_new_column:
    sty COL
    ldx #0
_new_row:
    stx ROW
    
    // do stuff
    // lda #0
    // sta COUNTER

    // here we count:
    lda #$2a
    jsr plot_char
    ldy COL
    ldx ROW

    // lda COUNTER
    // cmp #3
    // beq cell_born


_cont:    
    inx
    cpx #SCREEN_HEIGHT
    bne _new_row
    iny
    cpy #SCREEN_WIDTH
    bne _new_column

// update screen

    rts

cell_born:
    lda #BORN
    jmp _cont

cell_lives:
    lda #ALIVE
    jmp _cont

cell_dies:
    lda #DYING
    jmp _cont

