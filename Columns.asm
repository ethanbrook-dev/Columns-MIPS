################ CSC258H1F Assembly Project: Columns ##################
# This file contains the implementation of Columns.
#
# Student 1: Ethan Brook, 1010976295
# Student 2: [Your Name], [Student Number]
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
ADDR_DSPL:
    .word 0x10008000
ADDR_KBRD:
    .word 0xffff0000

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
current_column: .word 0, 0, 0  # Three gem colors for current column
column_x:       .word 5        # starting X position
column_y:       .word 0        # starting Y position

##############################################################################
# Code
##############################################################################
    .text
    .globl main

main:
    # Initialize the game
    jal draw_black_background
    jal draw_playing_field
    jal generate_new_column
    jal draw_current_column
    
# Main loop
game_loop:
    # For Milestone 1, we just keep displaying the static scene
    j game_loop

# Draw black background for entire screen
draw_black_background:
    lw $t0, ADDR_DSPL           # Base address
    li $t1, 0                   # Pixel counter
    lw $t2, COLOR_BG            # Black color
    
draw_bg_loop:
    sw $t2, 0($t0)              # Draw black pixel
    addi $t0, $t0, 4
    addi $t1, $t1, 1
    blt $t1, 1024, draw_bg_loop # 32x32 = 1024 pixels
    
    jr $ra

# Draw the playing field with brown border and grey interior (12x24)
draw_playing_field:
    lw $t0, ADDR_DSPL
    lw $t1, COLOR_BORDER        # Brown border color
    lw $t2, COLOR_FIELD         # Grey field color
    
    # Playing field dimensions: 12 units wide, 24 units long
    li $t3, 9                   # Start X position (was 10, now 9)
    li $t4, 4                   # Start Y position
    li $t5, 14                  # Total width (12 + 1 pixel border each side)
    li $t6, 26                  # Total height (24 + 1 pixel border top/bottom)
    
    # Calculate starting position
    li $t7, 128                 # Bytes per row
    mul $t8, $t4, $t7           # Y offset
    sll $t9, $t3, 2             # X offset (*4 bytes)
    add $t0, $t0, $t8
    add $t0, $t0, $t9
    
    # Draw top border
    li $s0, 0
    move $s1, $t0               # Save start position for this row

draw_top_border:
    sw $t1, 0($t0)              # Draw brown border
    addi $t0, $t0, 4
    addi $s0, $s0, 1
    blt $s0, $t5, draw_top_border
    
    # Draw sides and fill interior
    li $s2, 1                   # Row counter (skip top border)

draw_field_rows:
    move $t0, $s1               # Reset to start of current row
    mul $s3, $s2, 128           # Calculate row offset
    add $t0, $s1, $s3           # Move to correct row
    
    # Left border
    sw $t1, 0($t0)
    
    # Fill row with grey interior
    addi $t0, $t0, 4
    li $s0, 1                   # Column counter
draw_field_interior:
    sw $t2, 0($t0)              # Draw grey field
    addi $t0, $t0, 4
    addi $s0, $s0, 1
    blt $s0, 13, draw_field_interior  # 12 units wide for interior
    
    # Right border
    sw $t1, 0($t0)
    
    # Update for next row
    addi $s2, $s2, 1
    blt $s2, 25, draw_field_rows  # 24 rows of interior
    
    # Draw bottom border
    move $t0, $s1               # Reset to top left
    li $s3, 25                  # Bottom row offset (24 interior + 1 top border)
    mul $s3, $s3, 128           # Calculate bytes to bottom
    add $t0, $s1, $s3
    
    li $s0, 0

draw_bottom_border:
    sw $t1, 0($t0)
    addi $t0, $t0, 4
    addi $s0, $s0, 1
    blt $s0, $t5, draw_bottom_border
    
    jr $ra

# Generate a new column with three random gems
generate_new_column:
    la $t0, current_column
    
    # Generate three random colors (0-5)
    li $v0, 42
    li $a0, 0
    li $a1, 6
    syscall
    sw $a0, 0($t0)              # Store first gem color
    
    li $v0, 42
    li $a0, 0
    li $a1, 6
    syscall
    sw $a0, 4($t0)              # Store second gem color
    
    li $v0, 42
    li $a0, 0
    li $a1, 6
    syscall
    sw $a0, 8($t0)              # Store third gem color
    
    jr $ra

# Draw the current column at its position
draw_current_column:
    la $t0, current_column
    lw $t1, column_x            # X position (0-11)
    lw $t2, column_y            # Y position (0-23)
    
    # Calculate base position in display (inside playing field)
    lw $t3, ADDR_DSPL
    
    # Calculate offset to playing field interior
    # Field interior starts at (10, 5) - inside the border (shifted left)
    li $t4, 5                   # Start Y of field interior
    li $t5, 10                  # Start X of field interior (was 11, now 10)
    
    # Calculate final position
    li $t6, 128                 # Bytes per row
    add $t7, $t4, $t2           # Total Y offset
    mul $t7, $t7, $t6           # Y offset in bytes
    add $t8, $t5, $t1           # Total X offset
    sll $t8, $t8, 2             # X offset in bytes (*4)
    add $t3, $t3, $t7
    add $t3, $t3, $t8
    
    # Draw three gems vertically
    # Top gem (position 0)
    lw $a0, 0($t0)              # Get color index
    jal get_gem_color
    sw $v0, 0($t3)
    
    # Middle gem (position 1)  
    lw $a0, 4($t0)              # Get color index
    jal get_gem_color
    sw $v0, 128($t3)
    
    # Bottom gem (position 2)
    lw $a0, 8($t0)              # Get color index
    jal get_gem_color
    sw $v0, 256($t3)
    
    jr $ra

# Get actual color value from color index
# Input: $a0 = color index (0-5)
# Output: $v0 = color value
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

# Exit the program
exit:
    li $v0, 10
    syscall