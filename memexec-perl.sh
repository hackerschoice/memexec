#! /bin/bash

#  319 - x86_64
#  279 - aarch64
#  385 - armv6l
# 4314 - mipsel n64
# 4354 - mipsel o32
memexec(){ perl '-e$^F=255;for(319,279,385,4314,4354){($f=syscall$_,$",0)>0&&last};open($o,">&=".$f);print$o(<STDIN>);exec{"/proc/$$/fd/$f"}X,@ARGV' -- "$@";}
# memexec(){ perl '-efor(319,279){($f=syscall$_,$",1)>0&&last};open($o,">&=".$f);print$o(<STDIN>);exec{"/proc/$$/fd/$f"}X,@ARGV' -- "$@";}
# Example: cat /usr/bin/id | memexec -u

