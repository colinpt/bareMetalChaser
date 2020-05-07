.text
    .global _start
    .global reset
/*----------------------------------------------------------------------------|
    GPIO Layout
    =================================================================== 
    Button - 17
    1-R - 21
    2-Y - 20
    3-G - 16
    4-Y - 12
    5-R - 25

    1-B - 22
    2-B - 23
    3-B - 24

    GPFSEL1 (Output 001) = [18-20, 6-8]
    GPFSEL2 (Output 001) = [0-2, 3-5, 15-17]
    GPFSEL2 (Input 000)  = [6-8]
    ===================================================================
|----------------------------------------------------------------------------*/

@ Misc
    /*----------------------------------------------------------------------------*/
    .EQU LED1, 21
    .EQU LED2, 20 
    .EQU LED3, 16 
    .EQU LED4, 12 
    .EQU LED5, 25

    .EQU GPFSEL1, 4
    .EQU GPFSEL2, 8 

    .EQU DELAY_LONG, 1000000
    /*----------------------------------------------------------------------------*/

@ Addresses
    /*----------------------------------------------------------------------------*/
    .EQU BASE,  0x3F200000
    .EQU GPREN0, 0x3F20004C
     /*----------------------------------------------------------------------------*/

@ Masks
    /*----------------------------------------------------------------------------*/
    .EQU GPF1_OUT_MASK, 0x40040
    .EQU GPF2_OUT_MASK, 0x9249
    .EQU GPREN_MASK, 0x2331000
     /*----------------------------------------------------------------------------*/
_start:

/*----------------------------------------------------------------------------|
    config
    *********************************************************
    =========================================================
    DESCRIPTION:
    Runs once at startup. Configures GPFSEL0, GPFSEL2, and GPREN0
    in order to let the needed GPIO pins take output.
    Additionally initalizes the local stack, and shows the starting life total.
    =========================================================
    ARGS: void
    =========================================================
    RETURN: void
    =========================================================
    REGISTERS USED: R0, R1, R2, R3, R4
    =========================================================
|----------------------------------------------------------------------------*/
/*>>>>>>>>>>>>>>>>>>>SET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    baseAddress     .req     R0 
    setMask         .req     R1
    GPREN0_Mask     .req     R2   
    GPREN0_Address  .req     R3
    startingLives   .req     R4
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/

config:
    ldr     sp, =STACK                        @ Initialize local stack

    ldr     baseAddress, =BASE                @ Load base address

    ldr     setMask, =GPF1_OUT_MASK           @ Load mask that sets GPIO 12 & 16 to output
    str     setMask, [baseAddress, #GPFSEL1]  @ Store it in GPFSEL1

    ldr     setMask, =GPF2_OUT_MASK           @ Load mask that sets GPIO 20 - 25 to output
    str     setMask, [baseAddress, #GPFSEL2]  @ Store it in GPFSEL2

    ldr     GPREN0_Address, =GPREN0           @ Address of GPREN0
    ldr     GPREN0_Mask, =GPREN_MASK          @ Load mask that sets up the event listener  
    str     GPREN0_Mask, [GPREN0_Address]     @ Store it in GPREN0

    ldr     startingLives, =LIVES             @ Load address of lives
    ldr     startingLives, [startingLives]    @ Get value of starting lives
    stmfa   sp!, {startingLives}              @ Push value onto the stack
    bl      showLives                         @ Display current life
    
/*>>>>>>>>>>>>>>>>>>>UNSET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    .unreq   baseAddress
    .unreq   setMask  
    .unreq   GPREN0_Mask
    .unreq   GPREN0_Address
    .unreq   startingLives
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/

/*----------------------------------------------------------------------------|
    main
    *********************************************************
    =========================================================
    DESCRIPTION:
    Handles the main logic of the game. Handles the movement the lights,
    and checks for button presses. 
    =========================================================
    ARGS: void
    =========================================================
    RETURN: void
    =========================================================
    REGISTERS USED: R0, R1, R2, R3, R4
    =========================================================
|----------------------------------------------------------------------------*/

/*>>>>>>>>>>>>>>>>>>>SET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    currentLight  .req     R0
    LEDS          .req     R1 
    index         .req     R2
    delayTime     .req     R3
    buttonBoolean .req     R4 
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
    .EQU    ARRAY_LEN, 28         @ 7 * 4
main:
    ldr     delayTime, = CURRENT_DELAY      @ Gets address of current delay
    ldr     delayTime, [delayTime]          @ Gets the value of the current amount of time to delay

    ldr     LEDS, = LED_ARRAY               @ Address for current lights
    mov     index, #0                       @ Index into light array
    lightLoop:
        ldr     currentLight, [LEDS, index] @ Fetch current light GPIO number
        bl      turnOn

        bl      checkButtonStatus           @ Check button status
        cmp     buttonBoolean, #1           @ See if it's been pressed
        bleq    buttonPressed               @ If it has, branch to appropriate response.

        bl      delay                       @ Wait to turn off this light / turn on the next one
        bl      turnOff                     @ Turn off current light
        # Loop controls
        add     index, #4                   @ Increment address
        cmp     index, #ARRAY_LEN           @ Check index bounds
        movgt   index, #0                   @ Reset index if needed
        b lightLoop                         @ Always loop
  
/*>>>>>>>>>>>>>>>>>>>UNSET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    .unreq   currentLight
    .unreq   LEDS
    .unreq   index
    .unreq   delayTime
    .unreq   buttonBoolean
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/

/*----------------------------------------------------------------------------|
    buttonPressed
    *********************************************************
    =========================================================
    DESCRIPTION:
    Handles the logic of what should happen when the button has been pressed. 
    =========================================================
    ARGS: void
    =========================================================
    RETURN: void
    =========================================================
    REGISTERS USED: R0, R1, R2, R3, R4
    =========================================================
|----------------------------------------------------------------------------*/

/*>>>>>>>>>>>>>>>>>>>SET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    currentLight    .req    R0
    livesAddress    .req    R1
    lives           .req    R2
    pressDelay      .req    R3
    score           .req    R4
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
buttonPressed:
       ldr  pressDelay, = #DELAY_LONG   @ Delay for 1 second to show which light has been hit
       bl delay

       ldr      livesAddress, = LIVES   @ Load address of lives
       ldr      lives, [livesAddress]   @ Load value of the current number of lives

       cmp      currentLight, #LED3     @ Check if the current light is the middle light.
       bleq     levelUp                 @ If it is, pass off logic to the levelUp method
       beq      afterChecks             @ Also skip other checks if true

       cmp      currentLight, #LED2     @ If either of the lights adjacent to the middle were hit
       subeq    lives, #1               @ Lose 1 life
       cmp      currentLight, #LED4
       subeq    lives, #1 

       cmp      currentLight, #LED1     @ If either of the lights on the end were hit
       subeq    lives, #2               @ Lose 2 lives
       cmp      currentLight, #LED5
       subeq    lives, #2 
    
       str      lives, [livesAddress]   @ Store new life total

       cmp      lives, #0
                                        @ Perform these, only if lives are <= 0
       ldrle    score, =SCORE           @ Load address of score
       ldrle    score, [score]          @ Load value of score
       stmlefa  sp!, {score}            @ Push it onto the stack
       ble      showScore               @ Display the score

       afterChecks:
            bl      turnAllOff          @ Turn all lights of to prepare for next run
            stmfa   sp!, {lives}        @ Push life total onto stack
            bl      showLives           @ Update life total
            bl      resetGPEDS          @ Allow for the next button press
            b       main                @ Start next run

/*>>>>>>>>>>>>>>>>>>>UNSET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    .unreq   currentLight
    .unreq   livesAddress
    .unreq   lives
    .unreq   pressDelay
    .unreq   score
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/

/*----------------------------------------------------------------------------|
    levelUp
    *********************************************************
    =========================================================
    DESCRIPTION:
    Handles the logic of what should happen when the player has hit the middle LED
    =========================================================
    ARGS: void
    =========================================================
    RETURN: void
    =========================================================
    REGISTERS USED: R0, R1, R2, R3, R4
    =========================================================
|----------------------------------------------------------------------------*/

/*>>>>>>>>>>>>>>>>>>>SET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    delayAddress .req    R0
    curDelay     .req    R1
    newDelay     .req    R2
    scoreAddress .req    R3
    newScore     .req    R4
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
levelUp:
    stmfa   sp!, {R0-R10, lr}                @ Preserve regs

    ldr     delayAddress, =CURRENT_DELAY     @ Load address of current delay
    ldr     curDelay, [delayAddress]         @ Load value of current delay

    add     curDelay, curDelay, lsl #3       @ Multiply current delay by 9

    /* do some wacky math to reduce the total delay by roughly 10% each time */
    lsr     newDelay, curDelay, #3           @ Initialize new delay
    lsr     curDelay, #7                     @ Shift current delay 7 places right
    add     curDelay, curDelay, lsl #1       @ Multiple the shifted value by 3
    sub     newDelay, newDelay, curDelay     @ Subtract that value from the new delay

    str     newDelay, [delayAddress]         @ Store the new delay as the current delay

    ldr     scoreAddress, =SCORE             @ Get the address of the current score
    ldr     newScore, [scoreAddress]         @ Get the value of the current score
    
    add     newScore, newScore, #1           @ Add one to it
    str     newScore, [scoreAddress]         @ Put it back

    ldmfa   sp!, {R0-R10, lr}                @ Restore regs
    mov     pc, lr                           @ Return
/*>>>>>>>>>>>>>>>>>>>UNSET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    .unreq   delayAddress
    .unreq   curDelay
    .unreq   newDelay
    .unreq   scoreAddress
    .unreq   newScore
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/

/*----------------------------------------------------------------------------|
    reset
    *********************************************************
    =========================================================
    DESCRIPTION:
    Handles the logic of what should happen when the player has lost
    =========================================================
    ARGS: void
    =========================================================
    RETURN: void
    =========================================================
    REGISTERS USED: R0, R1, R2, R3, R4, R5, R6
    =========================================================
|----------------------------------------------------------------------------*/

/*>>>>>>>>>>>>>>>>>>>SET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    score         .req     R0
    scoreAddress  .req     R1
    livesAddress  .req     R2
    resetDelay    .req     R3
    buttonBoolean .req     R4
    lives         .req     R5
    delayAddress  .req     R6
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
reset:
    ldr     delayAddress, =CURRENT_DELAY    
    ldr     resetDelay, [delayAddress]      
    bl      delay                           @ Delay to prevent switch debouncing
    bl      resetGPEDS                      @ Allow for a new button press
    waitForButtonPress:
        bl      checkButtonStatus           @ Check to see if button has been pressed
        cmp     buttonBoolean, #1
        beq     startReset                  @ If it has, begin a new game
        bne     waitForButtonPress          @ Otherwise, keep waiting
startReset:        
    bl      turnAllOff                      @ Reset all the lights
    
    ldr     scoreAddress, = SCORE           @ Reset score to 0
    mov     score, #0
    str     score, [scoreAddress]

    ldr     livesAddress, = LIVES           @ Reset lives to 5
    mov     lives, #5
    str     lives, [livesAddress]

    ldr     resetDelay, =100000             @ Reset delay to 0.1 seconds
    str     resetDelay, [delayAddress]

    bl      delay                           @ Delay to prevent switch debouncing once again
    bl      resetGPEDS                      @ Allow for the next button press

    b       _start                          @ Restart the game

/*>>>>>>>>>>>>>>>>>>>UNSET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    .unreq   score
    .unreq   scoreAddress
    .unreq   livesAddress
    .unreq   resetDelay
    .unreq   buttonBoolean
    .unreq   lives
    .unreq   delayAddress
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/

.section .data

@ Game data
    /*----------------------------------------------------------------------------*/
    CURRENT_DELAY:  .int  100000
    LIVES:          .int  5
    SCORE:          .int  0
    LED_ARRAY:      .int  21, 20, 16, 12, 25, 12, 16, 20
    /*----------------------------------------------------------------------------*/

@ Utility
    /*----------------------------------------------------------------------------*/
    STACK:          .skip 100*4
    /*----------------------------------------------------------------------------*/
