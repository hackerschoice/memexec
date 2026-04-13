#! /bin/bash

# ARM64 (AArch64) version of memexec-bash.sh
#
# Fileless execution with ARGV and ENV pass-through for AArch64 Linux.
# Injects ARM64 shellcode into the running bash process via /proc/$$/mem,
# which creates a memfd, reads a binary from stdin, and executes it
# via execveat() with the caller's arguments and environment.
#
# Shellcode generated from memexec-bash-arg-env-arm64.S:
#   as -o memexec-bash-arg-env-arm64.o memexec-bash-arg-env-arm64.S
#   ld -o memexec-bash-arg-env-arm64 memexec-bash-arg-env-arm64.o
#   objcopy -O binary -j .text memexec-bash-arg-env-arm64 memexec-bash-arg-env-arm64.bin
#   base64 -w 0 < memexec-bash-arg-env-arm64.bin

memexec() { bash -c 'cd /proc/$$;exec 4>mem;base64 -d<<<8wMAkWACQPmAAAC1YQZA+T+EAPFgAABUcyIAkfr//xdzIgDR4AMTqvQDH6r1Ax+qAQBA+YEAALUUIADRFSAAkQMAABQAIADR+v//F+ADFKr2Ax+q+AMfqgEAQPk/ABjrgAEAVCIAQLlCXAASo6WFUl8AA2uBAABU9gMAqhiAH/gEAAAUACAA0RgHAJHz//8X6QMAkf9DENFgrYzSQM6t8qCMzfLgf7+p6CKA0uADAJEBAIDSAQAA1PcDAKroB4DSAACA0uFDAJECgIDSAQAA1B8AAPHtAABU4gMAqggIgNLgAxeq4UMAkQEAANT0//8X/wMAOSgjgNLgAxeq4QMAkeIDFqrjAxWqBACC0gEAANSoC4DSYAyA0gEAANQ=|dd bs=1 seek=$[$(cat syscall|cut -f9 -d" ")]>&4 2>/dev/null' "$@"; }

# Example:
#  source memexec-bash-arm64.sh
#  cat /usr/bin/id | memexec
#  cat /bin/ls | TIME_STYLE=+%s memexec -- -lah
