section .text
    global _start                       ; Entry point for the program

_start:

; find the start of stack
    mov eax, esp
    xor ebx, ebx                        ; stack start addr
find_ss_loop:
    cmp DWORD [eax], 0x00000000
    jne cont_ss_loop
    cmp DWORD [eax+4], 0x00000021
    jne cont_ss_loop
    sub eax, 4                         ; start pos of stack
    mov ebx, eax
    jmp find_env
cont_ss_loop:
    add eax, 4
    jmp find_ss_loop

; find argp and envp
find_env:
    mov eax, ebx
    xor ecx, ecx                       ; last arg
    xor edx, edx                       ; envp
find_env_loop:
    cmp DWORD [eax], 0x00000000
    jne cont_env_loop    
    ; ================
    mov ecx, eax                       ; store the envp separator
    sub ecx, 4                         ; point to the last argument
    ; ================
    add eax, 4                         ; point to the first env variable
    mov edx, eax
    jmp find_arg
cont_env_loop:
    sub eax, 4
    jmp find_env_loop

; find argp
find_arg:
    mov eax, ecx                       ; pointer to the last argument
    xor ebx, ebx                       ; pointer to the bash arg separator
    xor edi, edi                       ; track how many arguments we have seen so far
find_arg_loop:
    mov ebx, DWORD [eax]
    ;===========================
    cmp ebx, edi                       ; quit if we have reached the top of arg list
    je run
    ;===========================
    mov ecx, DWORD [ebx]

    and ecx, 0x00ffffff                ; we are only interested in last 3 bytes i.e --\0
    cmp ecx, 0x00002d2d                ; find arg separator (--)
    jne cont_arg_loop
    ; ==========================    
    mov esi, eax                       ; point to first arg after the bash arg separator (--)
    mov DWORD [eax-4], edi             ; create the new argc
    ; ==========================
    jmp run

cont_arg_loop:
    sub eax, 4
    inc edi
    jmp find_arg_loop

run:
    ; create a buffer
    mov ebp, esp
    sub esp, 1042                         

    mov eax, 0x6c656e72                ; kernel
    push 0                                    
    push eax

    mov eax, 356                       ; memfd_create syscall number (x86)
    mov ebx, esp                       ; arg 1: name [kernel]
    xor ecx, ecx                       ; arg 2: 0 = no MFD_CLOEXEC
    int 0x80
    mov ebx, eax                       ; save memfd number           

rw_loop:
    mov eax, 3                         ; read syscall number (x86)
    mov ebx, 0                         ; stdin
    mov ecx, esp                       ; pointer to buffer
    mov edx, 1024                      ; number of bytes to read at time
    int 0x80              
    mov edx, eax                       ; store no of bytes read in edx

    ; check if we reached the end of the file
    cmp edx, 0
    jle exit                           ; if bytes read is 0, close the file

    ; write data to mem_fd
    mov eax, 4                         ; write syscall number (x86)
    mov ebx, ebx                       ; mem_fd number
    mov ecx, esp                       ; buffer
    int 0x80               

    jmp rw_loop

exit:
    ; execveat the program in memfd
    mov eax, 357                       ; execveat syscall number (x86)
    mov ebx, ebx                       ; arg 1: memfd
    push 0
    mov ecx, esp                       ; arg 2: path (empty string)
    mov edx, esi                       ; arg 3: ARGV
    xor esi, esi                       ; arg 4: ENV ?
    mov edi, 0x1000                    ; arg 5: AT_EMPTY_PATH
    int 0x80    

    ; Exit the program
    mov eax, 1                         ; exit syscall number (x86)
    xor ebx, ebx                       ; exit status 0
    int 0x80                           
