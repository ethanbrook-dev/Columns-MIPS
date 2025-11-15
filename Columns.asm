################# CSC258 Assembly Project - Milestone 1 ###################
# Static Scene: Playing Field + Random Color Column
# Playing Field: x=0-12, y=0-31 (13x32 units)
# Score Area: x=13-31, y=0-31
##############################################################################

.data
# Memory
ADDR_DSPL: .word 0x10008000
ADDR_KBRD: .word 0xffff0000
playing_field: .word 0:416    # 13×32 = 416 positions, all initialized to 0

# Colors
colors:
    .word 0x000000    # 0: Black (background)
    .word 0xff0000    # 1: Red
    .word 0xffa500    # 2: Orange  
    .word 0xffff00    # 3: Yellow
    .word 0x00ff00    # 4: Green
    .word 0x0000ff    # 5: Blue
    .word 0x800080    # 6: Purple
    .word 0x808080    # 7: Gray (border)
    .word 0x333333    # 8: Dark Gray (score area)

# Game state
current_x: .word 6     # Middle of playing field (0-12)
current_y: .word 1     # Start position
column_colors: .word 0, 0, 0  # Will be filled with random colors

.text
.globl main

main:
    # Initialize static game scene (if we make any)
    jal generate_random_colors
game_loop:
    jal handle_keyboard_controls
    jal check_collisions
    jal draw_screen
    
    # --- delay for 60 FPS ---
    li $v0, 32        # syscall 32 = sleep
    li $a0, 16        # ~16 milliseconds per frame
    syscall
    # ------------------------
    
    j game_loop

handle_keyboard_controls:
    lw $t0, ADDR_KBRD               # Setting $t0 = base address for keyboard
    lw $t8, 0($t0)                  # We load first word from keyboard
    beq $t8, 1, handle_keyboard_input      # If first word is 1, then that means a key is pressed and so we proceed to the handle_keyboard_input function
    jr $ra                          # No key pressed => return

handle_keyboard_input:              # If the program gets to this function, then a key is pressed
    lw $a0, 4($t0)                  # We load the second word from keyboard into register $a0 (arg register as we want to use this arg in the inner function calls)

    # If 'a' or 'A', we want the column to move left
    beq $a0, 0x61, move_left        # 0x61 is the keycode for 'a'
    beq $a0, 0x41, move_left        # 0x41 is the keycode for 'A'
    
    # If 'd' or 'D', we want the column to move right  
    beq $a0, 0x64, move_right       # 0x64 is the keycode for 'd'
    beq $a0, 0x44, move_right       # 0x44 is the keycode for 'D'
    
    # If 'w' or 'W', we want to shuffle the column
    beq $a0, 0x77, shuffle_column   # 0x77 is the keycode for 'w'
    beq $a0, 0x57, shuffle_column   # 0x57 is the keycode for 'W'
    
    # If 's' or 'S', we want the column to move down
    beq $a0, 0x73, move_down        # 0x73 is the keycode for 's'
    beq $a0, 0x53, move_down        # 0x53 is the keycode for 'S'
    
    # If 'q' or 'Q', we want to quit the game
    beq $a0, 0x71, quit_game        # 0x71 is the keycode for 'q'
    beq $a0, 0x51, quit_game        # 0x51 is the keycode for 'Q'
    
    jr $ra                          # Unknown key, return

move_left:
    lw $t0, current_x
    ble $t0, 1, move_left_done      # Don't move left if at left edge (x=1)
    addi $t0, $t0, -1
    sw $t0, current_x
move_left_done:
    jr $ra

move_right:
    lw $t0, current_x
    li $t1, 11
    bge $t0, $t1, move_right_done   # Don't move right if at right edge (x=11)
    addi $t0, $t0, 1
    sw $t0, current_x
move_right_done:
    jr $ra

move_down:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Check if we're at the bottom
    lw $t0, current_y
    li $t1, 28
    bge $t0, $t1, move_down_done    # Don't move down if at bottom
    
    # Check for collision below
    jal check_collision_below
    bnez $v0, move_down_done        # Don't move down if collision
    
    # No collision, move down
    lw $t0, current_y
    addi $t0, $t0, 1
    sw $t0, current_y

move_down_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

shuffle_column:
    # Rotate colors: bottom -> top, top -> middle, middle -> bottom
    la $t0, column_colors
    lw $t1, 0($t0)           # Set $t1 = top color
    lw $t2, 4($t0)           # Set $t2 = middle color  
    lw $t3, 8($t0)           # Set $t3 = bottom color
    
    # Shuffle order: bottom becomes top, top becomes middle, middle becomes bottom
    sw $t3, 0($t0)           # Store $t3 INTO first spot of column_colors array => new top = old bottom
    sw $t1, 4($t0)           # Store $t1 INTO second spot of column_colors array => new middle = old top  
    sw $t2, 8($t0)           # Store $t2 INTO third spot of column_colors array => new bottom = old middle

    jr $ra

quit_game:
    li $v0, 10
    syscall

# ==================== CORE FUNCTIONS ====================
draw_screen:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    jal clear_screen
    jal draw_playing_field_border
    jal draw_score_area
    jal draw_frozen_gems
    jal draw_current_column
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

clear_screen:
    la $t0, ADDR_DSPL
    lw $t0, 0($t0)           # Load actual display address
    
    li $t1, 0x000000         # Black color
    li $t2, 0                # Counter
    li $t3, 1024             # 32x32 = 1024 units
    
clear_loop:
    sw $t1, 0($t0)           # Store black
    addi $t0, $t0, 4         # Next unit
    addi $t2, $t2, 1         # Increment counter
    blt $t2, $t3, clear_loop
    jr $ra

draw_playing_field_border:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    li $a2, 7                # Gray color
    
    # Top border (y=0, x=0 to 12)
    li $a1, 0
    li $a0, 0
top_border:
    jal draw_unit
    addi $a0, $a0, 1
    li $t0, 13
    blt $a0, $t0, top_border
    
    # Bottom border (y=31, x=0 to 12)
    li $a1, 31
    li $a0, 0
bottom_border:
    jal draw_unit
    addi $a0, $a0, 1
    li $t0, 13
    blt $a0, $t0, bottom_border
    
    # Left border (x=0, y=0 to 31)
    li $a0, 0
    li $a1, 0
left_border:
    jal draw_unit
    addi $a1, $a1, 1
    li $t0, 32
    blt $a1, $t0, left_border
    
    # Right border (x=12, y=0 to 31)
    li $a0, 12
    li $a1, 0
right_border:
    jal draw_unit
    addi $a1, $a1, 1
    li $t0, 32
    blt $a1, $t0, right_border
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

draw_score_area:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    li $a2, 8                # Dark gray
    
    # Fill area from x=13-31, y=0-31
    li $a1, 0                # y coordinate
score_y_loop:
    li $a0, 13               # x coordinate starts at 13
score_x_loop:
    jal draw_unit
    addi $a0, $a0, 1
    li $t0, 32
    blt $a0, $t0, score_x_loop
    
    addi $a1, $a1, 1
    li $t0, 32
    blt $a1, $t0, score_y_loop
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

generate_random_colors:
    la $t0, column_colors
    li $t1, 3

gen_loop:
    li $v0, 42
    li $a0, 0        # lower bound
    li $a1, 6        # upper bound (exclusive)
    syscall

    # Saturn puts result in $a0
    addi $a0, $a0, 1 # shift range 0–5 → 1–6
    sw $a0, 0($t0)

    addi $t0, $t0, 4
    addi $t1, $t1, -1
    bgtz $t1, gen_loop

    jr $ra

draw_current_column:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Load column position
    lw $a0, current_x        # Grid X (0-12)
    lw $a1, current_y        # Grid Y (0-31)
    la $s0, column_colors    # Color array

    # Draw top gem
    lw $a2, 0($s0)           # Color index
    jal draw_unit
    
    # Draw middle gem
    lw $a2, 4($s0)           # Color index
    addi $a1, $a1, 1         # Move down one row
    jal draw_unit
    
    # Draw bottom gem  
    lw $a2, 8($s0)           # Color index
    addi $a1, $a1, 1         # Move down one more row
    jal draw_unit
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# ==================== FROZEN GEM FUNCTIONS ====================

store_gem:
    # a0 = x (0-12), a1 = y (0-31), a2 = color index (1-6)
    la $t0, playing_field        # Base address of playing field
    li $t1, 13                   # Grid width (13 columns)
    mul $t2, $a1, $t1           # y * 13
    add $t2, $t2, $a0           # + x
    sll $t2, $t2, 2             # * 4 bytes
    add $t2, $t0, $t2           # Final address in playing_field
    
    sw $a2, 0($t2)              # Store color index at calculated address
    jr $ra

load_gem:
    # a0 = x (0-12), a1 = y (0-31)
    # returns: v0 = color index (0 if empty)
    la $t0, playing_field        # Base address of playing field
    li $t1, 13                   # Grid width (13 columns)
    mul $t2, $a1, $t1           # y * 13
    add $t2, $t2, $a0           # + x
    sll $t2, $t2, 2             # * 4 bytes
    add $t2, $t0, $t2           # Final address in playing_field
    
    lw $v0, 0($t2)              # Load color index from address
    jr $ra

draw_frozen_gems:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    li $a1, 0                   # Start from y=0
frozen_y_loop:
    li $a0, 0                   # Start from x=0  
frozen_x_loop:
    jal load_gem                # Check if cell has gem
    beqz $v0, frozen_skip       # Skip if empty (0)
    
    # Draw the frozen gem
    move $a2, $v0               # Color index
    jal draw_unit
    
frozen_skip:
    addi $a0, $a0, 1
    li $t0, 13
    blt $a0, $t0, frozen_x_loop # Loop through x=0-12
    
    addi $a1, $a1, 1
    li $t0, 32
    blt $a1, $t0, frozen_y_loop # Loop through y=0-31
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# ==================== COLLISION DETECTION ====================
check_collisions:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Check if we're at the bottom of the screen
    lw $t0, current_y
    li $t1, 28
    bge $t0, $t1, land_col    # If at bottom, land automatically
    
    # Check for collision with other gems below
    jal check_collision_below
    beqz $v0, collisions_done  # No collision, continue
    
land_col:
    jal land_column            # Land the column
    
collisions_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

check_collision_below:
    # Check if the current column would collide if moved down
    # Returns: v0 = 1 if collision, 0 if no collision
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $a0, current_x
    lw $a1, current_y
    
    # Check position below the entire column (y+3)
    addi $a1, $a1, 3
    li $t0, 32
    bge $a1, $t0, collision_detected  # Would hit bottom of screen
    
    jal load_gem
    bnez $v0, collision_detected      # Space below column has another gem
    
    li $v0, 0                       # No collision
    j collision_return
    
collision_detected:
    li $v0, 1                       # Collision detected
    
collision_return:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
   
land_column:
    # Store current column in playing_field as frozen gems
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    la $s0, column_colors
    lw $a0, current_x
    lw $a1, current_y
    
    # Store top gem
    lw $a2, 0($s0)              # Top color
    jal store_gem
    
    # Store middle gem  
    lw $a2, 4($s0)              # Middle color
    addi $a1, $a1, 1            # y+1
    jal store_gem
    
    # Store bottom gem
    lw $a2, 8($s0)              # Bottom color  
    addi $a1, $a1, 1            # y+2
    jal store_gem
    
    # Generate new random column at top
    jal generate_random_colors
    li $t0, 6
    sw $t0, current_x           # Reset to middle
    li $t0, 1
    sw $t0, current_y           # Reset to top
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra    

# ==================== UTILITY FUNCTIONS ====================

draw_unit:
    # a0 = x (0-31), a1 = y (0-31), a2 = color index (0-8)
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Calculate memory address: address = base + (y * 32 + x) * 4
    la $t0, ADDR_DSPL
    lw $t0, 0($t0)           # Load actual display address
    
    li $t1, 32               # Grid width
    mul $t2, $a1, $t1        # y * 32
    add $t2, $t2, $a0        # + x
    sll $t2, $t2, 2          # * 4 bytes
    add $t2, $t0, $t2        # Final address
    
    # Get actual color value from colors array
    la $t3, colors           # Base of colors array
    sll $t4, $a2, 2          # color index * 4
    add $t3, $t3, $t4        # Address of specific color
    lw $t4, 0($t3)           # Load actual color value
    
    # Store to display memory
    sw $t4, 0($t2)
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# ==================== DISPLAY LAYOUT ====================
# Playing Field: x=0-12, y=0-31 (13 columns x 32 rows)
# Score Area: x=13-31, y=0-31 (19 columns x 32 rows)
# Column Position: x=6 (middle), y=1 (starting position)
# Each "unit" = 1 display cell in the 32x32 grid
##############################################################################