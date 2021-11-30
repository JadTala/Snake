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
	; checkpoint initialization
	stw zero, CP_VALID(zero)

	; initializing the game
	game_init:
    call init_game

	; launching the main game loop
	game_loop:

	; wait a bit before getting input
	addi t0, zero, 1
	slli t0, t0, 22
	game_wait:
	addi t0, t0, -1
	bne t0, zero, game_wait

	; polling input
    call get_input

	; if checkpoint button is pressed restore checkpoint
	addi t0, zero, 5
	beq v0, t0, game_restore

	game_continue:
	; collision testing
	call hit_test
	; food was hit
    addi t0, zero, 1
	beq v0, t0, game_up
	; screen border or snake body was hit
	addi t0, zero, 2
	beq v0, t0, game_init;

	; update game logic
	addi a0, zero, 0
	call move_snake

	game_display:
	call clear_leds
	call draw_array
    
	jmpi game_loop

	game_up:
	; increment score
	ldw t0, SCORE(zero)
	addi t0, t0, 1
	stw t0, SCORE(zero)
	; update score display
	call display_score
	; increment snake position
	addi a0, zero, 1
	call move_snake
	; spawn new random food
	call create_food
	; saving checkpoint if needed
	call save_checkpoint
	; checking whether checkpoint was saved
	addi t0, zero, 0
	beq v0, t0, game_display
	addi t0, zero, 1
	beq v0, t0, game_blink

	game_blink:
	call blink_score
	jmpi game_display

	game_restore:
	call restore_checkpoint
	; checking whether or not checkpoint is valid
	addi t0, zero, 0
	beq v0, t0, game_loop
	addi t0, zero, 1
	beq v0, t0, game_blink

; BEGIN: clear_leds
clear_leds:
    stw zero, LEDS(zero)
    stw zero, LEDS+4(zero) 
    stw zero, LEDS+8(zero)

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

; TODO score modulo 100
; BEGIN: display_score
display_score:
	; last two digits will stay 0
	ldw t0, digit_map(zero)
	stw t0, SEVEN_SEGS(zero)
	stw t0, SEVEN_SEGS+4(zero)

	ldw t1, SCORE(zero)
	addi t2, t1, 0 
	addi t3, zero, 10
	addi t4, zero, 0
	display_score_loop:
	blt t2, t3, display_score_write
	addi t2, t2, -10
	addi t4, t4, 4
	jmpi display_score_loop
	
	display_score_write:
	slli t2, t2, 2
	ldw t0, digit_map(t1) 
	stw t0, SEVEN_SEGS+12(zero)
	ldw t0, digit_map(t4)
	stw t0, SEVEN_SEGS+8(zero)

	ret
; END: display_score


; BEGIN: init_game
init_game:
	addi sp, sp, -4
	stw ra, 0(sp)

	; reset gsa
	addi t0, zero, 0
	addi t1, zero, 0
	addi t2, zero, 96
	init_game_reset_gsa:
	stw zero, GSA(t0)
	addi t0, t0, 4
	addi t1, t1, 1
	blt t1, t2, init_game_reset_gsa

	init_game_callback:
	; spawn the 1-pixel snake at the upperleftmost pixel of the screen
	stw zero, HEAD_X(zero)
    stw zero, HEAD_Y(zero)
    stw zero, TAIL_X(zero)
    stw zero, TAIL_Y(zero)

	; make the snake move right
    addi t0, zero, 4
	stw t0, GSA(zero)

	; spawn a random food
	call create_food

	; display game
	call clear_leds
	call draw_array

	; reset the score
	stw zero, SCORE(zero)
	call display_score

	; reset return values
	addi v0, zero, 0
	addi v1, zero, 0

	ldw ra, 0(sp)
	addi sp, sp, 4

	ret
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
    addi t1, zero, 5 ; checkpoint
	stw t1, GSA(t0) ; storing 5 (t1) at GSA(t0)

	addi v0, zero, 0 ; else, we store 0 in v0 to say everything to put the v0 value back from 2 to 0 to say there is no more collision

    ret
; END: create_food


; BEGIN: hit_test
hit_test:
	addi v0, zero, 0
	ldw t0, HEAD_X(zero)
	ldw t1, HEAD_Y(zero)
	slli t2, t0, 3
	add t2, t2, t1
	slli t2, t2, 2
	ldw t3, GSA(t2)
	addi t4, zero, 1
	beq t3, t4, hit_test_left				
	addi t4, t4, 1
	beq t3, t4, hit_test_up
	addi t4, t4, 1
	beq t3, t4, hit_test_down
	addi t4, t4, 1
	beq t3, t4, hit_test_right
	ret
 
	hit_test_left:
	addi t0, t0, -1
	slli t2, t0, 3
	add t2, t2, t1
	slli t2, t2, 2
	ldw t3, GSA(t2)
	jmpi hit_test_next
	
	hit_test_up:
	addi t1, t1, -1
	slli t2, t0, 3
	add t2, t2, t1
	slli t2, t2, 2
	ldw t3, GSA(t2)
	jmpi hit_test_next

	hit_test_down:
	addi t1, t1, 1
	slli t2, t0, 3
	add t2, t2, t1
	slli t2, t2, 2
	ldw t3, GSA(t2)
	jmpi hit_test_next

	hit_test_right:
	addi t0, t0, 1
	slli t2, t0, 3
	add t2, t2, t1
	slli t2, t2, 2
	ldw t3, GSA(t2)
	jmpi hit_test_next
	
	hit_test_next:
	blt t0, zero, hit_test_screen_body
	blt t1, zero, hit_test_screen_body
	addi t4, zero, 12
	bge t0, t4, hit_test_screen_body
	addi t4, zero, 8
	bge t1, t4, hit_test_screen_body
	addi t4, zero, 1
	beq t3, t4, hit_test_screen_body
	addi t4, zero, 2
	beq t3, t4, hit_test_screen_body
	addi t4, zero, 3
	beq t3, t4, hit_test_screen_body
	addi t4, zero, 4
	beq t3, t4, hit_test_screen_body
	addi t4, zero, 5
	beq t3, t4, hit_test_food
	ret

	hit_test_food:
	addi v0, zero, 1
	stw zero, GSA(t2)
	ret	
	hit_test_screen_body:
	addi v0, zero, 2
	ret
; END : hit_test


; BEGIN: get_input
get_input:
	; get edgecapture
	ldw t0, BUTTONS+4(zero)
	; reset edgecapture
	stw zero, BUTTONS+4(zero) 
	; update if a button was pressed
	bne t0, zero, get_input_update
	; no button was pressed
	addi v0, zero, 0
	jmpi get_input_end

	get_input_update:
	addi t3, zero, 1 ; helper bit
	addi t7, zero, 5 ; counter
	slli t4, t3, 4   ; mask

	get_input_scan:
	; interpret edgecapture with priority for checkpoint button
	and t1, t0, t4
	beq t1, t4, get_input_post_scan
	addi t7, t7, -1
	srli t4, t4, 1
	jmpi get_input_scan

	get_input_post_scan:
	; return the pressed button
	add v0, zero, t7

	; break if button pressed is checkpoint
	addi t1, zero, 5
	beq t7, t1, get_input_end

	; get snake position
    ldw t1, HEAD_X(zero)
	ldw t2, HEAD_Y(zero)
	slli t1, t1, 3
	add t1, t1, t2
	slli t1, t1, 2

	; get current snake direction
	ldw t3, GSA(t1)

	; get opposite direction
	addi t4, zero, 5
	sub t4, t4, t3
	
	; don't allow the snake to turn around
	beq t7, t4, get_input_end
	
	; update gsa
	stw t7, GSA(t1)

	get_input_end:
	ret
; END: get_input


; BEGIN: draw_array
draw_array:
	addi t0, zero, 0
	addi t6, zero, 12
	addi t5, zero, 8
	jmpi draw_array_x_loop 

draw_array_x_loop:
	addi t1, zero, 0
	blt t0, t6, draw_array_y_loop
	ret
	
draw_array_y_loop:
	slli t2, t0, 3
	add t3, t2, t1
	slli t3, t3, 2

	ldw t4, GSA(t3)
	bne t4, zero, draw_array_set_pixel

draw_array_step:
	addi t1, t1, 1
	blt t1, t5, draw_array_y_loop
	addi t0, t0, 1

	jmpi draw_array_x_loop 
	
draw_array_set_pixel:
	addi sp, sp, -12
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
    jmpi draw_array_step
; END: draw_array


; BEGIN: move_snake
move_snake:
	; load head and tail coordinates
	ldw t0, HEAD_X(zero)
	ldw t1, HEAD_Y(zero)

	slli t2, t0, 3
	add t2, t2, t1
	slli t2, t2, 2
	ldw t3, GSA(t2)

	ldw t4, TAIL_X(zero)
	ldw t5, TAIL_Y(zero)

	slli t6, t4, 3
	add t6, t6, t5
	slli t6, t6, 2
	
	addi t7, zero, 1
	beq t3, t7, move_snake_head_left
	addi t7, zero, 2
	beq t3, t7, move_snake_head_up
	addi t7, zero, 3		
	beq t3, t7, move_snake_head_down
	addi t7, zero, 4
	beq t3, t7, move_snake_head_right

	move_snake_head_left:
	addi t2, t0, -1
	stw t2, HEAD_X(zero)
	ldw t3, HEAD_Y(zero)
	slli t4, t2, 3
	add t4, t4, t3
	slli t4, t4, 2 
	addi t5, zero, 1
	stw t5, GSA(t4)
	jmpi move_snake_check_tail 

	move_snake_head_up:
	addi t2, t1, -1
	stw t2, HEAD_Y(zero)
	ldw t3, HEAD_X(zero)
	slli t4, t3, 3
	add t4, t4, t2
	slli t4, t4, 2 
	addi t5, zero, 2
	stw t5, GSA(t4)
	jmpi move_snake_check_tail 

	move_snake_head_down:
	addi t2, t1, 1
	stw t2, HEAD_Y(zero)
	ldw t3, HEAD_X(zero)
	slli t4, t3, 3
	add t4, t4, t2
	slli t4, t4, 2
	addi t5, zero, 3
	stw t5, GSA(t4)
	jmpi move_snake_check_tail 

	move_snake_head_right:
	addi t2, t0, 1
	stw t2, HEAD_X(zero)
	ldw t3, HEAD_Y(zero)
	slli t4, t2, 3
	add t4, t4, t3
	slli t4, t4, 2
	addi t5, zero, 4
	stw t5, GSA(t4)
	jmpi move_snake_check_tail

	move_snake_check_tail:
	beq a0, zero, move_snake_update_tail 
	ret 

	move_snake_update_tail:						
	ldw t3, GSA(t6)
	stw zero, GSA(t6)
	addi t7, zero, 1
	beq t3, t7, move_snake_tail_left
	addi t7, t7, 1
	beq t3, t7, move_snake_tail_up
	addi t7, t7, 1		
	beq t3, t7, move_snake_tail_down
	addi t7, t7, 1
	beq t3, t7, move_snake_tail_right
	ret

	move_snake_tail_left:
	ldw t4, TAIL_X(zero)
	addi t3, t4, -1
	stw t3, TAIL_X(zero)
	ret	
	
	move_snake_tail_up:
	ldw t5, TAIL_Y(zero)
	addi t3, t5, -1
	stw t3, TAIL_Y(zero)
	ret
	
	move_snake_tail_down:
	ldw t5, TAIL_Y(zero)
	addi t3, t5, 1
	stw t3, TAIL_Y(zero)
	ret

	move_snake_tail_right:
	ldw t4, TAIL_X(zero)
	addi t3, t4, 1
	stw t3, TAIL_X(zero)
	ret
; END: move_snake


; BEGIN: save_checkpoint
save_checkpoint:
	addi sp, sp, -4 
	stw ra, 0(sp)

	ldw t1, SCORE(zero)
	addi t2, zero, 10
	save_checkpoint_mod:
	blt t1, t2, save_checkpoint_check
	addi t1, t1, -10
	jmpi save_checkpoint_mod

	save_checkpoint_check:
	; if score is multiple of 10 create new checkpoint
	beq t1, zero, save_checkpoint_create

	; if not, notify and break
	addi v0, zero, 0
	jmpi save_checkpoint_end

	save_checkpoint_create:
	; setting the checkpoint as valid
	addi t0, zero, 1
	stw t0, CP_VALID(zero)

	; copying current into check point
	ldw t3, HEAD_X(zero)
	stw t3, CP_HEAD_X(zero)
	ldw t3, HEAD_Y(zero)
	stw t3, CP_HEAD_Y(zero)

	ldw t3, TAIL_X(zero)
	stw t3, CP_TAIL_X(zero)
	ldw t3, TAIL_Y(zero)
	stw t3, CP_TAIL_Y(zero)

	ldw t3, SCORE(zero)
	stw t3, CP_SCORE(zero)

	ldw t3, GSA(zero)
	stw t3, CP_GSA(zero)

	; notify that checkpoint was saved
	addi v0, zero, 1

	jmpi save_checkpoint_end

	save_checkpoint_end:
	ldw ra, 0(sp)
	addi sp, sp, 4

	ret
; END: save_checkpoint


; BEGIN: restore_checkpoint
restore_checkpoint:
	addi sp, sp, -4
	stw ra, 0(sp)

	; check if checkpoint is valid
	addi t0, zero, 1
	ldw t1, CP_VALID(zero)
	; if the checkpoint is valid load it and notify
	beq t1, t0, restore_checkpoint_load
	; else notify that not valid
	beq t1, zero, restore_checkpoint_do_nothing

	ldw ra, 0(sp)
	addi sp, sp, 4

	ret

	restore_checkpoint_load:
	ldw t3, CP_HEAD_X(zero)
	stw t3, HEAD_X(zero)
	ldw t3, CP_HEAD_Y(zero)
	stw t3, HEAD_Y(zero)

	ldw t3, CP_TAIL_X(zero)
	stw t3, TAIL_X(zero)
	ldw t3, CP_TAIL_Y(zero)
	stw t3, TAIL_Y(zero)

	ldw t3, CP_SCORE(zero)
	stw t3, SCORE(zero)

	ldw t3, CP_GSA(zero)
	stw t3, GSA(zero)

	addi v0, zero, 1

	ret

	restore_checkpoint_do_nothing:
	addi v0, zero, 0
; END: restore_checkpoint


; BEGIN: blink_score
blink_score:
	addi t0, zero, 5

	blink_score_loop:
	; break if blinked enough times
	beq t0, zero, blink_score_end

	; clear the score
	stw zero, SEVEN_SEGS(zero)
	stw zero, SEVEN_SEGS+4(zero)
	stw zero, SEVEN_SEGS+8(zero)
	stw zero, SEVEN_SEGS+12(zero)

	; wait procedure
	addi t1, zero, 1
	slli t1, t1, 22
	blink_score_wait_loop:
	addi t1, t1, -1
	bne t1, zero, blink_score_wait_loop

	; display the score
	call display_score

	addi t0, t0, -1
	jmpi blink_score_loop

	blink_score_end:
	ret
; END: blink_score


digit_map:
.word 0xFC ; 0
.word 0x60 ; 1
.word 0xDA ; 2
.word 0xF2 ; 3
.word 0x66 ; 4
.word 0xB6 ; 5
.word 0xBE ; 6
.word 0xE0 ; 7
.word 0xFE ; 8
.word 0xF6 ; 9