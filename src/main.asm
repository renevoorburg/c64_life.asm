//wip 

*=$0801
BasicUpstart2(main)

.const ALIVE = $2a // '*'
.const EMPTY = $20 // ' '

.const SCREEN_WIDTH  = 40
.const SCREEN_HEIGHT = 25
.const SCREEN = $0400
.const COUNTS = $0c00

.const SCR_LINE_PTRLO = $fd
.const SCR_LINE_PTRHI = $fe

.const CNT_CUR_LINE_PTRLO = $fb
.const CNT_CUR_LINE_PTRHI = $fc

.const CNT_PREV_LINE_PTRLO = $f7
.const CNT_PREV_LINE_PTRHI = $f8

.const CNT_NEXT_LINE_PTRLO = $f9
.const CNT_NEXT_LINE_PTRHI = $fa


ROWOFF_SCREEN_LO:
    .for (var i=0; i<SCREEN_HEIGHT; i++) .byte <(SCREEN + i*SCREEN_WIDTH)
ROWOFF_SCREEN_HI:
    .for (var i=0; i<SCREEN_HEIGHT; i++) .byte >(SCREEN + i*SCREEN_WIDTH)

ROWOFF_COUNTS_LO:
    .for (var i=0; i<SCREEN_HEIGHT; i++) .byte <(COUNTS + i*SCREEN_WIDTH)
ROWOFF_COUNTS_HI:
    .for (var i=0; i<SCREEN_HEIGHT; i++) .byte >(COUNTS + i*SCREEN_WIDTH)

// Vorige rij met wrap
ROWOFF_COUNTS_PREV_LO:
    .for (var i=0; i<SCREEN_HEIGHT; i++) .byte <(COUNTS + ((i==0) ? (SCREEN_HEIGHT-1) : (i-1)) * SCREEN_WIDTH)
ROWOFF_COUNTS_PREV_HI:
    .for (var i=0; i<SCREEN_HEIGHT; i++) .byte >(COUNTS + ((i==0) ? (SCREEN_HEIGHT-1) : (i-1)) * SCREEN_WIDTH)

// Volgende rij met wrap 
ROWOFF_COUNTS_NEXT_LO:
    .for (var i=0; i<SCREEN_HEIGHT; i++) .byte <(COUNTS + ((i==(SCREEN_HEIGHT-1)) ? 0 : (i+1)) * SCREEN_WIDTH)
ROWOFF_COUNTS_NEXT_HI:
    .for (var i=0; i<SCREEN_HEIGHT; i++) .byte >(COUNTS + ((i==(SCREEN_HEIGHT-1)) ? 0 : (i+1)) * SCREEN_WIDTH)


COLUMN:
    .byte 0


// reset counts to zero
reset_counts:
    lda #<COUNTS
    sta $fb
    lda #>COUNTS
    sta $fc
    lda #$0
    ldx #$03                // 3 x 256 cells
reset_page_loop:
    ldy #$00
reset_cell_loop:
    sta ($fb),y
    iny
    bne reset_cell_loop
    inc $fc
    dex
    bne reset_page_loop
    ldy #$00                // remaining 232 bytes 
reset_tail_loop:
    sta ($fb),y
    iny
    cpy #$E8         
    bne reset_tail_loop
    rts


main:
    jsr reset_counts
    jmp update_counts

next_cell_jmp:
    jmp next_cell

//
// update COUNTS for whole board:
//
update_counts:
    ldx #0                  // first ROW
    
next_column:
    ldy #0                  // first COLUMN of new ROW

    lda ROWOFF_SCREEN_LO,x
    sta SCR_LINE_PTRLO
    lda ROWOFF_SCREEN_HI,x
    sta SCR_LINE_PTRHI    

    lda ROWOFF_COUNTS_LO,x
    sta CNT_CUR_LINE_PTRLO
    lda ROWOFF_COUNTS_HI,x
    sta CNT_CUR_LINE_PTRHI

    lda ROWOFF_COUNTS_PREV_LO,x
    sta CNT_PREV_LINE_PTRLO
    lda ROWOFF_COUNTS_PREV_HI,x
    sta CNT_PREV_LINE_PTRHI

    lda ROWOFF_COUNTS_NEXT_LO,x
    sta CNT_NEXT_LINE_PTRLO
    lda ROWOFF_COUNTS_NEXT_HI,x
    sta CNT_NEXT_LINE_PTRHI

check_cell:
    lda (SCR_LINE_PTRLO),y
    cmp #ALIVE
    bne next_cell_jmp
 
    lda (CNT_PREV_LINE_PTRLO),y
    adc #1
    sta (CNT_PREV_LINE_PTRLO),y

    lda (CNT_NEXT_LINE_PTRLO),y
    adc #1
    sta (CNT_NEXT_LINE_PTRLO),y

    sty COLUMN

    dey
    bpl no_wrap_to_right
    ldx #SCREEN_WIDTH-1
no_wrap_to_right:
    clc
    
    lda (CNT_CUR_LINE_PTRLO),y
    adc #1
    sta (CNT_CUR_LINE_PTRLO),y
    
    lda (CNT_PREV_LINE_PTRLO),y
    adc #1
    sta (CNT_PREV_LINE_PTRLO),y

    lda (CNT_NEXT_LINE_PTRLO),y
    adc #1
    sta (CNT_NEXT_LINE_PTRLO),y

    ldy COLUMN
    iny
    cpy #SCREEN_WIDTH
    bne no_wrap_to_left
    ldy #0
no_wrap_to_left:
    clc

    lda (CNT_CUR_LINE_PTRLO),y
    adc #1
    sta (CNT_CUR_LINE_PTRLO),y

    lda (CNT_PREV_LINE_PTRLO),y
    adc #1
    sta (CNT_PREV_LINE_PTRLO),y

    lda (CNT_NEXT_LINE_PTRLO),y
    adc #1
    sta (CNT_NEXT_LINE_PTRLO),y

    ldy COLUMN

 next_cell:
    iny                     // next column
    cpy #SCREEN_WIDTH
    bne check_cell_jmp
    inx                     // next row
    cpx #SCREEN_HEIGHT
    bne next_column_jmp

    rts

check_cell_jmp:
    jmp check_cell

next_column_jmp:
    jmp next_column