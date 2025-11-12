################# CSC258 Assembly Final Project ###################
# Columns implementation with working falling column
##############################################################################

.data
ADDR_DSPL:       .word 0x10008000
ADDR_KBRD:       .word 0xffff0000

colors:
    .word 0x000000    # 0: Black (background)
    .word 0xff0000    # 1: Red
    .word 0xffa500    # 2: Orange
    .word 0xffff00    # 3: Yellow
    .word 0x00ff00    # 4: Green
    .word 0x0000ff    # 5: Blue
    .word 0x800080    # 6: Purple
    .word 0x808080    # 7: Gray (border)

current_x:       .word 5
current_y:       .word 1
column_colors:   .word 0, 0, 0  # Top, middle, bottom gem

.text
.globl main
main:
    # Initialize first column

game_loop:
    jal clear_screen
    jal draw_border
    jal draw_current_column

    # Sleep ~16ms for ~60 FPS
    li $v0, 32
    li $a0, 16
    syscall

    j game_loop

# -------------------------------
# Clear screen
# -------------------------------
clear_screen:
    lw $t0, ADDR_DSPL
    li $t1, 0
    li $t2, 0
    li $t3, 1024
clear_loop:
    sw $t1, 0($t0)
    addi $t0, $t0, 4
    addi $t2, $t2, 1
    blt $t2, $t3, clear_loop
    jr $ra

# -------------------------------
# Draw border (unit-based)
# -------------------------------
draw_border:
    addi $sp, $sp, -4          # make space on stack
    sw $ra, 0($sp)             # save return address

    li $a2, 7                  # Gray

    # --- Top border ---
    li $a1, 0
    li $a0, 0
top_border_loop:
    jal draw_pixel
    addi $a0, $a0, 1
    ble $a0, 11, top_border_loop

    # --- Bottom border ---
    li $a1, 21
    li $a0, 0
bottom_border_loop:
    jal draw_pixel
    addi $a0, $a0, 1
    ble $a0, 11, bottom_border_loop

    # --- Left border ---
    li $a0, 0
    li $a1, 0
left_border_loop:
    jal draw_pixel
    addi $a1, $a1, 1
    ble $a1, 21, left_border_loop

    # --- Right border ---
    li $a0, 11
    li $a1, 0
right_border_loop:
    jal draw_pixel
    addi $a1, $a1, 1
    ble $a1, 21, right_border_loop

    lw $ra, 0($sp)             # restore return address
    addi $sp, $sp, 4           # restore stack pointer
    jr $ra

# -------------------------------
# Draw single pixel (unit-based)
# -------------------------------
draw_pixel:
    lw $t0, ADDR_DSPL
    li $t1, 32
    mul $t2, $a1, $t1
    add $t2, $t2, $a0
    sll $t2, $t2, 2
    add $t2, $t0, $t2

    la $t3, colors
    sll $t4, $a2, 2
    add $t3, $t3, $t4
    lw $t4, 0($t3)
    sw $t4, 0($t2)
    jr $ra

# -------------------------------
# Draw current column
# -------------------------------
draw_current_column:
    addi $sp, $sp, -8         # save registers
    sw $ra, 0($sp)
    sw $s0, 4($sp)

    lw $t0, current_x         # load x position
    lw $t1, current_y         # load y position

    # Draw top gem
    jal generate_random_color  # get random color in $v0
    move $a2, $v0             # set color argument
    move $a0, $t0             # set x position
    move $a1, $t1             # set y position
    jal draw_pixel            # draw top gem

    # Draw middle gem
    jal generate_random_color  # get random color in $v0
    move $a2, $v0             # set color argument
    move $a0, $t0             # set x position
    addi $a1, $t1, 1          # set y position + 1
    jal draw_pixel            # draw middle gem

    # Draw bottom gem
    jal generate_random_color  # get random color in $v0
    move $a2, $v0             # set color argument
    move $a0, $t0             # set x position
    addi $a1, $t1, 2          # set y position + 2
    jal draw_pixel            # draw bottom gem

    lw $ra, 0($sp)            # restore registers
    lw $s0, 4($sp)
    addi $sp, $sp, 8
    jr $ra

# -------------------------------
# Generate random color (1-6)
# Returns: $v0 - random color index (1-6)
# -------------------------------
generate_random_color:
    li $v0, 42               # random int range syscall
    li $a0, 0                # random generator id
    li $a1, 6                # upper bound (exclusive)
    syscall                  # result in $a0 (0-5)
    addi $v0, $a0, 1         # convert to 1-6
    jr $ra