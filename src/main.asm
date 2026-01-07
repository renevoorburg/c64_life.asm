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


COL_SAVE:
    .byte  0
ROW_SAVE:
    .byte  0

count_cell:
    jsr get_char
    cmp #ALIVE
    beq increase_counter
    cmp #DYING
    beq increase_counter
    rts
increase_counter:    
    inc COUNTER
    rts

save_current_row_col:
    lda ROW
    sta ROW_SAVE
    lda COL
    sta COL_SAVE
    rts

load_current_row:
    lda ROW_SAVE
    sta ROW
    rts

load_current_col:
    lda COL_SAVE
    sta COL
    rts

goto_left_col:
    dec COL
    bmi _column_wrap_to_right
    rts
_column_wrap_to_right:
    lda #SCREEN_WIDTH-1
    sta COL
    rts

goto_top_row:
    dec ROW
    bmi _row_wrap_to_bottom
    rts
_row_wrap_to_bottom:
    lda #SCREEN_HEIGHT-1
    sta ROW
    rts

goto_right_col:
    inc COL
    lda COL
    cmp #SCREEN_WIDTH
    beq _column_wrap_to_left
    rts
_column_wrap_to_left:
    lda #0
    sta COL
    rts

goto_bottom_row:
    inc ROW
    lda ROW
    cmp #SCREEN_HEIGHT
    beq _row_wrap_to_top
    rts
_row_wrap_to_top:
    lda #0
    sta ROW
    rts

check_row_before:
    jsr load_current_row
    jsr goto_top_row
    jsr count_cell
    rts

check_central_row:
    jsr load_current_row
    jsr count_cell
    rts

check_row_after:
    jsr load_current_row
    jsr goto_bottom_row
    jsr count_cell
    rts

calculate_next_gen:
    // remove cursor:
    lda CURCHAR
    jsr plot_char

next_gen_loop:
    ldy #0
_new_column:
    sty COL
    ldx #0
_new_row:
    stx ROW
    
    lda #0
    sta COUNTER

    jsr save_current_row_col

    jsr goto_left_col
    // left col:
    jsr check_row_before
    jsr check_central_row
    jsr check_row_after

    jsr load_current_col
    // central col:
    jsr check_row_before
    jsr load_current_row // no count here
    jsr check_row_after

    jsr goto_right_col
    // right col:
    jsr check_row_before
    jsr check_central_row
    jsr check_row_after

    // all around counted
    // reset ROW, COL, y, x
    jsr load_current_col
    ldy COL
    jsr load_current_row
    ldx ROW

    jsr get_char
    sta CURCHAR

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

    // redraw everything, nice when not started with a blank screen
    // cmp #ALIVE
    // beq redraw_cont
    // jmp _empty

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
    jmp next_gen_loop

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

// used by redraw
_empty:
    lda #EMPTY
    jsr plot_char
    jmp redraw_cont

_fill:
    lda #ALIVE
    jsr plot_char
    jmp redraw_cont
