#! /bin/bash

memexec(){ perl '-efor(319,279){($f=syscall$_,$",1)>0&&last};open($o,">&=".$f);print$o(<STDIN>);exec{"/proc/$$/fd/$f"}X,@ARGV' -- "$@";}
# Example: cat /usr/bin/id | memexec -u

