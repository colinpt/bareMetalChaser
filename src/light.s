.text
    .global showScore
    .global showLives
    .global turnOn
    .global turnOff
    .global turnAllOff

    .EQU SET,   0x3F20001C
    .EQU CLEAR, 0x3F200028
/*----------------------------------------------------------------------------|
    turnOn
    *********************************************************
    =========================================================
    DESCRIPTION:
    Sets a GPSET0 bit to turn on an LED
    =========================================================
    ARGS: 
         R0: GPIO pin of desired LED
    =========================================================
    RETURN: void
    =========================================================
    REGISTERS USED: R0, R1, R2
    =========================================================
    EXAMPLES:
    ARG: 21 ==> GPIO 21 will be set to high.
|----------------------------------------------------------------------------*/

/*>>>>>>>>>>>>>>>>>>>SET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    GPIO_NUM     .req     R0
    setAddress   .req     R1    
    position     .req     R2
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/

turnOn:
    stmfa   sp!, {R0-R10}                  @ Preserve regs

    ldr     setAddress, =SET               @ Load address

    mov     position, #1
    lsl     position, position, GPIO_NUM   @ Go to position by shifting by the argument

    str     position, [setAddress]         @ Set the bit in GPSET0

    ldmfa   sp!, {R0-R10}                  @ Restore regs
    mov     pc, lr                         @ Return

/*>>>>>>>>>>>>>>>>>>>UNSET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    .unreq   GPIO_NUM
    .unreq   setAddress
    .unreq   position  
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/

/*----------------------------------------------------------------------------|
    turnOff
    *********************************************************
    =========================================================
    DESCRIPTION:
    Sets a GPCLR0 bit to turn off an LED
    =========================================================
    ARGS: 
         R0: GPIO pin of desired LED
    =========================================================
    RETURN: void
    =========================================================
    REGISTERS USED: R0, R1, R2
    =========================================================
    EXAMPLES:
    ARG: 21 ==> GPIO 21 will be set to low.
|----------------------------------------------------------------------------*/

/*>>>>>>>>>>>>>>>>>>>SET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    GPIO_NUM     .req     R0
    clearAddress .req     R1 
    position     .req     R2
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/

turnOff:
    stmfa   sp!, {R0-R10}                   @ Preserve regs

    ldr     clearAddress, =CLEAR            @ Load address

    mov     position, #1
    lsl     position, position, GPIO_NUM    @ Go to position by shifting by the argument

    str     position, [clearAddress]        @ Set the bit in GPCLR0

    ldmfa   sp!, {R0-R10}                   @ Restore regs
    mov     pc, lr                          @ Return

/*>>>>>>>>>>>>>>>>>>>UNSET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    .unreq   GPIO_NUM
    .unreq   clearAddress
    .unreq   position  
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/

/*----------------------------------------------------------------------------|
    turnAllOff
    *********************************************************
    =========================================================
    DESCRIPTION:
    Sets all GPCLR0 bits to turn off all LEDs
    =========================================================
    ARGS: void
    =========================================================
    RETURN: void
    =========================================================
    REGISTERS USED: R0, R1
    =========================================================
    EXAMPLES: All GPIO output pins will be set to low.
|----------------------------------------------------------------------------*/

/*>>>>>>>>>>>>>>>>>>>SET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    allMask      .req     R0
    clearAddress .req     R1   
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/

turnAllOff:
    stmfa   sp!, {R0-R10}                  @ Preserve regs

    ldr     clearAddress, =CLEAR           @ Load address

    ldr     allMask, =0x3FFFFFFF           @ All ones, except for reserved bits in GPCLR0

    str     allMask, [clearAddress]        @ Set all valid bits in GPCLR0

    ldmfa   sp!, {R0-R10}                  @ Restore regs
    mov     pc, lr                         @ Return

/*>>>>>>>>>>>>>>>>>>>UNSET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    .unreq   clearAddress
    .unreq   allMask
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/

/*----------------------------------------------------------------------------|
    showLives
    *********************************************************
    =========================================================
    DESCRIPTION:
    Displays remaining lives in binary on the 3 blue LEDs
    =========================================================
    ARGS: x - STACK OFFSET
          0: Number of lives
    =========================================================
    RETURN: void
    =========================================================
    REGISTERS USED: R0, R1, R2, R3, R4
    =========================================================
    EXAMPLES: 
    ARG: (4) Will be displayed as 100 on the blue LEDs
|----------------------------------------------------------------------------*/

/*>>>>>>>>>>>>>>>>>>>SET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    currentLight .req     R0
    LEDS         .req     R1
    index        .req     R2
    life         .req     R3
    isOn         .req     R4
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
    .EQU    LIFE_LEN, 12
showLives:
    mov     fp, sp                          @ Store sp for arg
    stmfa   sp!, {R0-R10, lr}               @ Preserve regs

    ldr     LEDS, =LIFE_LEDS                @ Address for current lights
    ldr     life, [fp]                      @ Get value of current lives from arg
    mov     index, #0                       @ Index into light array
    lifeLoop:
        ldr     currentLight, [LEDS, index] @ Fetch current light GPIO number
        and     isOn, life, #1              @ Isolate LSB
        cmp     isOn, #1                    @ Check if LSB is on
        bleq    turnOn                      @ If it is, turn on the current light
        lsr     life, #1                    @ Shift to the next bit
        # Loop controls
        add     index, #4                   @ Increment address
        cmp     index, #LIFE_LEN            @ Check index bounds
        blt     lifeLoop                    @ Loop if within bounds

    ldmfa   sp!, {R0-R10, lr}               @ Restore regs
    mov pc, lr                              @ Return
  
/*>>>>>>>>>>>>>>>>>>>UNSET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    .unreq   currentLight
    .unreq   LEDS
    .unreq   index
    .unreq   life
    .unreq   isOn
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/

/*----------------------------------------------------------------------------|
    showScore
    *********************************************************
    =========================================================
    DESCRIPTION:
    Displays total score on main LEDs.
    To be called once lives run out.
    =========================================================
    ARGS: x - STACK OFFSET
          0: score
    =========================================================
    RETURN: void
    =========================================================
    REGISTERS USED: R0, R1, R2, R3
    =========================================================
    EXAMPLES: 
    ARG: (11) Will be displayed as 01011 on the main LEDs
|----------------------------------------------------------------------------*/

/*>>>>>>>>>>>>>>>>>>>SET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    currentLight .req     R0
    LEDS         .req     R1
    index        .req     R2
    score        .req     R3
    isOn         .req     R4
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/
    .EQU    SCORE_LEN, 20
showScore:

    bl      turnAllOff                      @ Ensure no lights are already on
    
    ldr     LEDS, = SCORE_LEDS              @ Address for current lights
    ldmfa   sp!, {score}                    @ Get value of current score from arg
    mov     index, #0                       @ Index into light array
    scoreLoop:
        ldr     currentLight, [LEDS, index] @ Fetch current light GPIO number
        and     isOn, score, #1             @ Isolate LSB
        cmp     isOn, #1                    @ Check if LSB is on
        bleq    turnOn                      @ If it is, turn on the current light
        lsr     score, #1                   @ Shift to the next bit
        # Loop controls
        add     index, #4                   @ Increment address
        cmp     index, #SCORE_LEN           @ Check index bounds
        blt     scoreLoop                   @ Loop if within bounds

    b       reset                           @ Branch to end of game procedure

/*>>>>>>>>>>>>>>>>>>>UNSET REGISTER ALIASES<<<<<<<<<<<<<<<<<<<<<<<<<*/
    .unreq   currentLight
    .unreq   LEDS
    .unreq   index
    .unreq   score
    .unreq   isOn
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*/


.section .data
LIFE_LEDS:     .int  24, 23, 22
SCORE_LEDS:    .int  25, 12, 16, 20, 21
