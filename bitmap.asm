######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       4
# - Unit height in pixels:      4
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################


.data 0x10010000
THE_COLOUR:
    .word       0x885A89    # an initial colour


.text
main:
    # load a colour to draw
    lui $t0, 0x88
    ori $t0, $0, 0x5A89
    # paint the first unit with the colour
    sw $t0, 0($gp)

    # TODO
    #   Add calls to your functions below to try them out
   
   
    # --------------- UNCOMMENT TO RUN TESTS ---------------
    # addi $a0, $0, 12       # x coordinate
    # addi $a1, $0, 12       # y coordinate
    # addi $a2, $0, 0x00FF00 # color
    # # 0x00FF00
    # # 0x0000FF
   
    # addi $a0, $0, 38
    # addi $a1, $0, 38
    # addi $a2, $0, 0xFFFFFF
    # jal fill_unit       # Call fill_unit
   
    # addi $a0, $0, 0
    # addi $a1, $0, 40
    # addi $a2, $0, 55
    # jal draw_horizontal_line
   
    # addi $a0, $0, 40
    # addi $a1, $0, 0
    # addi $a2, $0, 50
    # jal draw_vertical_line
   
    # addi $a0, $0, 10
    # addi $a1, $0, 50
    # addi $a2, $0, 12
    # jal draw_horizontal_line
   
    # addi $a0, $0, 10
    # addi $a1, $0, 4
    # addi $a2, $0, 3
    # jal draw_vertical_line
   
   
    # addi $a0, $0, 30
    # addi $a1, $0, 40
    # addi $a2, $0, 15
    # addi $a3, $0, 15
    # jal draw_rectangle
   
   
    # # Test for 'abs' procedure
    # addi $a0, $0, 12
    # addi $a1, $0, 15
    # jal abs
    # add $t0, $0, $v0 # $t0 should end up holding |$a0 - $a1|
   
    # addi $a0, $0, 12
    # addi $a1, $0, 15
    # addi $a2, $0, 6
    # addi $a3, $0, 9
    # jal draw_line
   
    addi $a0, $0, 12
    addi $a1, $0, 30
    addi $a2, $0, 6
    addi $a3, $0, 24
    jal draw_line

exit:
        addi $v0, $0, 10
        syscall


# fill_unit(x, y, colour) -> void
#   Draw a unit with the given colour at location (x, y).
# MY NOTES: The address in memory holding the colour for cell with location (x,y) is: {base_address} + {width}*y + x
fill_unit:
    # PROLOGUE
    # Save registers if needed

    # BODY
    # Calculate the starting memory address
    # li $t1, 256        # Load display width in pixels
    # mul $t1, $t1, $a1  # Multiply display width by y
    sll $t1, $a1, 6  # Multiply display width (64, since we have 256 pixels and a unit width of 4) by y
    add $t1, $t1, $a0  # Add x to get the pixel offset

    # Currently, $t1 holds the number of units from the start of the grid till until we reach unit (x,y). Since the unit width is 4 pixels, we need to
    # multiply that amount by 4 to find the number of pixels from the first pixel of the grid till the one corresponding to the unit-position (x,y).
    sll $t1, $t1, 2   
   
    # Loading the base address
    lui $t3, 0x1000    # Load the upper part of the base address
    ori $t3, $t3, 0x8000 # Complete the base address 0x10008000
   
    # $t1 currently holds the exact number of pixels from the first pixel of the grid until the one corresponding to unit-position (x,y). Since the memory
    # address corresponding to the first pixel is the base address 0x10008000, we add 0x10008000 to $t1 to determine the memory address corresponding to the
    # first pixel of our unit-position (x,y).
    add $t3, $t3, $t1  # Add the byte offset to the base address
       
    # Storing the color to address $t3, which corresponds to the memory address that holds the colour of the first pixel of the unit at (x,y).
    sw $a2, 0($t3)     # Store the color at the current address

    # EPILOGUE
    jr $ra             # Return to the caller
   


# draw_horizontal_line(x, y, size) -> void
#   Draw a straight line that starts at (x, y) and ends at (x + width, y)
#   using the colour found at THE_COLOUR.
# Arguments:
#   $a0 - x coordinate
#   $a1 - y coordinate
#   $a2 - size of the line
draw_horizontal_line:
    # PROLOGUE
    # Save the return address and any callee-saved registers you'll use
    addi $sp, $sp, -4    # Decrement the stack pointer to make space
    sw $ra, 0($sp)       # Save the return address on the stack

    # Save arguments if you need to use the registers for other things
    addi $sp, $sp, -12   # Make space for three more registers
    sw $a0, 0($sp)       # Save $a0
    sw $a1, 4($sp)       # Save $a1
    sw $a2, 8($sp)      # Save $a2
   
    # this holds the required size of the line (TRANSLATED WITH INITIAL X $a0), so it will be used to check whether we should exit the for loop.
    add $t3, $a0, $a2 

    # BODY
    # Load the colour to use into $a2
    lw $a2, THE_COLOUR   # Assume THE_COLOUR is a memory address with the color

    # Initialize counter in $t0
    add $t0, $a0, $0     # $t0 will track the current x position
   
    # addi $t3, $0, 64    # this holds number of units fitting in a row, so it will be used to check whether we should exit the for loop.

    # Begin loop to draw the line
draw_line_loop:
    # Call fill_unit for each unit in the horizontal line
    add $a0, $0, $t0     # the x position; note we are mutating $a0 but we don't care because we have saved the original value in the stack.
   
    # CAREFUL! calling 'jal fill_unit' changes the temporary ragisters (which are non-preserved), causing us problems because we are using these non-preserved
    # registers.
    # In particular, it is changing $t1 and $t3, so we will store these in the stack before calling the function.
    addi $sp, $sp, -8 # decrementing the stack pointer so that we get space for two more words
    sw $t1, 4($sp) # saving the value of $t1 at the stack (one word before the word that the stack pointer points to)
    sw $t3, 0($sp) # saving the value of $t3 at the stack (to the word that the stack pointer points to)
   
    # Now, we can call 'fill_unit' since the values of $t1 and $t2 are in the stack, and we can restore them right after 'fill_unit' returns.
    jal fill_unit
   
    # Restoring $t1 and $t3
    lw $t1, -4($sp)
    lw $t3, 0($sp)
    # SOS: had forgotten the line below: i.e. I was decrementing but forgot to increment back when restoring the values.
    addi $sp, $sp, 8 # decrementing the stack pointer so that we get space for two more words
   
    # Increment x position
    addi $t0, $t0, 1     # Increment by the width of one unit (4 pixels)

    # # Load the updated x position and size to compare
    # lw $a3, 4($sp)       # Load original x position
    # lw $t1, 12($sp)      # Load size
    # add $t1, $a3, $t1    # Calculate the ending x position

    # # Check if the end of the line is reached
    # blt $t0, $t1, draw_line_loop # If current x < end x, loop
   
    slt $t2, $t0, $t3    # seeing if our x-pos accumulator has exeeded the grid width, in which case the loop must be exited.
    bne $t2, $0, draw_line_loop
    # blt $t0, $t1, draw_line_loop # Loop back if current x < end x

    # EPILOGUE
    # Restore the return address and any callee-saved registers
    addi $t5, $sp, 12
    lw $ra, 12($sp)       # Restore the return address
    addi $sp, $sp, 16    # Reset the stack pointer

    jr $ra               # Return to caller


# draw_vertical_line(x, y, size) -> void
#   Draw a straight line that starts at (x, y) and ends at (x, y + size)
#   using the colour found at THE_COLOUR.
draw_vertical_line:
    # PROLOGUE
    # Save the return address and any callee-saved registers you'll use
    addi $sp, $sp, -4    # Decrement the stack pointer to make space
    sw $ra, 0($sp)       # Save the return address on the stack

    # Save arguments if you need to use the registers for other things
    addi $sp, $sp, -12   # Make space for three more registers
    sw $a0, 0($sp)       # Save $a0
    sw $a1, 4($sp)       # Save $a1
    sw $a2, 8($sp)      # Save $a2
   
    # this holds the required size of the line (TRANSLATED WITH INITIAL Y $a0), so it will be used to check whether we should exit the for loop.
    add $t3, $a1, $a2
    # Why does the code 'lw $t3, 8($sp)' below not work?

    # BODY
    # Load the colour to use into $a2
    lw $a2, THE_COLOUR   # Assume THE_COLOUR is a memory address with the color

    # Initialize counter in $t0
    add $t0, $a1, $0     # $t0 will track the current y position
   
    # addi $t3, $0, 64    # this holds number of units fitting in a column, so it will be used to check whether we should exit the for loop.
    # lw $t3, 8($sp)  # this holds number of units fitting in a column, so it will be used to check whether we should exit the for loop.

    # Begin loop to draw the line
draw_line_loop_2:
    # Call fill_unit for each unit in the horizontal line
    add $a1, $0, $t0     # the y position; note we are mutating $a0 but we don't care because we have saved the original value in the stack.
   
    # CAREFUL! calling 'jal fill_unit' changes the temporary ragisters (which are non-preserved), causing us problems because we are using these non-preserved
    # registers.
    # In particular, it is changing $t1 and $t3, so we will store these in the stack before calling the function.
    addi $sp, $sp, -8 # decrementing the stack pointer so that we get space for two more words
    sw $t1, 4($sp) # saving the value of $t1 at the stack (one word before the word that the stack pointer points to)
    sw $t3, 0($sp) # saving the value of $t3 at the stack (to the word that the stack pointer points to)
   
    # Now, we can call 'fill_unit' since the values of $t1 and $t2 are in the stack, and we can restore them right after 'fill_unit' returns.
    jal fill_unit
   
    # Restoring $t1 and $t3
    lw $t1, -4($sp)
    lw $t3, 0($sp)
    # SOS: had forgotten the line below: i.e. I was decrementing but forgot to increment back when restoring the values.
    addi $sp, $sp, 8 # decrementing the stack pointer so that we get space for two more words
   
    # Increment x position
    addi $t0, $t0, 1     # Increment by the width of one unit (4 pixels)

    # # Load the updated x position and size to compare
    # lw $a3, 4($sp)       # Load original x position
    # lw $t1, 12($sp)      # Load size
    # add $t1, $a3, $t1    # Calculate the ending x position

    # # Check if the end of the line is reached
    # blt $t0, $t1, draw_line_loop # If current x < end x, loop
   
    slt $t2, $t0, $t3    # seeing if our x-pos accumulator has exeeded the grid width, in which case the loop must be exited.
    bne $t2, $0, draw_line_loop_2
    # blt $t0, $t1, draw_line_loop # Loop back if current x < end x

    # EPILOGUE
    # Restore the return address and any callee-saved registers
    addi $t5, $sp, 12
    lw $ra, 12($sp)       # Restore the return address
    addi $sp, $sp, 16    # Reset the stack pointer

    jr $ra               # Return to caller


# draw_rectangle(x, y, width, height) -> void
#   Draw the outline of a rectangle whose top-left corner is at (x, y)
#   and bottom-right corner is at (x + width, y + height) using the
#   colour found at THE_COLOUR.
draw_rectangle:
    # PROLOGUE
   
    # Decrementing the stack pointer to leave space to store the return adress $ra (this needs to be preserved, but calling nested procedures will change it)
    addi $sp, $sp, -4
    sw $ra, 0($sp)
   
    # Decrementing the stack pointer to leave space to store the arguments ($a0-$a3)
    addi $sp, $sp, -16
    sw $a3, 0($sp)
    sw $a2, 4($sp)
    sw $a1, 8($sp)
    sw $a0, 12($sp)
   

    # BODY
     # Note: x = $a0, y = $a1, width = $a2, height = $a3
   
    # essentially loading the original arguments $a0, $a1, $a2, and $a3
    lw $t0, 12($sp)
    lw $t1, 8($sp)
    lw $t2, 4($sp)
    lw $t3, 0($sp)
    add $a0, $0, $t0
    add $a1, $0, $t1
    add $a2, $0, $t2
    jal draw_horizontal_line
   
    # essentially loading the original arguments $a0, $a1, $a2, and $a3
    lw $t0, 12($sp)
    lw $t1, 8($sp)
    lw $t2, 4($sp)
    lw $t3, 0($sp)
    add $a0, $t2, $t0
    addi $a0, $a0, -1 # without this we have an off-by-one error
    add $a1, $0, $t1
    add $a2, $0, $t3
    jal draw_vertical_line
   
    # essentially loading the original arguments $a0, $a1, $a2, and $a3
    lw $t0, 12($sp)
    lw $t1, 8($sp)
    lw $t2, 4($sp)
    lw $t3, 0($sp)
    add $a0, $0, $t0
    add $a1, $t3, $t1
    addi $a1, $a1, -1 # without this we have an off-by-one error
    add $a2, $0, $t2
    jal draw_horizontal_line
   
    # essentially loading the original arguments $a0, $a1, $a2, and $a3
    lw $t0, 12($sp)
    lw $t1, 8($sp)
    lw $t2, 4($sp)
    lw $t3, 0($sp)
    add $a0, $0, $t0
    add $a1, $0, $t1
    add $a2, $0, $t3
    jal draw_vertical_line

    # EPILOGUE
    lw $ra, 16($sp) # restoring the original return address
    addi $sp, $sp, 20 # popping stack frames
   
    jr $ra



# draw_line(x0, y0, x1, y1) -> void
draw_line:
    # ----------PROLOGUE----------
    # Decrementing the stack pointer to leave space to store the return adress $ra (this needs to be preserved, but calling nested procedures will change it)
    # Storing arguments on the stack (since to call other procedures we will have to modify these registers).
    addi $sp, $sp, -20
    sw $a3, 0($sp)
    sw $a2, 4($sp)
    sw $a1, 8($sp)
    sw $a0, 12($sp)
    sw $ra, 16($sp)
   
    # ----------BODY----------
   
    #                                                                   ~~~ dx - $t0 ~~~
    # Note, we do not need to change $a0 and $a1 at all because currently $a0 and $a1 already contain 'x0' and 'x1', so the arguments are ready for
    # abs to be called
    jal abs
    add $t0, $0, $v0  # storing the return value of 'abs', so <$t0 = dx>
   
    #                                                                   ~~~ dy - $t1 ~~~
    add $a0, $0, $a2
    add $a1, $0, $a3
    jal abs
    sub $t1, $0, $v0  # storing the return value of 'abs', so <$t1 = dy>
    lw $a0, 12($sp)
    lw $a1, 8($sp)
   
    #                                                                   ~~~ error - $t2 ~~~
    add $t2, $t0, $t1
   
    #                                                                   ~~~ SlopeX - represented by $t3 ~~~
        lw $a0, 12($sp) # recall we had changed this before calling abs the second time, so we are re-loading it from the stack.
        blt $a0, $a1, slopeXPos
        addi $t3, $0, -1
        j afterSlopeX
       
    slopeXPos:
        addi $t3, $0, 1
       
    afterSlopeX:
    #                                                                   ~~~ SlopeY - represented by $t4 ~~~
        blt $a2, $a3, slopeYPos
        addi $t4, $0, -1
        j afterSlopeY
       
    slopeYPos:
        addi $t4, $0, 1
       
    afterSlopeY:
   
   
   
   
   

    # # LOOP...
    # loop_check:
        # # Restoring original values to ensure that a3=y2, a2=y1, a1=x2, and a0=x1.
        # lw $a3, 0($sp)
        # lw $a2, 4($sp)
        # lw $a1, 8($sp)
        # lw $a0, 12($sp)
       
        # bne $a0, $a1, loop_continue
        # bne $a2, $a3, loop_continue
        # j loop_end
   
    # loop_continue:
            # # Preparing arguments for fill_unit call
            # add $a0, $0, $a0
            # add $a1, $0, $a2
           
            # jal fill_unit
           
            # # $t5 -> Error2
            # sll $t5, $t2, 1 # Error2 ← 2 × Error
           
            # slt $t6, $t5, $t1
           
            # bne $t6, $0, after_first_if
           
            # add $t2, $t2, $t1
       
        # after_first_if:
            # slt $t6, $t0, $t5
           
            # bne $t6, $0, after_second_if
           
           
           
        # after_second_if:
       
        # j loop_check
   
    # loop_end:
   
   
   
   
    # LOOP...
   
    #  ensure that a0=x0, a1=y0
    lw $a1, 4($sp)
    lw $a0, 12($sp)
       
    loop_check:
        # Restoring original values to ensure that a3=y2, a2=y1, a1=x2, and a0=x1.
        lw $a3, 0($sp) # -> y1
        lw $a2, 8($sp) # -> x1
      
       
        bne $a0, $a2, loop_continue
        bne $a1, $a3, loop_continue
        j loop_end
   
    loop_continue:
            # Storing state for preservation purposes
            addi $sp, $sp, -28
            sw $a0, 0($sp)
            sw $a1, 4($sp)
            sw $t0, 8($sp)
            sw $t1, 12($sp)
            sw $t2, 16($sp)
            sw $a2, 20($sp)
            sw $t3, 24($sp)
           
           
            # Preparing arguments for fill_unit call
            # add $a0, $0, $a0
            # add $a1, $0, $a2
            add $a2, $0, 0xFFFFFF
           
           
            jal fill_unit
           
            # Re-storing state
            lw $a0, 0($sp)
            lw $a1, 4($sp)
            lw $t0, 8($sp)
            lw $t1, 12($sp)
            lw $t2, 16($sp)
            lw $a2, 20($sp)
            lw $t3, 24($sp)
            addi $sp, $sp, 28
           
           
           
            # $t5 -> Error2
            sll $t5, $t2, 1 # Error2 ← 2 × Error
           
            slt $t6, $t5, $t1
           
            bne $t6, $0, after_first_if
           
            add $a0, $a0, $t3 # x0 ← x0 + SlopeX
       
        after_first_if:
            slt $t6, $t0, $t5
           
            bne $t6, $0, after_second_if
           
            add $a1, $a1, $t4 # y0 ← y0 + SlopeY
           
           
           
        after_second_if:
       
        j loop_check
   
    loop_end:
   
   
    # EPILOGUE
    lw $ra, 16($sp)
    addi $sp, $sp, 20
    jr $ra
   
# abs(a,b) -> int
# Returns |a-b|
abs:
    # $a0 holds a and $a1 holds b
        sub $t8, $a0, $a1
        slt $t9, $t8,$zero
        bne $t9, $zero, neg
        j final

    neg:
         sub $t8, $zero, $t8
        
    # Once we have determined the value of |a-b|, the code will jump here (to finally "return").
    final:
         add $v0, $zero, $t8
   
    # jumping back to caller
    jr $ra
