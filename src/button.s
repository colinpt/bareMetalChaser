.text
    .global checkButtonStatus
    .global resetGPEDS
    .global delay

    .EQU BUTTON_NUM, 17
    .EQU GPEDS0, 0x3F200040
    .EQU GPEDS_MASK, 0x2331000
    .EQU CLOCK, 0x3F003004

/*----------------------------------------------------------------------------|
    checkButtonStatus
    *********************************************************
    =========================================================
    DESCRIPTION:
    Checks if the button at the defined GPIO number has been pressed
    since the last time the GPEDS0 for that pin has been reset.
    =========================================================
    ARGS: void
    =========================================================
    RETURN: R4 - boolean (pressed/not pressed)
    =========================================================
    REGISTERS USED: R0, R1, R2, R3, R4
    =========================================================
    EXAMPLES:
    If the button has been pressed, R4 will contain 1. 
    Otherwise, it will contain 0
|----------------------------------------------------------------------------*/

/*>>>>>>>>>>>>>>>>>>>SET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    GPEDS_Address       .req    R0
    buttonPin           .req    R1
    buttonIsPressed     .req    R2
    GPED_Bits           .req    R3
    result              .req    R4
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
checkButtonStatus: 
    stmfa   sp!, {R0-R3, R5-R10, lr}                @ Preserve regs
    mov     buttonPin, #1
    lsl     buttonPin, #BUTTON_NUM                  @ Shift to button position

    ldr     GPEDS_Address, =GPEDS0                  @ Get address of GPEDS0
    ldr     GPED_Bits, [GPEDS_Address]              @ Get contents of GPEDS0

    and     buttonIsPressed,  GPED_Bits, buttonPin  @ Grab relevant bit
    cmp     buttonIsPressed,  buttonPin             @ Check if it's set 

    moveq   result, #1                              @ If result was not zero, button was pressed.
    movne   result, #0                              @ Otherwise, it wasn't

    ldmfa   sp!, {R0-R3, R5-R10, lr}                @ Restore regs
    mov     pc, lr                                  @ Return

/*>>>>>>>>>>>>>>>>>>>UNSET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    .unreq   GPEDS_Address
    .unreq   buttonPin
    .unreq   buttonIsPressed
    .unreq   GPED_Bits
    .unreq   result
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/

/*----------------------------------------------------------------------------|
    resetGPEDS
    *********************************************************
    =========================================================
    DESCRIPTION:
    Resets all used bits in the GPEDS0 register to allow for new input.
    This is done by storing a 1 at the position of each used GPIO pin
    =========================================================
    ARGS: void
    =========================================================
    RETURN: void
    =========================================================
    REGISTERS USED: R0, R1
    =========================================================
|----------------------------------------------------------------------------*/

/*>>>>>>>>>>>>>>>>>>>SET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    GPEDS_Address       .req    R0
    GPEDS_Mask          .req    R1
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
resetGPEDS:
    stmfa   sp!, {R0-R10, lr}                @ Preserve regs

    ldr     GPEDS_Address, = GPEDS0          @ Load address of GPEDS0
    ldr     GPEDS_Mask, = GPEDS_MASK         @ Load mask
    str     GPEDS_Mask, [GPEDS_Address]      @ Reset GPEDS0 by storing the mask 

    ldmfa   sp!, {R0-R10, lr}                @ Restore regs
    mov     pc, lr                           @ Return
/*>>>>>>>>>>>>>>>>>>>UNSET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    .unreq   GPEDS_Address
    .unreq   GPEDS_Mask
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/

/*----------------------------------------------------------------------------|
    delay
    *********************************************************
    =========================================================
    DESCRIPTION:
    Utilizes a busy-loop to delay a provided number of microseconds.
    1,000,000 microseconds == 1 second
    =========================================================
    ARGS: R3 - Number of microseconds
    =========================================================
    RETURN: void
    =========================================================
    REGISTERS USED: R0, R1, R2, R3
    =========================================================
|----------------------------------------------------------------------------*/

/*>>>>>>>>>>>>>>>>>>>SET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    clockAddress .req     R0
    startTime    .req     R1 
    currTime     .req     R2 
    delay        .req     R3  
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
delay:
    stmfa   sp!, {R0-R10, lr}                @ Preserve regs

    ldr     clockAddress, =CLOCK             @ Load address of system clock
    ldr     startTime,  [clockAddress]       @ Store the current time before the loop
    add     delay, delay, startTime          @ Add the delay to the start time
    delayLoop:
        ldr     currTime, [clockAddress]     @ Get current time
        cmp     currTime, delay              @ Check against the combined time  
        blo     delayLoop                    @ Keep looping until the time has elapsed
    
    ldmfa   sp!, {R0-R10, lr}                @ Restore regs
    mov     pc, lr                           @ Return

/*>>>>>>>>>>>>>>>>>>>UNSET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    .unreq   clockAddress
    .unreq   startTime
    .unreq   delay
    .unreq   currTime  
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/

.section .data
