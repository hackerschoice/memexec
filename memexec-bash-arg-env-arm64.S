// memexec-bash-arg-env-arm64.S
// ARM64 (AArch64) port of memexec-bash-arg-env.nasm
//
// Fileless execution with ARGV and ENV pass-through for AArch64 Linux.
// Creates a memfd, reads a binary from stdin into it, and executes it
// via execveat() with the caller's arguments and environment.
//
// Assemble and link:
//   as -o memexec-bash-arg-env-arm64.o memexec-bash-arg-env-arm64.S
//   ld -o memexec-bash-arg-env-arm64 memexec-bash-arg-env-arm64.o
//
// Usage:
//   cat /usr/bin/id | ./memexec-bash-arg-env-arm64
//   cat /bin/ls | TIME_STYLE=+%s ./memexec-bash-arg-env-arm64 -- -lah
//
// ARM64 Linux syscall ABI:
//   syscall number in x8
//   arguments in x0-x5
//   return value in x0
//   instruction: svc #0
//
// ARM64 Linux syscall numbers:
//   read         = 63
//   write        = 64
//   exit         = 93
//   memfd_create = 279
//   execveat     = 281
//
// Register allocation (callee-saved registers for persistent values):
//   x19 = stack scan pointer / scratch
//   x20 = last arg pointer (points to last argv entry before NULL separator)
//   x21 = envp (pointer to first environment variable on stack)
//   x22 = pointer to first user arg after "--" separator (new argv for execveat)
//   x23 = memfd file descriptor
//   x24 = argument counter

.text
.global _start

_start:

// ============================================================
// Phase 1: Find the auxiliary vector boundary on the stack.
//
// Walk upward from SP looking for the pattern:
//   [NULL] [AT_PHDR (0x21)]
// which marks the boundary between envp's trailing NULL and
// the start of the auxiliary vector.
// ============================================================

    mov     x19, sp                     // x19 = current scan pointer

find_ss_loop:
    ldr     x0, [x19]                   // load qword at [x19]
    cbnz    x0, cont_ss_loop            // if not NULL, keep scanning
    ldr     x1, [x19, #8]              // load next qword
    cmp     x1, #0x21                   // AT_PHDR marker?
    b.eq    found_ss
cont_ss_loop:
    add     x19, x19, #8               // advance by one pointer
    b       find_ss_loop

found_ss:
    sub     x19, x19, #8               // x19 = one slot before the NULL
                                        // (points into the last envp entry area)

// ============================================================
// Phase 2: Find envp.
//
// Walk backward (downward in memory) from the aux vector boundary
// to find the NULL separator between argv and envp.
// The NULL at [x19] separates argv (below) from envp (above).
// ============================================================

    mov     x0, x19                     // x0 = scan pointer
    mov     x20, xzr                    // x20 = will hold last arg pointer
    mov     x21, xzr                    // x21 = will hold envp

find_env_loop:
    ldr     x1, [x0]                    // load qword at [x0]
    cbnz    x1, cont_env_loop           // if not NULL, keep scanning

    // Found the NULL separator between argv and envp
    sub     x20, x0, #8                // x20 = pointer to last argument
    add     x21, x0, #8                // x21 = pointer to first env variable (envp)
    b       find_arg

cont_env_loop:
    sub     x0, x0, #8                 // walk backward
    b       find_env_loop

// ============================================================
// Phase 3: Find the "--" argument separator in argv.
//
// Walk backward through argv from the last argument.
// Count arguments and look for the "--" separator (0x2d2d as
// a 3-byte match: '-', '-', '\0').
// If found, set x22 to point to the first arg after "--" and
// write the new argc just before the "--" entry.
// If not found (reached argc at top of stack), fall through.
// ============================================================

find_arg:
    mov     x0, x20                     // x0 = pointer to last argument
    mov     x22, xzr                    // x22 = new argv (default: none)
    mov     x24, xzr                    // x24 = argument counter

find_arg_loop:
    ldr     x1, [x0]                    // x1 = argv[i] (pointer to string)

    // Check if we've reached the top of the arg list (argc value).
    // argc is a small integer, not a valid pointer. When we walk past
    // all argv entries we hit argc. Since x24 counts from 0 upward
    // and argc equals the total argument count, x1 == x24 means we've
    // gone past all arguments.
    cmp     x1, x24
    b.eq    run                         // reached argc, no "--" found

    // Dereference the string pointer and check for "--\0"
    ldr     w2, [x1]                    // load first 4 bytes of the string
    and     w2, w2, #0x00ffffff         // mask to 3 bytes: "--\0"
    mov     w3, #0x2d2d                 // "--" = 0x2d2d
    cmp     w2, w3
    b.ne    cont_arg_loop

    // Found "--" separator
    mov     x22, x0                     // x22 = pointer to "--" entry (new argv for execveat)
    str     x24, [x0, #-8]             // write new argc before "--" entry
    b       run

cont_arg_loop:
    sub     x0, x0, #8                 // walk backward through argv
    add     x24, x24, #1               // increment argument counter
    b       find_arg_loop

// ============================================================
// Phase 4: Create memfd, copy binary from stdin, execute it.
// ============================================================

run:
    // Allocate a 1024-byte buffer on the stack (+ alignment)
    mov     x9, sp
    sub     sp, sp, #1040               // 1024 buffer + 16 for name string

    // Push the name string "kernel\0" onto the stack
    // "kernel" = 0x6c656e72656b
    mov     x0, #0x656b                 // "ke"
    movk    x0, #0x6e72, lsl #16        // "rn" -> "kern"
    movk    x0, #0x6c65, lsl #32        // "el" -> "kernel"
    stp     x0, xzr, [sp, #-16]!       // push "kernel\0" + NULL padding

    // memfd_create("kernel", 0)
    mov     x8, #279                    // syscall: memfd_create
    mov     x0, sp                      // arg1: name = "kernel"
    mov     x1, #0                      // arg2: flags = 0
    svc     #0
    mov     x23, x0                     // x23 = memfd file descriptor

// Read loop: read from stdin, write to memfd
rw_loop:
    // read(0, buf, 1024)
    mov     x8, #63                     // syscall: read
    mov     x0, #0                      // arg1: fd = stdin
    add     x1, sp, #16                 // arg2: buf (past the name string)
    mov     x2, #1024                   // arg3: count
    svc     #0

    // Check for EOF or error
    cmp     x0, #0
    b.le    do_exec                     // if read <= 0, done reading

    // write(memfd, buf, bytes_read)
    mov     x2, x0                      // arg3: count = bytes read
    mov     x8, #64                     // syscall: write
    mov     x0, x23                     // arg1: fd = memfd
    add     x1, sp, #16                 // arg2: buf
    svc     #0

    b       rw_loop

// ============================================================
// Phase 5: execveat(memfd, "", argv, envp, AT_EMPTY_PATH)
// ============================================================

do_exec:
    // Prepare empty path string on stack
    strb    wzr, [sp]                   // write a '\0' byte at [sp]

    mov     x8, #281                    // syscall: execveat
    mov     x0, x23                     // arg1: dirfd = memfd
    mov     x1, sp                      // arg2: pathname = "" (empty string)
    mov     x2, x22                     // arg3: argv (parsed from stack)
    mov     x3, x21                     // arg4: envp
    mov     x4, #0x1000                 // arg5: flags = AT_EMPTY_PATH (4096)
    svc     #0

    // If execveat failed, exit with code 99
    mov     x8, #93                     // syscall: exit
    mov     x0, #99                     // exit code 99
    svc     #0
