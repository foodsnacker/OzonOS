nasm bootloader.asm -f bin -o bootloader.bin
nasm kernal.asm -f bin -o kernal.bin
cat bootloader.bin kernal.bin > ozonos.bin
qemu-system-x86_64 ozonos.bin