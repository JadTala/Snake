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
 	; Checkpoint initialization, setting to 0 before the game is initialized
	stw zero, CP_VALID(zero)
	; Initializing the game
    call init_game
	; launching the game / main loop
    call main_loop
    ret

main_loop:
    call draw_array ; REMMM
	call display_score
	call wait ; REMMM ; so it is "fluent"
	call clear_leds
    call get_input
	call hit_test ; if returns 2, terminate ??? which method ?
    call coll_transition ; if 2, terminates ?, if 1 create food, if 0 then continues down
	; TODO, do we have to put coll_transition inside hit_test or not ?
	call move_snake
    call main_loop
    ret

coll_transition:
; as always every time we have branches or calls we need to store the ret value into a stack
addi sp, sp, -4 ; allouer emplacement dans stack
stw ra, 0(sp)

addi t1, zero, 1
beq v0, t1, score_food_incr
beq v0, t1, create_food

addi t1, zero, 2 ; should terminate the game - collision with border or with body
beq v0, t1, stack_prob ; 

ldw ra, 0(sp)  ; reloading the stack ; TODO demander assistant s'il y aura un problème si
addi sp, sp, 4
ret
; addi t1, zero, 0 not necessary, we can leave the rest after the call of this method

score_food_incr:
ldw t0, SCORE(zero)
addi t0, t0, 1
stw t0, SCORE(zero)
ret

stack_prob: ; to do before calling init game
ldw ra, 0(sp)  ; reloading the stack ; TODO demander assistant s'il y aura un problème si
addi sp, sp, 4

addi t1, zero, 2 ; should terminate the game - collision with border or with body
beq v0, t1, main ; after setting the stack back to where it was, should go to init game as usual // change, branch to main because otherwise ret of init game -> skip until move snake in main loop



;   The clear_leds procedure initializes all LEDs to 0 (zero)
;   called before drawing every new position of the snake and/or food 

; BEGIN: clear_leds
clear_leds:
    stw zero, LEDS(zero)
    stw zero, LEDS + 4 (zero) 
    stw zero, LEDS + 8 (zero)
    ret
; END: clear_leds


;    takes two coordinates as arguments and turns on the corresponding pixel
;   on the LED display. When this procedure turns on a pixel, it must keep the state of all the other pixels
;   unmodified.

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
ldw t0, SCORE(zero); get the current score (in decimal representation) on the display, located at 0x1010 -> 4112
addi sp, sp, -4
stw ra, 0(sp)

; first digit
addi t3, zero, 0 ;; manque comment trouver les digits, millier, centaine, dizaine, unité
addi t1, zero, 0
call disp
; second digit
addi t3, zero, 1   ; compter combiend de fois il faut soustraire 10 jusqu'à trouver des unités
addi t1, zero, 0
call disp
; third digit
addi t3, zero, 2
addi t1, zero, 0
ldw t6, 0(t0) ; in t5 we have the score
call third
call disp
; fourth - las digit
addi t3, zero, 3
ldw t1, 0(t0)
call fourth
call disp

ldw ra, 0(sp)
addi sp, sp, 4
ret

disp:
slli t1, t1, 2 ; shift by 2
ldw t6, digit_map(t1)
stw t6, SEVEN_SEGS(t3)
ret

third:
addi t6, t0, -10
addi t4, zero, 10
addi t1, t1, 1 ; adding in t1
blt t6, t4, end_disp ; at the end we break out of loop when t6 = t4 = 10 t1 is the dizaine digit
br third

fourth:
addi t1, t0, -10
addi t4, zero, 10
blt t1, t4, end_disp
br fourth

end_disp: 
ret
; END: display_score



; BEGIN: init_game
init_game: ; TODO réinitialiser la GSA -> tous les remettre à 0

	; previously in main
	; snake of length one, appearing at the top left corner of the LED screen and moving towards right
	
	; ; as always every time we have branches or calls we need to store the ret value into a stack
	addi sp, sp, -4 ; allouer emplacement dans stack
	stw ra, 0(sp)

	addi t0, zero, 95 ; since 0-95 = 96 values
	call resetGSA


	follow:

	stw zero, HEAD_X(zero)
    stw zero, HEAD_Y(zero)
    stw zero, TAIL_X(zero)
    stw zero, TAIL_Y(zero)
    addi t0, zero, 4
	stw t0, GSA(zero)

	; section 7 in addition :
	; food is appearing at a random location and score is all zeros
	; call create_food ; TODO enlever le commentaire
	ldw t0, SCORE(zero)
	sub t0, t0, t0 ; t0 - t0 should give 0 
	stw t0, SCORE(zero)

	addi v0, zero, 0 ; setting v0 back to 0, imagine collision with border previously, would launch infinitely

	ldw ra, 0(sp)  ; reloading the stack
	addi sp, sp, 4
	ret

	resetGSA:
	stw zero, GSA(t0)
	beq t0, zero, follow
	addi t0, t0, -1
	br resetGSA

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


; tests whether or not the new element being drawn as the snake’s head collides with the
; screen boundary, the food, or the snake’s own body
; If there is a collision with the food, the procedure returns 1 indicating that the score needs to be incremented.
; If there is a collision with the screen boundary or the snake’s body, the procedure returns 2 indicating the end of the game. 
; If there is no collision, the procedure returns 0

; BEGIN: hit_test
hit_test:

addi sp, sp, -4 ; allouer emplacement dans stack
stw ra, 0(sp)

; call get_input ; address of potential new head stored in t4, {address of food is GSA(t0)} if GSA(t4) = 5 then collision with food

ldw t0, HEAD_X(zero)
srli t0, t0, 27 ; (x) * 8
ldw t7, HEAD_Y(zero)
add t0, t0, t7  ; (x mod 4) * 8 + y

ldw t2, GSA(t0)
; 4 cases
; right
addi t6, zero, 1
beq t2, t6, hit_left; if current head's direction is left, we look at what is one case to the left of head

addi t6, t6, 1
beq t2, t6, hit_up

addi t6, t6, 1
beq t2, t6, hit_down

addi t6, t6, 1
beq t2, t6, hit_right

post_col:
; after collision testing, value of position of direction head + 1 move is in t0
addi t1, zero, 5	; init t1 at 5
ldw t7, GSA(t0)
beq t7, t1, coll_food ; if t0 (position of head) = 5 then there is a food in front

addi t1, zero, 1
beq t7, t1, coll_screen_body ; if t0 (position of head) = 1, 2, 3, 4 / there is a body in front
addi t1, t1, 1
beq t7, t1, coll_screen_body
addi t1, t1, 1
beq t7, t1, coll_screen_body
addi t1, t1, 1
beq t7, t1, coll_screen_body

addi t1, zero, 1
ldw t7, HEAD_X(zero)
blt t7, zero, coll_screen_body ; if t0 (position of head) = 1, 2, 3, 4 / there is a body in front

addi t1, t1, 1
ldw t7, HEAD_Y(zero)
blt t7, zero, coll_screen_body 

addi t1, t1, 1
ldw t7, HEAD_Y(zero)
addi t4, zero, 8
bgeu t7, t4, coll_screen_body 

addi t1, t1, 1
ldw t7, HEAD_X(zero)
addi t4, zero, 12
bgeu t7, t4, coll_screen_body 

; addi t1, zero, 4116
; blt t0, t1, coll_screen_body ; < 0x1014 ; 4116 ; there is a collision with the screen
; addi t1, zero, 4504
; bge t0, t1, coll_screen_body ; >= 0x1198 ; 4504

addi v0, zero, 0 ; else, we store 0 in v0 to say everything is fine


ldw ra, 0(sp) ; reload ret value from stack
addi sp, sp, 4
ret

hit_left:
addi t0, t1, -8 ; t1 is the position of head on the board
jmpi post_col

hit_up:
addi t0, t1, -1 ; t1 is the position of head on the board
jmpi post_col

hit_down:
addi t0, t1, 1 ; t1 is the position of head on the board
jmpi post_col

hit_right:
addi t0, t1, 8 ; t1 is the position of head on the board
jmpi post_col

coll_food:
addi v0, zero, 1 ; 1 to say collision with food -> ! set v0 back to 0
ret

coll_screen_body:
addi v0, zero, 2 ; 2 to say collision with body or border screen
ret

; END : hit_test



; BEGIN: get_input
get_input:
	ldw t1, BUTTONS+4(zero) ; get edgecapture and store into t1
	addi t5, zero, 0
	bne t1, t5, input_update ; update only if button was pressed
	ret

input_update:
    ldw t2, HEAD_X(zero) ; get head x and load it into t2
	ldw t3, HEAD_Y(zero) ; get head y and load it into t3
	
	slli t2, t2, 5 ; 32x - shifting left by 5 bits is same as doing value * 2^5
	slli t3, t3, 2 ; 4y - shifting left by 2 bits -> val of t3 * 2^2
	add t4, t2, t3 ; 32x + 4y and store in t4
	addi t4, t4, GSA ; head GSA address and add with t4 - side note: GSA contains 96 x 32-bit words :: 0x1014 - 0x1197 / 4116 - 4503 + 1 = 388 values between -> 97 values taking 4 each 
	
	andi t1, t1, 15	; ignore checkpoint button - value between 0-4 AND 15 will result in 0
	stw t1, 0(t4) ; update

	and t1, t1, zero ; reset edgecapture
	stw t1, BUTTONS+4(zero) ; store if something is stil pressed
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
	stw ra, 0(sp) ; return address
	stw a1, 4(sp) ; register arguments
	stw a0, 8(sp)
	addi a0, t0, 0
	addi a1, t1, 0
	call set_pixel ; will take as argument register a0 and register a1
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

	slli t2, t0, 3 ; head x * 2^3
	slli t6, t4, 3
	add t2, t2, t1
	slli t2, t2, 2 

	add t6, t6, t5
	slli t6, t6, 2
	ldw t3, GSA(t2)

	addi t7, zero, 1
	beq t3, t7, head_left
	addi t7, t7, 1
	beq t3, t7, head_up
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
; as always every time we have branches we need to store the ret value into a stack
addi sp, sp, -4 ; allouer emplacement dans stack
stw ra, 0(sp)

ldw t1, SCORE(zero)

addi t0, zero, 10 ; hard coded is simpler, since the score cannot go over 96, creating loops would be bothersome
beq t0, t1, act_CP_Valid
addi t0, zero, 20
beq t0, t1, act_CP_Valid
addi t0, zero, 30
beq t0, t1, act_CP_Valid
addi t0, zero, 40
beq t0, t1, act_CP_Valid
addi t0, zero, 50
beq t0, t1, act_CP_Valid
addi t0, zero, 60
beq t0, t1, act_CP_Valid
addi t0, zero, 70
beq t0, t1, act_CP_Valid
addi t0, zero, 80
beq t0, t1, act_CP_Valid
addi t0, zero, 90
beq t0, t1, act_CP_Valid
addi t0, zero, 100

; But also save the current game State to the checkpoint memory region
addi t0, zero, 1
ldw t1, CP_VALID(zero)
beq t0, t1, copy_memory_CP ; TODO here there is a problem, while score is at mult. of 10, the position is stored at every move since the score hasn't changed (case where we are in an impossible case, even restoring wouldn't help since it will be the last position before the collision)

ldw ra, 0(sp) ; reloading the stack
addi sp, sp, 4

ret

act_CP_Valid:
addi t0, zero, 1
stw t0, CP_VALID(zero) ; setting CP_VALID to one
ret

copy_memory_CP:
; copying current into check point
ldw t3, HEAD_X(zero)
stw t3, CP_HEAD_X(zero) ; Snake head's position on x
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
ret
; END: save_checkpoint


; BEGIN: restore_checkpoint
restore_checkpoint:
; if checkpoint button is pressed, if pressed, check
addi t0, zero, 5 ; TODO CHECK THIS LINE OF CODE, IM NOT SURE HOW WE SEE IF THE BUTTON CHECKPOINT has been pressed : get edgecapture and store into t1

; as always every time we have branches or calls we need to store the ret value into a stack
addi sp, sp, -4 ; allouer emplacement dans stack
stw ra, 0(sp)

ldw t5, BUTTONS+5(zero)
beq t5, t0, check_CP ; TODO maybe should we modify the stack pointer in check_CP to go further ???

ldw ra, 0(sp)  ; reloading the stack
addi sp, sp, 4

; if not pressed then return back
ret

check_CP:
addi t0, zero, 0
ldw t5, CP_VALID(zero)
beq t0, t5, end_CP ; if not valid, we break out of this process and don't look further down

; as always every time we have branches or calls we need to store the ret value into a stack
addi sp, sp, -4 ; allouer emplacement dans stack
stw ra, 0(sp)

call load_memory_CP

ldw ra, 0(sp)  ; reloading the stack
addi sp, sp, 4

ret

end_CP: ; TODO ATTENTION GRADER
ret

load_memory_CP:
; copying current into check point
ldw t3, CP_HEAD_X(zero)
stw t3, HEAD_X(zero) ; Snake head's position on x
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
ret
; END: restore_checkpoint


; BEGIN: blink_score
blink_score:
addi sp, sp, -4 ; allouer emplacement dans stack
stw ra, 0(sp)

call clear_leds ; TODO not clear leds but clear diplay led
call wait
call display_score
call wait
call clear_leds
call wait
call display_score
call wait
call clear_leds
call wait
call display_score

ldw ra, 0(sp)
addi sp, sp, 4
ret

ret
; END: blink_score

; BEGIN: wait_procedure ; TODO LE NOM
wait:
addi t0, zero, 1
slli t0, t0, 22
addi t1, zero, 0

wait_loop:
addi t0, t0, -1
bne t0, t1, wait_loop

ret
		; just in case reputing this there TODO verify with an assistant - do we have to put it again in blink_score ?
; END: wait_procedure

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

; TODO - check left right up down constraint, shouldnt be able to go left while going right

; TODO - However, if the checkpoint button was pressed together with any other button, this procedure should return that
; only the checkpoint button was pressed.


; ; as always every time we have branches or calls we need to store the ret value into a stack
; addi sp, sp, -4 ; allouer emplacement dans stack
; stw ra, 0(sp)

; ldw ra, 0(sp)  ; reloading the stack
; addi sp, sp, 4