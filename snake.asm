;	set game state memory location
.equ    HEAD_X,         0x1000  ; Snake head's position on x
.equ    HEAD_Y,         0x1004  ; Snake head's position on y
.equ    TAIL_X,         0x1008  ; Snake tail's position on x
.equ    TAIL_Y,         0x100C  ; Snake tail's position on Y
.equ    SCORE,          0x1010  ; Score address
.equ    GSA,            0x1014  ; Game state array address

.equ    CP_VALID,       0x1200  ; Whether the checkpoint is valid.
.equ    CP_HEAD_X,      0x1204  ; Snake head's X coordinate. (Checkpoint)
.equ    CP_HEAD_Y,      0x1208  ; Snake head's Y coordinate. (Checkpoint)
.equ    CP_TAIL_X,      0x120C  ; Snake tail's X coordinate. (Checkpoint)
.equ    CP_TAIL_Y,      0x1210  ; Snake tail's Y coordinate. (Checkpoint)
.equ    CP_SCORE,       0x1214  ; Score. (Checkpoint)
.equ    CP_GSA,         0x1218  ; GSA. (Checkpoint)

.equ    LEDS,           0x2000  ; LED address
.equ    SEVEN_SEGS,     0x1198  ; 7-segment display addresses
.equ    RANDOM_NUM,     0x2010  ; Random number generator address
.equ    BUTTONS,        0x2030  ; Buttons addresses

; initialize stack pointer
addi    sp, zero, LEDS

; main
; arguments
;     none
;
; return values
;     This procedure should never return.
main:
    stw zero, HEAD_X(zero)
    stw zero, HEAD_Y(zero)
    stw zero, TAIL_X(zero)
    stw zero, TAIL_Y(zero)
    addi t0, zero, 4
    stw t0, GSA(zero)
    call main_loop

    ret

main_loop:
    call clear_leds
    call get_input
    call move_snake
    call draw_array
    call main_loop

    ret


; BEGIN: clear_leds
clear_leds:
    stw zero, LEDS(zero)
    stw zero, LEDS + 4 (zero) 
    stw zero, LEDS + 8 (zero)

    ret
; END: clear_leds


; BEGIN: set_pixel
set_pixel:
    srli t0, a0, 2  ; leds chunk index
    ldw t0, LEDS(t0); load leds chunk

    slli t1, a0, 30 ; x mod 4
    srli t1, t1, 27 ; (x mod 4) * 8
    add t1, t1, a1  ; (x mod 4) * 8 + y

    addi t2, zero, 1; bit to shift
    sll t2, t2, t1  ; shifting the bit

    or t0, t0, t2   ; update chunk
    stw t0, LEDS(a0); write update

    ret
; END: set_pixel


; BEGIN: display_score
display_score:

; END: display_score


; BEGIN: init_game
init_game:

; END: init_game


; BEGIN: create_food
create_food:
    addi t0, zero, 1
    stw t0, RANDOM_NUM(zero)
    ldw	t0, RANDOM_NUM(zero)

    andi t0, t0, 255

    addi t1, zero, 96
	blt t0, zero, create_food
	bge t0, t1, create_food

    slli t0, t0, 2
	ldw t1, GSA(t0)

    bne t1, zero, create_food

    addi t1, zero, 5
	stw t1, GSA(t0)

    ret
; END: create_food


; BEGIN: hit_test
hit_test:

; END: hit_test


; BEGIN: get_input
get_input:
    ldw t0, BUTTONS(zero)
	ldw t1, BUTTONS+4(zero)

	addi t5, t5, 31
	bne t0, t5, input_update ; update only if changed
	
	ret

input_update:
    ldw t2, HEAD_X(zero) ; get head x
	ldw t3, HEAD_Y(zero) ; get head y
	
	slli t2, t2, 5 ; 32x
	slli t3, t3, 2 ; 4y
	add t4, t2, t3 ; 32x + 4y
	addi t4, t4, GSA ; head GSA address
	
	andi t1, t1, 15	; ignore checkpoint button
		
	stw t1, 0(t4) ; update
	and t1, t1, zero ; reset edgecapture
	stw t0, BUTTONS+4(zero)
	
	ret
; END: get_input


; BEGIN: draw_array
draw_array:
	addi t0, zero, 0
	addi t6, zero, 12
	addi t5, zero, 8
	jmpi draw_loop 
	ret

; each iteration updates a pixel row 
draw_loop:
	addi t1, zero, 0
	blt t0, t6, sub_draw_loop
	ret
	
; each iteration updates a pixel
sub_draw_loop:
	slli t2, t0, 3
	add t3, t2, t1
	slli t3, t3, 2
	ldw t4, GSA(t3)
	bne t4, zero, stack_draw_array
post_draw:
	addi t1, t1, 1
	blt t1, t5, sub_draw_loop
	addi t0, t0, 1
	jmpi draw_loop 
	
stack_draw_array:
	addi sp, sp, -12 ; pop 3 times
	stw ra, 0(sp)
	stw a1, 4(sp)
	stw a0, 8(sp)

	addi a0, t0, 0
	addi a1, t1, 0
	
	call set_pixel

	addi t0,a0,0
	addi t1,a1,0

	ldw a0, 8(sp)
	ldw a1, 4(sp)
	ldw ra, 0(sp)
	addi sp, sp, 12

    jmpi post_draw
; END: draw_array


; BEGIN: move_snake
move_snake:
	ldw t0, HEAD_X(zero)
	ldw t1, HEAD_Y(zero)
	ldw t4, TAIL_X(zero)
	ldw t5, TAIL_Y(zero)
	slli t2, t0, 3
	slli t6, t4, 3
	add t2, t2, t1
	slli t2, t2, 2 
	add t6, t6, t5
	slli t6, t6, 2
	ldw t3, GSA(t2)

	addi t7, zero, 1
	beq t3, t7, head_left
	addi t7, t7, 1
	beq t3, t7, head_right
	addi t7, t7, 1		
	beq t3, t7, head_down
	addi t7, t7, 1
	beq t3, t7, head_right

	head_left:
	addi t2, t0, -1
	stw t2, HEAD_X(zero)
	ldw t3, HEAD_Y(zero)
	slli t4, t2, 3
	add t4, t4, t3
	slli t4, t4, 2 
	addi t5, zero, 1
	stw t5, GSA(t4)
	jmpi check_tail 

	head_up:
	addi t2, t1, -1
	stw t2, HEAD_Y(zero)
	ldw t3, HEAD_X(zero)
	slli t4, t3, 3
	add t4, t4, t2
	slli t4, t4, 2 
	addi t5, zero, 2
	stw t5, GSA(t4)
	jmpi check_tail 

	head_down:
	addi t2, t1, 1
	stw t2, HEAD_Y(zero)
	ldw t3, HEAD_X(zero)
	slli t4, t3, 3
	add t4, t4, t2
	slli t4, t4, 2
	addi t5, zero, 3
	stw t5, GSA(t4)
	jmpi check_tail 

	head_right:
	addi t2, t0, 1
	stw t2, HEAD_X(zero)
	ldw t3, HEAD_Y(zero)
	slli t4, t2, 3
	add t4, t4, t3
	slli t4, t4, 2
	addi t5, zero, 4
	stw t5, GSA(t4)
	jmpi check_tail

    check_tail:
	beq a0, zero, update_tail 
	ret 

	update_tail:						
	ldw t3, GSA(t6)
	stw zero, GSA(t6)
	addi t7, zero, 1
	beq t3, t7, tail_left
	addi t7, t7, 1
	beq t3, t7, tail_up
	addi t7, t7, 1		
	beq t3, t7, tail_down
	addi t7, t7, 1
	beq t3, t7, tail_right
	ret

	tail_left:
	ldw t4, TAIL_X(zero)
	addi t3, t4, -1
	stw t3, TAIL_X(zero)
	ret	
	
	tail_up:
	ldw t5, TAIL_Y(zero)
	addi t3, t5, -1
	stw t3, TAIL_Y(zero)
	ret
	
	tail_down:
	ldw t5, TAIL_Y(zero)
	addi t3, t5, 1
	stw t3, TAIL_Y(zero)
	ret

	tail_right:
	ldw t4, TAIL_X(zero)
	addi t3, t4, 1
	stw t3, TAIL_X(zero)
	ret
; END: move_snake


; BEGIN: save_checkpoint
save_checkpoint:

; END: save_checkpoint


; BEGIN: restore_checkpoint
restore_checkpoint:

; END: restore_checkpoint


; BEGIN: blink_score
blink_score:

; END: blink_score
