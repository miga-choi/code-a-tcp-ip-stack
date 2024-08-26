        ; In x86 assembly language, the CPU can operate in different modes: 
        ;   16-bit (real mode)
        ;   32-bit (protected mode)
        ;   64-bit (long mode).

        ; Tells  the assembler that the code that follows is intended to be excuted in 16-bit mode.
        ; This is common in bootloader or BIOS-level programming, where the CPU stars in real mode (16-bit).
        bits 16


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

        ;; We're now free to use the standard calling convention in order to safely 
        ;; pass control over to different functions. We can use "push" in order to 
        ;; push "call-saved" registers on the stack, pass parameters to callee again 
        ;; with "push", and then use "call" to save the current program counter to 
        ;; the stack, and perform an unconditional jump to the given label.

        ;; Now that all that is out of the way, let's figure out a way to clear the screen,
        ;; move the pointer, and write some text. This is where real mode and BIOS interrupt calls
        ;; come into play. By storing certain registers with certain parameters and then sending a
        ;; particular opcode to the BIOS as an interrupt, we can do a bunch of cool stuff.
        ;; For example, by storing 0x07 in the AH register and sending interrupt code 0x10 to the BIOS,
        ;; we can scroll the window down by a number of rows. Note the the registers AH and AL refer to
        ;; the most and least significant bytes of the 16 bit register AX. Thus, we could effectively
        ;; update both their values at once by simply pushing a 16 bit value to AX, however, we'll opt
        ;; for the clearer approach of updating each 1-byte subregister at a time.

        ;; If you look at the spec, you'll see that we need to set AH to 0x07, and AL to 0x00. 
        ;; The value of register BH refers to the BIOS color attribute, which for our purposes will be 
        ;; black background (0x0) behind light-gray (0x7) text, so we must set BH to 0x07. 
        ;; Registers CX and DX refer to the subsection of the screen that we want to clear. 
        ;; The standard number of character rows/cols here is 25/80, so we set CH and CL to 
        ;; 0x00 to set (0,0) as the top left of the screen to clear, and DH as 0x18 = 24, 
        ;; DL as 0x4f = 79. Putting this all together in a function, we get the following snippet. 

        ; Calls the "clearscreen" subroutine/function.
        ; The "call" instruction pushes the return address onto the stack and
        ; then jumps to the "clearscreen" label to execute the code at that location.
        call clearscreen

        ;; The overhead at the beginning and end of the subroutine allows us to adhere to the standard
        ;; calling convention between caller and callee. "pusha" and "popa" push and pop all general
        ;; registers on an off the stack. We save the caller's base pointer (4 bytes), and update the
        ;; base pointer with the new stack pointer. At the very end, we essentially mirror this process.

        ;; Now let's write a subroutine for moving the cursor to and arbitrary (row,col) position on the screen.
        ;; Int 10/AH=02h does this nicely. This subroutine will be slightly different, since we'll need to pass
        ;; it an argument. According to the spec, we must set register DX to a two byte value, the first
        ;; representing the desired row, and second the desired column, "AH" has gotta be 0x02, "BH" represents
        ;; the page number we want to move the cursor to. This parameter has to do with the fact that the BIOS
        ;; allows you to draw to off-screen pages, in order to facilitate smoother visual transitions by rendering
        ;; off-screen content before it is shown to the user. This is called "multiple" or "double buffering".
        ;; We don't really acre about this, however, so we'll just use the default page of 0.

        push 0000h
        call movecursor
        add sp, 2

        push msg

; This is the label for the "clearscreen" subroutine.
clearscreen:
        ; Saves the current value of the "bp" (base pointer) register onto the stack.
        push bp
        mov bp, sp

        ; Push all general-purpose registers ("ax","cx","dx","bx","sp","bp","si","di") onto the stack.
        pusha

        mov ah, 07h ; tells BIOS to scroll down window
        mov al, 00h ; clear entire window
        mov bh, 07h ; white on black
        mov cx, 00h ; specifies top left of screen as (0,0)
        mov dh, 18h ; 18h = 24 rows of chars
        mov dl, 4fh ; 4fh = 79 cols of chars

        ; This triggers a BIOS interrupt, specifically interrupt "10th", which handles video services.
        int 10h ; calls video interrupt

        ; Restores all the general-purpose register that where saved with.
        popa

        mov sp, bp

        ; Restore the "bp" register to its original value. This restores the caller's stack frame.
        pop bp

        ; Returns from the subroutine by popping the return address off the stack and jumping back to that address.
        ret

movecursor:
        push bp
        mov bp, sp
        pusha

        mov dx, [bp+4] ; get the argument from the stack. |bp| = 2, |arg| = 2
        mov ah, 02h    ; set cursor position
        mov bh, 00h    ; page 0 - doesn't matter, we're not using double-buffering

        popa
        mov sp, bp
        pop bp
        ret

;; The final subroutine we want to write is simple one that, given a pointer to the beginning of a string,
;; prints that string to the screen beginning at the current cursor position. Using the video interrupt
;; code with "AH=0Eh" works nicely. First off, we can define some data and store a pointer to its starting
;; address with something that looks like this.
;;
;; The "0" at the end terminates the string with a null character, so we'll know when the string is done.
;; We can reference the address of this string with "msg".
msg:    db "Oh boy do I sure love assembly!", 0