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
    jal generate_random_colors

game_loop:
    jal clear_screen
    jal draw_border
    jal draw_static_gems
    jal draw_current_column

    # Sleep ~16ms for ~60 FPS
    li $v0, 32
    li $a0, 16
    syscall

    j game_loop

# -------------------------------
# Generate 3 random colors for column
# -------------------------------
generate_random_colors:
    la $t0, column_colors
    li $t1, 3

gen_loop:
    li $v0, 42
    li $a0, 0
    li $a1, 6
    syscall
    addi $v0, $v0, 1
    sw $v0, 0($t0)
    addi $t0, $t0, 4
    addi $t1, $t1, -1
    bgtz $t1, gen_loop
    jr $ra

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
    li $a2, 7          # Gray

    # Top and bottom border
    li $a1, 0
top_border:
    li $a0, 0
top_border_loop:
    jal draw_pixel
    addi $a0, $a0, 1
    ble $a0, 11, top_border_loop

    li $a1, 21
    li $a0, 0
bottom_border_loop:
    jal draw_pixel
    addi $a0, $a0, 1
    ble $a0, 11, bottom_border_loop

    # Left and right border
    li $a0, 0
    li $a1, 0
left_border_loop:
    jal draw_pixel
    addi $a1, $a1, 1
    ble $a1, 21, left_border_loop

    li $a0, 11
    li $a1, 0
right_border_loop:
    jal draw_pixel
    addi $a1, $a1, 1
    ble $a1, 21, right_border_loop

    jr $ra

# -------------------------------
# Draw current column (3 gems vertically)
# -------------------------------
draw_current_column:
    lw $t0, current_x
    lw $t1, current_y
    la $t2, column_colors
    li $t3, 0

draw_column_loop:
    lw $a2, 0($t2)
    addi $t2, $t2, 4

    move $a0, $t0
    add $a1, $t1, $t3
    jal draw_gem

    addi $t3, $t3, 1
    li $t4, 3
    blt $t3, $t4, draw_column_loop
    jr $ra

# -------------------------------
# Draw gem (8x8 pixels)
# -------------------------------
draw_gem:
    sll $t0, $a0, 3       # x pixel = x unit * 8
    sll $t1, $a1, 3       # y pixel = y unit * 8
    li $t2, 0

gem_row_loop:
    li $t3, 0
gem_col_loop:
    add $a0, $t0, $t3
    add $a1, $t1, $t2
    jal draw_pixel
    addi $t3, $t3, 1
    li $t4, 8
    blt $t3, $t4, gem_col_loop
    addi $t2, $t2, 1
    li $t4, 8
    blt $t2, $t4, gem_row_loop
    jr $ra

# -------------------------------
# Draw static gems (empty for now)
# -------------------------------
draw_static_gems:
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
