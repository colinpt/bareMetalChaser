bin  = kernel.img
elf  = kernel.elf

src = game.s
src2 = light.s
src3 = button.s

obj  = kernel.o
obj2 = light.o
obj3 = button.o

$(bin) : $(elf)
	arm-none-eabi-objcopy $(elf) -O binary $(bin)

# kernel.ld directs the pi to the start of the assembly code.
$(elf) : $(obj) $(obj2) $(obj3)
	arm-none-eabi-ld $(obj) $(obj2) $(obj3) -o $(elf)  -T kernel.ld

$(obj) : $(src)
	arm-none-eabi-as -g -o $(obj) $(src)

$(obj2) : $(src2)
	arm-none-eabi-as -g -o $(obj2) $(src2)

$(obj3) : $(src3)
	arm-none-eabi-as -g -o $(obj3) $(src3)

clean:
	rm *.o *.elf

