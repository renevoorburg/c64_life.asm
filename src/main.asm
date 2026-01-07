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
COUNTER:
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
    beq jump_calculate_next_gen
    cmp #$20         // ' '
    beq toggle_cell
    jmp readkey  

jump_calculate_next_gen:
    jmp calculate_next_gen

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

jmp calculate_next_gen

_compare:
    jsr get_char
    cmp #ALIVE
    beq __count
    cmp #DYING
    beq __count
    rts
__count:    
    inc COUNTER
    rts

set_left_col:
    dec COL
    bmi _column_wrap_right
    rts
_column_wrap_right:
    lda #SCREEN_WIDTH-1
    sta COL
    rts

set_mid_col:
    lda COL
    cmp #SCREEN_WIDTH-1
    beq _column_restore_wrapped_right
    inc COL
    rts
_column_restore_wrapped_right:
    lda #0
    sta COL
    rts

set_right_col:
    inc COL
    lda COL
    cmp #SCREEN_WIDTH
    beq _column_wrap_left
    rts
_column_wrap_left:
    lda #0
    sta COL
    rts

reset_col:
    dec COL
    bmi _column_restore_wrapped_left
    rts
_column_restore_wrapped_left:
    lda #SCREEN_WIDTH-1
    sta COL
    rts


// left column:
_check_topleft: 
    jsr set_left_col
    dec ROW
    jsr _compare
    rts
_check_left:
    inc ROW
    jsr _compare
    rts
_check_bottomleft:
    inc ROW
    jsr _compare
    rts

// mid column:
_check_below:
    jsr set_mid_col
    jsr _compare
    rts
_check_above:
    dec ROW
    dec ROW
    jsr _compare
    rts


_check_topright:
    jsr set_right_col
    jsr _compare
    rts
_check_right:
    inc ROW
    jsr _compare
    rts
_check_bottomright:
    inc ROW
    jsr _compare
    rts

calculate_next_gen:
    lda CURCHAR
    jsr plot_char

    ldy #0
_new_column:
    sty COL
    ldx #0
_new_row:
    stx ROW
    
    lda #0
    sta COUNTER

    jsr _check_topleft
    jsr _check_left
    jsr _check_bottomleft
    jsr _check_below
    jsr _check_above
    jsr _check_topright
    jsr _check_right
    jsr _check_bottomright

_all_counted:
    // restore COL, ROW. y, x
    jsr reset_col
    ldy COL
    dec ROW
    ldx ROW

    jsr get_char
    sta CURCHAR

    // lda COUNTER
    // jsr plot_char
    // ldx ROW
    // ldy COL

    cmp #ALIVE
    beq next_with_cell
    jmp next_no_cell

_cont:    
    inx
    cpx #SCREEN_HEIGHT
    bne _new_row
    iny
    cpy #SCREEN_WIDTH
    bne _new_column
    
// redraw
    ldy #0
redraw_new_column:
    sty COL
    ldx #0
redraw_new_row:
    stx ROW
    
    jsr get_char
    sta CURCHAR
    cmp #DYING
    beq _empty
    cmp #BORN
    beq _fill

redraw_cont:
    ldx ROW
    ldy COL
    inx
    cpx #SCREEN_HEIGHT
    bne redraw_new_row
    iny
    cpy #SCREEN_WIDTH
    bne redraw_new_column
    
// read key
    jsr $ff9f
    jsr $ffe4
    cmp #$51
    beq quit
    jmp calculate_next_gen

 quit:
    rts


next_with_cell:
    lda COUNTER
    cmp #02
    bcc next_is_death
    cmp #04
    bcs next_is_death
    jmp _cont

next_no_cell:
    lda COUNTER
    cmp #03
    beq next_is_born
    jmp _cont

next_is_death:
    lda #DYING
    jsr plot_char
    ldx ROW
    ldy COL
    jmp _cont

next_is_born:
    lda #BORN
    jsr plot_char
    ldx ROW
    ldy COL
    jmp _cont

_empty:
    lda #EMPTY
    jsr plot_char
    ldx ROW
    ldy COL
    jmp redraw_cont

_fill:
    lda #ALIVE
    jsr plot_char
    ldx ROW
    ldy COL
    jmp redraw_cont
