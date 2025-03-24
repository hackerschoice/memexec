#! /bin/bash

memexec(){ perl '-e$^F=255;for(319,279,385,314){($f=syscall$_,$",0)>0&&last};open($o,">&=".$f);print$o(<STDIN>);exec{"/proc/$$/fd/$f"}X,@ARGV' -- "$@";}
# memexec(){ perl '-efor(319,279){($f=syscall$_,$",1)>0&&last};open($o,">&=".$f);print$o(<STDIN>);exec{"/proc/$$/fd/$f"}X,@ARGV' -- "$@";}
# Example: cat /usr/bin/id | memexec -u

