; This code was used to generate the ShellCode. You wont
; need it again. Published for educational purpose only.
; https://www.thc.org
;
; nasm -felf64 memexec.nasm && ld memexec.o &&  ./a.out

global _start
section .text

_start:
    push    0x00676765  ; "egg"
    mov     rax, 0x13f
    mov     rdi, rsp    ; arg 1: name [egg]
    xor     rsi, rsi    ; arg 2: 0 = no MFD_CLOEXEC
    syscall
    mov     r8, rax

    mov     rax, 2
    mov     rdi, rsp    ; arg 1: name [egg]
    xor     rsi, rsi    ; arg 2: 0 = O_RDONLY
    syscall
    mov     r9, rax

loop:
    sub     rsp, 0x400
    xor     rax, rax    ; arg 0: read_NR
    mov     rdi, r9     ; arg 1: FD [egg]
    mov     rsi, rsp    ; arg 2: buffer
    mov     edx, 0x400  ; arg 3: length
    syscall

    cmp     rax, 0x00
    jle     done        ; EOF

    mov     rdx, rax    ; arg 3: length (from read()) 
    mov     eax, 0x01   ; arg 0: write_NR
    mov     rdi, r8     ; arg 1: FD [memfd]
    syscall
    jmp     loop
done:

    mov     rax, 322    ; arg 0: execveat_NR
    mov     rdi, r8     ; arg 1: memfd
    push    0x00
    mov     rsi, rsp    ; arg 2: path (empty string)
    xor     rdx, rdx    ; arg 3: ARGV [NULL]
    xor     rcx, rcx    ; arg 4: ENV ?
    xor     r9, r9      ; arg 4: ENV ?
    xor     r10, r10    ; arg 4: ENV
    mov     r8, 0x1000  ; arg 5: AT_EMPTY_PATH
    syscall
    
    mov     rax, 60
    xor     rdi, rdi
    syscall
