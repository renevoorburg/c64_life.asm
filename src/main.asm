// conway's game of life
// rv

// speedtest: glider down 49s

*=$0801
BasicUpstart2(setup_board)

.const SCREEN_WIDTH  = 40
.const SCREEN_HEIGHT = 25
.const SCREEN0 = $0400
.const SCREEN1 = $2000 

.const ALIVE = $2a // '*'
.const EMPTY = $20 // ' '

.const S0BASELO = $f7
.const S0BASEHI = $f8
.const S1BASELO = $f9
.const S1BASEHI = $fa
.const COL = $fb
.const ROW = $fc
.const SCRPTRLO = $fd
.const SCRPTRHI = $fe

CURCHAR:
    .byte 0
COUNTER:
    .byte 0

rowoff0_lo:
    .fill 25, <(SCREEN0 + i*40)
rowoff0_hi:
    .fill 25, >(SCREEN0 + i*40)

rowoff1_lo:
    .fill 25, <(SCREEN1 + i*40)
rowoff1_hi:
    .fill 25, >(SCREEN1 + i*40)

key:
    .byte 0

setup_board:
    // blank screen
    // lda #$93
    // jsr $ffd2

    // prepare keyboard
    lda #1
    sta $0289  //  disable keyboard buffer
    lda #127
    sta $028a  // disable key repeat

    // clean  screen1
    ldy #0
redraw_new_column:
    sty COL
    ldx #0
redraw_new_row:
    stx ROW
    lda #EMPTY
    jsr plot_char1
    ldx ROW
    ldy COL
    inx
    cpx #SCREEN_HEIGHT
    bne redraw_new_row
    iny
    cpy #SCREEN_WIDTH
    bne redraw_new_column


    // set initial cursor position
    ldx #5
    ldy #5

edit_loop:
    // get CURCHAR : character at current position
    jsr get_char0
    sta CURCHAR

draw_cursor:
    // draw_cursor as inversed character   
    eor #$80
    jsr plot_char0

readkey:
    stx ROW
    sty COL
    jsr $ff9f
    jsr $ffe4
    sta key
    ldx ROW
    ldy COL
    lda key
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
    cpy #0
    beq readkey
    lda CURCHAR
    jsr plot_char0
    dey
    jmp edit_loop

cursor_right: 
    cpy #(SCREEN_WIDTH-1)
    beq readkey
    lda CURCHAR
    jsr plot_char0
    iny
    jmp edit_loop   

cursor_up: 
    cpx #0
    beq readkey
    lda CURCHAR
    jsr plot_char0
    dex
    jmp edit_loop

cursor_down: 
    cpx #(SCREEN_HEIGHT-1)
    beq readkey
    lda CURCHAR
    jsr plot_char0
    inx
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


flip_screen:
    lda $d018
    and #$f0
    cmp #$10
    beq display_screen1

display_screen0:
    lda #$14        // show screen0 - $0400
    sta $d018

    // write to screen1
    lda #<plot_char1
    sta plot_char + 1
    lda #>plot_char1
    sta plot_char + 2

    // read from screen0
    lda #<get_char0
    sta get_char + 1
    lda #>get_char0
    sta get_char + 2
    rts

display_screen1:
    lda #$84        // show screen1 - $0800
    sta $d018
    // write to screen0
    lda #<plot_char0
    sta plot_char + 1
    lda #>plot_char0
    sta plot_char + 2

    // read from screen1
    lda #<get_char1
    sta get_char + 1
    lda #>get_char1
    sta get_char + 2
    rts

plot_char:
    jmp plot_char0 // dynamically changed

plot_char0:
    pha
    lda rowoff0_lo,x
    sta SCRPTRLO
    lda rowoff0_hi,x
    sta SCRPTRHI
    pla
    sta (SCRPTRLO),y
    rts

plot_char1:
    pha
    lda rowoff1_lo,x
    sta SCRPTRLO
    lda rowoff1_hi,x
    sta SCRPTRHI
    pla
    sta (SCRPTRLO),y
    rts

get_char:
    jmp get_char0 // dynamically changed

get_char0:
    lda rowoff0_lo,x
    sta SCRPTRLO
    lda rowoff0_hi,x
    sta SCRPTRHI
    lda (SCRPTRLO),y
    rts

get_char1:
    lda rowoff1_lo,x
    sta SCRPTRLO
    lda rowoff1_hi,x
    sta SCRPTRHI
    lda (SCRPTRLO),y
    rts

// 


.macro COUNT_CELL() {
    jsr get_char
    eor #ALIVE
    bne !+
    inc COUNTER
!:
}

calculate_next_gen:
    // remove inverted cursor:
    lda CURCHAR
    jsr plot_char

    jsr display_screen0 // setup screen for switching
next_gen_loop:
    ldy #0
_new_column:
    ldx #0
_new_row:
    stx ROW
    
    lda #0
    sta COUNTER

    stx ROW
    sty COL

// left column:
    dey
    bmi _column_wrap_to_right
    jmp cell_top_left
_column_wrap_to_right:
    ldy #SCREEN_WIDTH-1

cell_top_left:
    dex
    bmi _row_wrap_to_bottom_leftcol
    jmp count_top_left
_row_wrap_to_bottom_leftcol:
    ldx #SCREEN_HEIGHT-1
count_top_left:
    COUNT_CELL()

cell_mid_left:
    ldx ROW
    COUNT_CELL()

cell_bottom_left:
    inx
    cpx #SCREEN_HEIGHT
    beq _row_wrap_to_top
    jmp count_bottom_left
_row_wrap_to_top:
    ldx #0
count_bottom_left:
    COUNT_CELL()

// central column:
    ldy COL
    ldx ROW
    dex
    bmi _row_wrap_to_bottom_midcol
    jmp cell_top_center
_row_wrap_to_bottom_midcol:
    ldx #SCREEN_HEIGHT-1
cell_top_center:
    COUNT_CELL()

    ldx ROW
    inx
    cpx #SCREEN_HEIGHT
    beq _row_wrap_to_top_midcol
    jmp cell_bottom_center
_row_wrap_to_top_midcol:
    ldx #0
cell_bottom_center:
    COUNT_CELL()

// right col:
    iny
    cpy #SCREEN_WIDTH
    beq _column_wrap_to_left
    jmp cell_top_right
_column_wrap_to_left:
    ldy #0
    
cell_top_right:
    ldx ROW
    dex
    bmi _row_wrap_to_bottom_rightcol
    jmp count_cell_top_right
_row_wrap_to_bottom_rightcol:
    ldx #SCREEN_HEIGHT-1
count_cell_top_right:
    COUNT_CELL()

    ldx ROW
    COUNT_CELL()

    inx
    cpx #SCREEN_HEIGHT
    beq _row_wrap_to_top_rightcol
    jmp count_bottom_right
_row_wrap_to_top_rightcol:
    ldx #0
count_bottom_right:
    COUNT_CELL()


all_around_counted:
    // reset ROW, COL, y, x
    ldy COL
    ldx ROW

    jsr get_char
    sta CURCHAR

    cmp #ALIVE
    beq next_with_cell
    jmp next_no_cell

_cont:    
    inx
    cpx #SCREEN_HEIGHT
    bne new_row_jmp
    iny
    cpy #SCREEN_WIDTH
    bne new_column_jmp
    

// trampoline:
    jmp redraw
new_row_jmp:
    jmp _new_row  
new_column_jmp:
    jmp _new_column


redraw:
    jsr flip_screen

// read key
    jsr $ff9f
    jsr $ffe4
    cmp #$51
    beq quit
    cmp #$45         // 'E'
    beq jump_edit_loop
    jmp next_gen_loop

 quit:
    lda #$14        // show screen0 - $0400
    sta $d018

    // reset dynamic code
    lda #<plot_char0
    sta plot_char + 1
    lda #>plot_char0
    sta plot_char + 2

    lda #<get_char0
    sta get_char + 1
    lda #>get_char0
    sta get_char + 2

    rts

jump_edit_loop:
    jmp edit_loop

next_with_cell:
    lda COUNTER
    cmp #02
    bcc next_is_empty
    cmp #04
    bcs next_is_empty
    jmp next_is_alive

next_no_cell:
    lda COUNTER
    cmp #03
    beq next_is_alive
    jmp next_is_empty

next_is_empty:
    lda #EMPTY
    jsr plot_char

next_is_alive:
    lda #ALIVE
    jsr plot_char
 