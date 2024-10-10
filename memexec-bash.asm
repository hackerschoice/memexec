section .text
    global _start                    ; Entry point for the program

_start:
    ; create a buffer
    mov rbp, rsp
    sub rsp, 1042                         

    mov  rax, 0x6c656e72656b    ; kernel
    push 0                                    
    push rax

    mov rax, 319           ; memfd_create
    mov rdi, rsp           ; name - kernel
    xor rsi, rsi           ; no MFD_CLOEXEC
    syscall
    mov r8, rax            ; save memfd number


rw_loop:
    mov rax, 0             ; read
    mov rdi, 0             ; stdin
    mov rsi, rsp           ; pointer to buffer
    mov rdx, 1024          ; number of bytes to read at time
    syscall
    mov rdx, rax           ; store no of bytes read in rdx

    ; check if we reached the end of the file
    cmp rdx, 0
    jle exit               ; if bytes read is 0, close the file

    ; write data to mem_fd
    mov rax, 1
    mov rdi, 3            ; mem_fd number
    mov rsi, rsp          ; buffer
    ;rdx already has the amount of bytes previously read
    syscall

    jmp rw_loop


exit:
    ; execveat the program in memfd

    mov     rax, 322    ; execveat
    mov     rdi, r8     ; memfd
    push    0
    mov     rsi, rsp    ; path (empty string)
    push    0
    push    rsp
    mov     rdx, rsp    ; ARGV (pointer to a array containing a pointer to a empty string)
    mov     r8, 4096    ; AT_EMPTY_PATH
    syscall


    ; Exit the program
    mov rax, 60                       ; syscall number for sys_exit
    mov rdi, 99                       ; exit code 99
    syscall
