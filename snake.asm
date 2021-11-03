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
    ; TODO: Finish this procedure.

    ret


; BEGIN: clear_leds
clear_leds:
    stw zero, LEDS(zero)
    stw zero, LEDS + 4 (zero) 
    stw zero, LEDS + 8 (zero) ; addi t1, zero, 8 || stw zero, LEDS(t1)

    ret
; END: clear_leds


; BEGIN: set_pixel
set_pixel: (a0, a1)
    br check0

    check0:
    cmpgeui t0, a0, 4
    bre t0, 0, ldled0
    bre t0, 1, check1

    check1:
    cmpgeui t0, a0, 8
    bre t0, 0, ldled1
    bre t0, 1, ldled2

    ldled0:
    ldw t0, LEDS (zero) ; loading correct led chunk
    br update ; updating
    stw LEDS (zero), t3 ; writing update

    ldled1:
    ldw t0, LEDS + 4 (zero)
    br update
    stw LEDS + 4 (zero), t3

    ldled2:
    ldw t0, LEDS + 8 (zero)
    br update
    stw LEDS + 8 (zero), t3

    update:
    addi t1, zero, 1 ; bit to turn on
    ; bit index is 7 * a1 + a0 how to mult?
    addi t2, ; amount to shift
    slli t1, t1, ; shifting
    or t3, t0, t1 ; setting pixel

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

; END: create_food


; BEGIN: hit_test
hit_test:

; END: hit_test


; BEGIN: get_input
get_input:

; END: get_input


; BEGIN: draw_array
draw_array:

; END: draw_array


; BEGIN: move_snake
move_snake:

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
