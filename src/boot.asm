        ; In x86 assembly language, the CPU can operate in different modes: 
        ;   16-bit (real mode)
        ;   32-bit (protected mode)
        ;   64-bit (long mode).
        bits 16 ; specifies that the instructions and registers used are intended for 16-bit mode


        ;; The processor has a DS register for the data segment. 
        ;; Since our code resides at 0x7C00, the data segment may 
        ;; begin at 0x7C0, which we can set with

        ; ax:
        ;   This is the 16-bit "accumulator" register, one of the 
        ;   general-purpose registers in x86 assembly language.
        mov ax, 07C0h ; move the value "07C0h" into the "ax" register
        ; ds: 
        ;   This is the "data segment" register, which is used to hold
        ;   the segment address of the data segment. The data segment
        ;   is where the CPU expects to find the program's data.
        mov ds, ax ; moves the value from the "ax" register into the "ds" register.


        ;; We have to load the segment into another register (here it's ax) first;
        ;; We can't directly stick it in the segment register. 
        ;; Let's start the storage for the stack directly after the 512 bytes of the bootloader. 
        ;; Since the bootloader extends from 0x7C00 for 512 bytes to 0x7E00, 
        ;; the stack segment, SS, will be 0x7E0.

        ; 07E0h = (07C00h+200h)/10h, beginning of stack segment.
        mov ax, 07E0h; move the value "07E0h" into the "ax" register 

        ; ss:
        ;   This is the "stack segment" register, which is used to hold
        ;   the segment address of the stack. The stack is a special area
        ;   of memory used for storing return addresses, local variables,
        ;   and other data during program execution.
        mov ss, ax ; moves the value from the "ax" register into the "ss" register.


        ;; On x86 architectures, the stack pointer decreases, so we 
        ;; must set the initial stack pointer to a number of bytes past 
        ;; the stack segment equal to the desired size of the stack.

        ; sp:
        ;   This is the 16-bit "stack pointer" register. 
        ;   The "sp" register is used to keep track of the top of the stack in memory.
        ;   The stack is a special area of memory used for storing temporary data like 
        ;   return addresses, local variables, and other function-related information.
        mov sp, 2000h ; 8k of stack space.