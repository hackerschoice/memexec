section .text
    global _start                       ; Entry point for the program

_start:

; find the start of stack
    mov rax, rsp
    xor r10, r10                        ; stack start addr
find_ss_loop:
    cmp  QWORD [rax], 0x0000000000000000
    jne  cont_ss_loop
    cmp  QWORD [rax+8], 0x0000000000000021
    jne  cont_ss_loop
    sub  rax, 8                         ; start pos of stack
    mov  r10, rax
    jmp  find_env
cont_ss_loop:
    add  rax, 8
    jmp  find_ss_loop

; find argp and envp
find_env:
    mov  rax, r10
    xor  r11, r11                       ; last arg
    xor  r12, r12                       ; envp
find_env_loop:
    cmp  QWORD [rax], 0x0000000000000000
    jne  cont_env_loop    
    ; ================
    mov  r11, rax                       ; store the envp separator
    sub  r11, 8                         ; point to the last argument
    ; ================
    add  rax, 8                         ; point to the first env variable
    mov  r12, rax
    jmp  find_arg
cont_env_loop:
    sub  rax, 8
    jmp  find_env_loop


; find argp
find_arg:
    mov  rax, r11                       ; pointer to the last argument
    xor  r13, r13                       ; pointer to the bash arg separator
    xor  rdi, rdi                       ; track how many arguments we have seen so far
find_arg_loop:
    mov  rbx, QWORD [rax]
    ;===========================
    cmp  rbx, rdi                       ; quit if we have reached the top of arg list
    je   run
    ;===========================
    mov  rcx, QWORD [rbx]

    and  rcx, 0x0000000000ffffff        ; we are only interested in last 3 bytes i.e --\0
    cmp  rcx, 0x0000000000002d2d        ; find arg separator (--)
    jne  cont_arg_loop
    ; ==========================    
    mov  r14, rax                       ; point to first arg after the bash arg separator (--)
    mov  QWORD [rax-8], rdi             ; create the new argc
    ; ==========================
    jmp run

cont_arg_loop:
    sub  rax, 8
    inc  rdi
    jmp  find_arg_loop


run:
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
    mov rdi, r8            ; mem_fd number
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
    mov     rdx, r14    ; ARGV
    xor     rcx, rcx    ; arg 4: ENV ?
    xor     r9, r9      ; arg 4: ENV ?
    mov     r10, r12    ; arg 4: ENV
    mov     r8, 4096    ; AT_EMPTY_PATH
    syscall    


    ; Exit the program
    mov rax, 60                       ; syscall number for sys_exit
    mov rdi, 99                       ; exit code 99
    syscall                           
