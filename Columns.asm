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
match_mask: .word 0:416     # 13 × 32 mask array, 0 = no match, 1 = part of a match


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

    # NEW: clear any matches and apply gravity
    jal clear_matches_and_gravity

    # NEW: check for game over (gems at top row)
    jal check_game_over

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
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    jal check_collision_left
    bnez $v0, move_left_done        # Don't move if collision
    
    lw $t0, current_x
    addi $t0, $t0, -1
    sw $t0, current_x
    
move_left_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

move_right:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    jal check_collision_right
    bnez $v0, move_right_done       # Don't move if collision
    
    lw $t0, current_x
    addi $t0, $t0, 1
    sw $t0, current_x
    
move_right_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
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
    
    # Also in here after check if you made a new column but it automatically collides (occupied) because if so we gotta take the user to the game over screen or smth

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
clear_match_mask:
    la  $t0, match_mask
    li  $t1, 416        # number of cells
    li  $t2, 0
clear_mask_loop:
    sw  $zero, 0($t0)
    addi $t0, $t0, 4
    addi $t2, $t2, 1
    blt $t2, $t1, clear_mask_loop
    jr  $ra
store_mask:
    # a0 = x, a1 = y, a2 = value (0 or 1)
    la  $t0, match_mask
    li  $t1, 13
    mul $t2, $a1, $t1     # y * 13
    add $t2, $t2, $a0     # + x
    sll $t2, $t2, 2       # *4
    add $t2, $t0, $t2
    sw  $a2, 0($t2)
    jr  $ra
mark_matches:
    addi $sp, $sp, -16
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)
    sw   $s1, 8($sp)
    sw   $s2, 12($sp)

    # Start with a clean mask
    jal  clear_match_mask

    li   $s2, 0          # match_flag = 0

    ############################
    # Vertical scan (x fixed)
    ############################
    li   $s0, 0          # x = 0..12
vert_x_loop:
    li   $s1, 0          # y = 0..29 (start of triple)
vert_y_loop:
    li   $t0, 29
    bgt  $s1, $t0, vert_y_done

    # c0 = gem(x, y)
    move $a0, $s0
    move $a1, $s1
    jal  load_gem
    move $t3, $v0
    blez $t3, vert_y_next       # empty or 0 => no triple starting here

    # c1 = gem(x, y+1)
    move $a0, $s0
    addi $a1, $s1, 1
    jal  load_gem
    move $t4, $v0
    bne  $t3, $t4, vert_y_next

    # c2 = gem(x, y+2)
    move $a0, $s0
    addi $a1, $s1, 2
    jal  load_gem
    move $t5, $v0
    bne  $t3, $t5, vert_y_next

    # Found vertical triple
    li   $s2, 1

    # Mark (x, y), (x, y+1), (x, y+2)
    move $a0, $s0
    move $a1, $s1
    li   $a2, 1
    jal  store_mask

    move $a0, $s0
    addi $a1, $s1, 1
    li   $a2, 1
    jal  store_mask

    move $a0, $s0
    addi $a1, $s1, 2
    li   $a2, 1
    jal  store_mask

vert_y_next:
    addi $s1, $s1, 1
    j    vert_y_loop

vert_y_done:
    addi $s0, $s0, 1
    li   $t1, 12
    ble  $s0, $t1, vert_x_loop

    ############################
    # Horizontal scan (y fixed)
    ############################
    li   $s0, 0          # y = 0..31
horiz_y_loop:
    li   $t0, 31
    bgt  $s0, $t0, horiz_done

    li   $s1, 0          # x = 0..10 (start of triple)
horiz_x_loop:
    li   $t1, 10
    bgt  $s1, $t1, horiz_x_done

    # c0 = gem(x, y)
    move $a0, $s1
    move $a1, $s0
    jal  load_gem
    move $t3, $v0
    blez $t3, horiz_x_next

    # c1 = gem(x+1, y)
    addi $a0, $s1, 1
    move $a1, $s0
    jal  load_gem
    move $t4, $v0
    bne  $t3, $t4, horiz_x_next

    # c2 = gem(x+2, y)
    addi $a0, $s1, 2
    move $a1, $s0
    jal  load_gem
    move $t5, $v0
    bne  $t3, $t5, horiz_x_next

    # Found horizontal triple
    li   $s2, 1

    # Mark (x, y), (x+1, y), (x+2, y)
    move $a0, $s1
    move $a1, $s0
    li   $a2, 1
    jal  store_mask

    addi $a0, $s1, 1
    move $a1, $s0
    li   $a2, 1
    jal  store_mask

    addi $a0, $s1, 2
    move $a1, $s0
    li   $a2, 1
    jal  store_mask

horiz_x_next:
    addi $s1, $s1, 1
    j    horiz_x_loop

horiz_x_done:
    addi $s0, $s0, 1
    j    horiz_y_loop

horiz_done:

    ############################
    # Diagonal scan: \ (down-right)
    ############################
    li   $s0, 0          # x = 0..10
diag_dr_x_loop:
    li   $t0, 10
    bgt  $s0, $t0, diag_dr_done

    li   $s1, 0          # y = 0..29
diag_dr_y_loop:
    li   $t1, 29
    bgt  $s1, $t1, diag_dr_next_x

    # c0 = gem(x, y)
    move $a0, $s0
    move $a1, $s1
    jal  load_gem
    move $t3, $v0
    blez $t3, diag_dr_y_next

    # c1 = gem(x+1, y+1)
    addi $a0, $s0, 1
    addi $a1, $s1, 1
    jal  load_gem
    move $t4, $v0
    bne  $t3, $t4, diag_dr_y_next

    # c2 = gem(x+2, y+2)
    addi $a0, $s0, 2
    addi $a1, $s1, 2
    jal  load_gem
    move $t5, $v0
    bne  $t3, $t5, diag_dr_y_next

    # Found diagonal \ triple
    li   $s2, 1

    # Mark (x, y), (x+1, y+1), (x+2, y+2)
    move $a0, $s0
    move $a1, $s1
    li   $a2, 1
    jal  store_mask

    addi $a0, $s0, 1
    addi $a1, $s1, 1
    li   $a2, 1
    jal  store_mask

    addi $a0, $s0, 2
    addi $a1, $s1, 2
    li   $a2, 1
    jal  store_mask

diag_dr_y_next:
    addi $s1, $s1, 1
    j    diag_dr_y_loop

diag_dr_next_x:
    addi $s0, $s0, 1
    j    diag_dr_x_loop

diag_dr_done:

    ############################
    # Diagonal scan: / (up-right)
    ############################
    li   $s0, 0          # x = 0..10
diag_ur_x_loop:
    li   $t0, 10
    bgt  $s0, $t0, diag_ur_done

    li   $s1, 2          # y = 2..31 (need y-2 >= 0)
diag_ur_y_loop:
    li   $t1, 31
    bgt  $s1, $t1, diag_ur_next_x

    # c0 = gem(x, y)
    move $a0, $s0
    move $a1, $s1
    jal  load_gem
    move $t3, $v0
    blez $t3, diag_ur_y_next

    # c1 = gem(x+1, y-1)
    addi $a0, $s0, 1
    addi $a1, $s1, -1
    jal  load_gem
    move $t4, $v0
    bne  $t3, $t4, diag_ur_y_next

    # c2 = gem(x+2, y-2)
    addi $a0, $s0, 2
    addi $a1, $s1, -2
    jal  load_gem
    move $t5, $v0
    bne  $t3, $t5, diag_ur_y_next

    # Found diagonal / triple
    li   $s2, 1

    # Mark (x, y), (x+1, y-1), (x+2, y-2)
    move $a0, $s0
    move $a1, $s1
    li   $a2, 1
    jal  store_mask

    addi $a0, $s0, 1
    addi $a1, $s1, -1
    li   $a2, 1
    jal  store_mask

    addi $a0, $s0, 2
    addi $a1, $s1, -2
    li   $a2, 1
    jal  store_mask

diag_ur_y_next:
    addi $s1, $s1, 1
    j    diag_ur_y_loop

diag_ur_next_x:
    addi $s0, $s0, 1
    j    diag_ur_x_loop

diag_ur_done:

    ############################
    # Return: did we find any?
    ############################
    move $v0, $s2       # 1 if any match, 0 otherwise

    lw   $ra, 0($sp)
    lw   $s0, 4($sp)
    lw   $s1, 8($sp)
    lw   $s2, 12($sp)
    addi $sp, $sp, 16
    jr   $ra

remove_marked_and_apply_gravity:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    ########################
    # Pass 1: clear matches
    ########################
    li   $a1, 0          # y = 0..31
rm_y_loop:
    li   $a0, 0          # x = 0..12
rm_x_loop:
    # mask[x, y]
    la   $t0, match_mask
    li   $t1, 13
    mul  $t2, $a1, $t1
    add  $t2, $t2, $a0
    sll  $t2, $t2, 2
    add  $t2, $t0, $t2
    lw   $t3, 0($t2)
    beqz $t3, rm_x_next      # if mask == 0, skip

    # Set gem(x, y) to 0 (empty)
    li   $a2, 0
    jal  store_gem

rm_x_next:
    addi $a0, $a0, 1
    li   $t4, 13
    blt  $a0, $t4, rm_x_loop

    addi $a1, $a1, 1
    li   $t5, 32
    blt  $a1, $t5, rm_y_loop

    ########################
    # Pass 2: gravity
    ########################
    li   $t6, 0          # x = 0..12
grav_x_loop:
    li   $t7, 30         # write_y = bottom
    li   $t8, 30         # y = bottom, count down

grav_y_loop:
    # c = gem(x, y)
    move $a0, $t6
    move $a1, $t8
    jal  load_gem
    beqz $v0, grav_y_next     # empty => skip

    # If y != write_y, move gem down
    beq  $t8, $t7, grav_no_move

    # store gem at (x, write_y)
    move $a0, $t6
    move $a1, $t7
    move $a2, $v0
    jal  store_gem

    # zero old spot (x, y)
    move $a0, $t6
    move $a1, $t8
    li   $a2, 0
    jal  store_gem

grav_no_move:
    addi $t7, $t7, -1          # write_y--

grav_y_next:
    addi $t8, $t8, -1          # y--
    bgez $t8, grav_y_loop

    # next column
    addi $t6, $t6, 1
    li   $t9, 13
    blt  $t6, $t9, grav_x_loop

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra
clear_matches_and_gravity:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

match_loop:
    jal  mark_matches
    beqz $v0, match_done       # if no matches, stop
    jal  remove_marked_and_apply_gravity
    j    match_loop            # repeat – chain reactions!

match_done:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

check_game_over:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    li   $a1, 1          # y = 1 (top playable row)
    li   $a0, 1          # x = 1..11 (inside walls)
game_over_x_loop:
    jal  load_gem
    bnez $v0, game_over_now   # any gem here => game over

    addi $a0, $a0, 1
    li   $t0, 11
    ble  $a0, $t0, game_over_x_loop

    # no gem on top row
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

game_over_now:
    # Clean stack then exit
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    j    quit_game          # calls syscall 10

# ==================== BOTTOM  COLLISION DETECTION ====================
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

# ==================== SIDE COLLISION DETECTION ====================

check_collision_left:
    # Check if moving left would cause collision
    # Returns: v0 = 1 if collision, 0 if no collision
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $a0, current_x
    lw $a1, current_y
    
    # Check left wall
    ble $a0, 1, collision_left_detected  # At left edge (x=1 is left border)
    
    # Check ALL THREE gems to the left
    # Check top gem left (x-1, y)
    addi $a0, $a0, -1
    jal load_gem
    bnez $v0, collision_left_detected
    
    # Check middle gem left (x-1, y+1)
    lw $a0, current_x
    lw $a1, current_y
    addi $a0, $a0, -1
    addi $a1, $a1, 1
    jal load_gem
    bnez $v0, collision_left_detected
    
    # Check bottom gem left (x-1, y+2)
    lw $a0, current_x
    lw $a1, current_y
    addi $a0, $a0, -1
    addi $a1, $a1, 2
    jal load_gem
    bnez $v0, collision_left_detected
    
    li $v0, 0                       # No collision
    j collision_left_return
    
collision_left_detected:
    li $v0, 1                       # Collision detected
    
collision_left_return:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

check_collision_right:
    # Check if moving right would cause collision
    # Returns: v0 = 1 if collision, 0 if no collision
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $a0, current_x
    lw $a1, current_y
    
    # Check right wall
    li $t0, 11
    bge $a0, $t0, collision_right_detected  # At right edge (x=11 is right border)
    
    # Check ALL THREE gems to the right
    # Check top gem right (x+1, y)
    addi $a0, $a0, 1
    jal load_gem
    bnez $v0, collision_right_detected
    
    # Check middle gem right (x+1, y+1)
    lw $a0, current_x
    lw $a1, current_y
    addi $a0, $a0, 1
    addi $a1, $a1, 1
    jal load_gem
    bnez $v0, collision_right_detected
    
    # Check bottom gem right (x+1, y+2)
    lw $a0, current_x
    lw $a1, current_y
    addi $a0, $a0, 1
    addi $a1, $a1, 2
    jal load_gem
    bnez $v0, collision_right_detected
    
    li $v0, 0                       # No collision
    j collision_right_return
    
collision_right_detected:
    li $v0, 1                       # Collision detected
    
collision_right_return:
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
    
# ==================== DISPLAY LAYOUT ====================
# Playing Field: x=0-12, y=0-31 (13 columns x 32 rows)
# Score Area: x=13-31, y=0-31 (19 columns x 32 rows)
# Column Position: x=6 (middle), y=1 (starting position)
# Each "unit" = 1 display cell in the 32x32 grid
##############################################################################