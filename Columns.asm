################# CSC258 Assembly Project - Milestone 1 ###################
# Static Scene: Playing Field + Random Color Column
# Playing Field: x=0-12, y=0-31 (13x32 units)
# Score Area: x=13-31, y=0-31
##############################################################################

.data
# Memory
ADDR_DSPL: .word 0x10008000

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
    jal draw_screen
    jal handle_keyboard_controls
    
    # --- delay for 60 FPS ---
    li $v0, 32        # syscall 32 = sleep
    li $a0, 16        # ~16 milliseconds per frame
    syscall
    # ------------------------
    
    j game_loop

handle_keyboard_controls:
    # Just return for now
    jr $ra

# ==================== CORE FUNCTIONS ====================

draw_screen:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    jal clear_screen
    jal draw_playing_field_border
    jal draw_score_area
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
    la $s0, column_colors    # Color arraya

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