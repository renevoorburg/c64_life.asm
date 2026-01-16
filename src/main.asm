// conway's game of life
// rv

// speedtest: glider down 33s

*=$0801
BasicUpstart2(setup_board)

.const SCREEN_WIDTH  = 40
.const SCREEN_HEIGHT = 25
.const SCREEN0 = $0400
.const SCREEN1 = $2000 

.const ALIVE = $2a // '*'
.const EMPTY = $20 // ' '

.const CURCHAR = $02
.const COUNTER = $03

.const S0BASELO = $f7
.const S0BASEHI = $f8
.const S1BASELO = $f9
.const S1BASEHI = $fa
.const COL = $fb
.const ROW = $fc
.const SCRPTRLO = $fd
.const SCRPTRHI = $fe

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

.macro COUNT_CELL_ROWPTR_SET() {
    lda (SCRPTRLO),y
    eor #ALIVE
    bne !+
    inc COUNTER
!:
}

.macro DEX_WRAP() {
    dex
    bpl !+
    ldx #SCREEN_HEIGHT-1
!:
}

.macro INX_WRAP() {
    inx
    cpx #SCREEN_HEIGHT
    bcc !+
    ldx #0
!:
}

.macro DEY_WRAP() {
    dey
    bpl !+
    ldy #SCREEN_WIDTH-1
!:
}

.macro INY_WRAP() {
    iny
    cpy #SCREEN_WIDTH
    bcc !+
    ldy #0
!:
}

calculate_next_gen:
    // remove inverted cursor:
    lda CURCHAR
    jsr plot_char

    jsr display_screen0 // setup screen for switching
next_gen_loop:
    ldy #1
_new_column:
    ldx #1
_new_row:
    stx ROW
    
    lda #0
    sta COUNTER

    // save state
    stx ROW
    sty COL

    // top row
    dex
    dey
    COUNT_CELL()        // now the ROWPTR is set 
    iny
    COUNT_CELL_ROWPTR_SET()
    iny
    COUNT_CELL_ROWPTR_SET()

    // middle row
    ldx ROW
    ldy COL
    dey
    COUNT_CELL()

    // centre_cell -> CURCHAR:
    iny
    lda (SCRPTRLO),y
    sta CURCHAR

    iny
    COUNT_CELL_ROWPTR_SET()    

    // bottom row
    ldx ROW
    inx
    ldy COL
    dey
    COUNT_CELL() 
    iny
    COUNT_CELL_ROWPTR_SET()  
    iny
    COUNT_CELL_ROWPTR_SET() 

    ldy COL
    ldx ROW

    lda CURCHAR
    cmp #ALIVE
    bne no_cell_next_gen
    
    lda COUNTER
    cmp #02
    bcc set_empty_next_gen
    cmp #04
    bcs set_empty_next_gen
set_alive_next_gen:
    lda #ALIVE
    jsr plot_char
    jmp continue_next_gen_loop

continue_next_gen_loop:    
    inx
    cpx #SCREEN_HEIGHT-1
    bne new_row_jmp
    iny
    cpy #SCREEN_WIDTH-1
    bne new_column_jmp
    
    jsr flip_screen

// read key
    jsr $ff9f
    jsr $ffe4
    cmp #$51
    beq quit
    jmp next_gen_loop

// trampoline:
new_row_jmp:
    jmp _new_row  
new_column_jmp:
    jmp _new_column

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

no_cell_next_gen:
    lda COUNTER
    cmp #03
    beq set_alive_next_gen
set_empty_next_gen:
    lda #EMPTY
    jsr plot_char
    jmp continue_next_gen_loop
