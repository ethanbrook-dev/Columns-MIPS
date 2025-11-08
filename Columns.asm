##############################################################################
# CSC258H1F Assembly Project: Columns with Keyboard Input Example
#
# Demonstrates keyboard input (detecting 'q') while preserving display memory ($gp)
##############################################################################

    .data
##############################################################################
# Hardware Addresses
##############################################################################
ADDR_DSPL:
    .word 0x10008000      # Base address for display memory ($gp points here)

##############################################################################
# Game Data
##############################################################################
# Gem colors
COLOR_RED:      .word 0xff0000
COLOR_ORANGE:   .word 0xff8800  
COLOR_YELLOW:   .word 0xffff00
COLOR_GREEN:    .word 0x00ff00
COLOR_BLUE:     .word 0x0000ff
COLOR_PURPLE:   .word 0x8800ff

# Game colors
COLOR_BG:       .word 0x000000      # Black background
COLOR_BORDER:   .word 0x8B4513      # Brown border
COLOR_FIELD:    .word 0x808080      # Grey playing field

# Game state
current_column: .word 0, 0, 0       # Three gem colors for current column
column_x:       .word 5             # starting X position
column_y:       .word 0             # starting Y position

    .text
    .globl main

##############################################################################
# Main Program
##############################################################################
main:
    # Initialize display
    jal draw_black_background
    jal draw_playing_field
    jal generate_new_column
    jal draw_current_column
    
    j main_loop # Start the game loop
    
main_loop:
    li $v0, 11
    li $a0, 35    # print '#'
    syscall
    j main_loop

##############################################################################
# Handling different keyboard keys
##############################################################################



##############################################################################
# Display / Drawing
##############################################################################
# Draw black background for entire screen
draw_black_background:
    lw $t2, COLOR_BG
    move $t0, $gp            # $gp points to display memory
    li $t1, 0
draw_bg_loop:
    sw $t2, 0($t0)
    addi $t0, $t0, 4
    addi $t1, $t1, 1
    blt $t1, 1024, draw_bg_loop
    jr $ra

# Draw playing field with brown border and grey interior
draw_playing_field:
    lw $t0, ADDR_DSPL
    lw $t1, COLOR_BORDER
    lw $t2, COLOR_FIELD

    li $t3, 9
    li $t4, 4
    li $t5, 14
    li $t6, 26

    li $t7, 128
    mul $t8, $t4, $t7
    sll $t9, $t3, 2
    add $t0, $t0, $t8
    add $t0, $t0, $t9

    li $s0, 0
    move $s1, $t0
draw_top_border:
    sw $t1, 0($t0)
    addi $t0, $t0, 4
    addi $s0, $s0, 1
    blt $s0, $t5, draw_top_border

    li $s2, 1
draw_field_rows:
    move $t0, $s1
    mul $s3, $s2, 128
    add $t0, $s1, $s3
    sw $t1, 0($t0)
    addi $t0, $t0, 4

    li $s0, 1
draw_field_interior:
    sw $t2, 0($t0)
    addi $t0, $t0, 4
    addi $s0, $s0, 1
    blt $s0, 13, draw_field_interior

    sw $t1, 0($t0)
    addi $s2, $s2, 1
    blt $s2, 25, draw_field_rows

    move $t0, $s1
    li $s3, 25
    mul $s3, $s3, 128
    add $t0, $s1, $s3

    li $s0, 0
draw_bottom_border:
    sw $t1, 0($t0)
    addi $t0, $t0, 4
    addi $s0, $s0, 1
    blt $s0, $t5, draw_bottom_border

    jr $ra

##############################################################################
# Generate new column
##############################################################################
generate_new_column:
    la $t0, current_column

    li $v0, 42
    li $a0, 0
    li $a1, 6
    syscall
    sw $a0, 0($t0)

    li $v0, 42
    li $a0, 0
    li $a1, 6
    syscall
    sw $a0, 4($t0)

    li $v0, 42
    li $a0, 0
    li $a1, 6
    syscall
    sw $a0, 8($t0)

    jr $ra

##############################################################################
# Draw current column
##############################################################################
draw_current_column:
    la $t0, current_column
    li $v0, 11
    li $a0, '1'
    syscall

    lw $t1, column_x
    li $v0, 11
    li $a0, '2'
    syscall

    lw $t2, column_y
    li $v0, 11
    li $a0, '3'
    syscall

    lw $t3, ADDR_DSPL
    li $v0, 11
    li $a0, '4'
    syscall

    li $t4, 5
    li $v0, 11
    li $a0, '5'
    syscall

    li $t5, 10
    li $v0, 11
    li $a0, '6'
    syscall

    li $t6, 128
    li $v0, 11
    li $a0, '7'
    syscall

    add $t7, $t4, $t2
    li $v0, 11
    li $a0, '8'
    syscall

    mul $t7, $t7, $t6
    li $v0, 11
    li $a0, '9'
    syscall

    add $t8, $t5, $t1
    li $v0, 11
    li $a0, 'A'
    syscall

    sll $t8, $t8, 2
    li $v0, 11
    li $a0, 'B'
    syscall

    add $t3, $t3, $t7
    li $v0, 11
    li $a0, 'C'
    syscall

    add $t3, $t3, $t8
    li $v0, 11
    li $a0, 'D'
    syscall

    lw $a0, 0($t0)
    li $v0, 11
    li $a0, 'E'
    syscall

    jal get_gem_color
    li $v0, 11
    li $a0, 'F'
    syscall

    sw $v0, 0($t3)
    li $v0, 11
    li $a0, 'G'
    syscall

    lw $a0, 4($t0)
    li $v0, 11
    li $a0, 'H'
    syscall

    jal get_gem_color
    li $v0, 11
    li $a0, 'I'
    syscall

    sw $v0, 128($t3)
    li $v0, 11
    li $a0, 'J'
    syscall

    lw $a0, 8($t0)
    li $v0, 11
    li $a0, 'K'
    syscall

    jal get_gem_color
    li $v0, 11
    li $a0, 'L'
    syscall

    sw $v0, 256($t3)
    li $v0, 11
    li $a0, 'M'
    syscall

    jr $ra
    li $v0, 11
    li $a0, 'N'
    syscall

##############################################################################
# Get gem color by index
##############################################################################
get_gem_color:
    beq $a0, 0, color_red
    beq $a0, 1, color_orange
    beq $a0, 2, color_yellow
    beq $a0, 3, color_green
    beq $a0, 4, color_blue
    beq $a0, 5, color_purple

color_red:
    lw $v0, COLOR_RED
    jr $ra
color_orange:
    lw $v0, COLOR_ORANGE
    jr $ra
color_yellow:
    lw $v0, COLOR_YELLOW
    jr $ra
color_green:
    lw $v0, COLOR_GREEN
    jr $ra
color_blue:
    lw $v0, COLOR_BLUE
    jr $ra
color_purple:
    lw $v0, COLOR_PURPLE
    jr $ra

##############################################################################
# Exit
##############################################################################
exit:
    li $v0, 10
    syscall
