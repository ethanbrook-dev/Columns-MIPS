################ CSC258H1F Assembly Project: Columns ##################
# This file contains the implementation of Columns.
#
# Student 1: Ethan Brook, 1010976295
# Student 2: [Name], [Student Number]
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

.data
    ADDR_DSPL:        .word 0x10008000      # Address for display memory (!!! $gp points here !!!)
    ADDR_KBRD: 	      .word 0xffff0000      # Address for keyboard
    COLOR_RED:        .word 0xff0000
    COLOR_ORANGE:     .word 0xff8800
    COLOR_YELLOW:     .word 0xffff00
    COLOR_GREEN:      .word 0x00ff00
    COLOR_BLUE:       .word 0x0000ff
    COLOR_PURPLE:     .word 0x8800ff
    COLOR_BG:         .word 0x000000        # Black background
    COLOR_BORDER:     .word 0x8B4513        # Brown border
    COLOR_FIELD:      .word 0x808080        # Grey playing field
    current_column:   .word 0, 0, 0         # Three gem colors for current column
    column_x:         .word 5               # starting X position
    column_y:         .word 0               # starting Y position

.text
.globl main

##############################################################################
# Main Program
##############################################################################
main:
    jal generate_new_column    # Start the game
    
game_loop:
    jal draw_black_background
    jal draw_playing_field
    jal draw_current_column
    jal handle_keyboard_input
    
    # Add sleep to control game speed (approximately 60 FPS)
    li $v0, 32
    li $a0, 16                 # Sleep for ~16ms (60 FPS)
    syscall
    
    j game_loop               # Loop forever

##############################################################################
# Handle keyboard input
##############################################################################
handle_keyboard_input:
    addi $sp, $sp, -4
    sw $ra, 0($sp)              # Save return address
    
    lw $t0, ADDR_KBRD           # $t0 = base address for keyboard
    lw $t1, 0($t0)              # Load first word from keyboard
    beq $t1, 1, process_input   # If first word 1, key is pressed
    j handle_keyboard_done      # No key pressed
    
process_input:
    lw $t2, 4($t0)              # Load second word from keyboard (ASCII value)
    
    # Check for 'a' or 'A' key (move left)
    beq $t2, 0x61, move_left    # 'a'
    beq $t2, 0x41, move_left    # 'A'
    
    # Check for 'd' or 'D' key (move right)  
    beq $t2, 0x64, move_right   # 'd'
    beq $t2, 0x44, move_right   # 'D'
    
    # Check for 's' or 'S' key (drop down)
    beq $t2, 0x73, drop_down    # 's'
    beq $t2, 0x53, drop_down    # 'S'
    
    # Check for 'w' or 'W' key (shuffle column)
    beq $t2, 0x77, shuffle_column  # 'w'
    beq $t2, 0x57, shuffle_column  # 'W'
    
    # Check for 'q' or 'Q' key (quit game)
    beq $t2, 0x71, exit    # 'q'
    beq $t2, 0x51, exit    # 'Q'
    
    j handle_keyboard_done      # Unknown key, ignore

move_left:
    lw $t3, column_x
    ble $t3, 0, handle_keyboard_done  # Don't move if at left edge (at x=0)
    addi $t3, $t3, -1
    sw $t3, column_x
    j handle_keyboard_done

move_right:
    lw $t3, column_x
    li $t4, 11                   # Right boundary (y=11)
    bge $t3, $t4, handle_keyboard_done  # Don't move if at right edge
    addi $t3, $t3, 1
    sw $t3, column_x
    j handle_keyboard_done

drop_down:
    lw $t3, column_y
    li $t4, 21                  # Bottom boundary
    bge $t3, $t4, handle_keyboard_done  # Don't move if at bottom
    addi $t3, $t3, 1
    sw $t3, column_y
    j handle_keyboard_done

shuffle_column:
    la $t3, current_column
    lw $t4, 0($t3)              # Load top gem color
    lw $t5, 4($t3)              # Load middle gem color  
    lw $t6, 8($t3)              # Load bottom gem color
    
    # Rotate colors downward (top -> middle, middle -> bottom, bottom -> top)
    sw $t6, 0($t3)              # Bottom goes to top
    sw $t4, 4($t3)              # Top goes to middle
    sw $t5, 8($t3)              # Middle goes to bottom
    j handle_keyboard_done

handle_keyboard_done:
    lw $ra, 0($sp)              # Restore return address
    addi $sp, $sp, 4
    jr $ra

##############################################################################
# Display / Drawing
##############################################################################
# Draw black background for entire screen
draw_black_background:
    lw $t2, COLOR_BG        # Load background color
    move $t0, $gp           # $gp points to display memory
    sw $t2, 0($t0)
    
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
    addi $sp, $sp, -4   # Make space on stack
    sw $ra, 0($sp)      # Save return address

    la $t0, current_column
    lw $t1, column_x
    lw $t2, column_y
    lw $t3, ADDR_DSPL

    li $t4, 5
    li $t5, 10
    li $t6, 128

    add $t7, $t4, $t2
    mul $t7, $t7, $t6
    add $t8, $t5, $t1
    sll $t8, $t8, 2
    add $t3, $t3, $t7
    add $t3, $t3, $t8

    lw $a0, 0($t0)
    jal get_gem_color
    sw $v0, 0($t3)

    lw $a0, 4($t0)
    jal get_gem_color
    sw $v0, 128($t3)

    lw $a0, 8($t0)
    jal get_gem_color
    sw $v0, 256($t3)

    lw $ra, 0($sp)      # Restore return address
    addi $sp, $sp, 4    # Restore stack
    jr $ra

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
    jr $ra

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
