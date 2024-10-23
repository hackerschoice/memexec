#! /bin/bash

memexec() { bash -c 'cd /proc/$$;exec 4>mem;base64 -d<<<SIngTTHSSIM4AHUQSIN4CCF1CUiD6AhJicLrBkiDwAjr5EyJ0E0x200x5EiDOAB1EEmJw0mD6whIg8AISYnE6wZIg+gI6+RMidhNMe1IMf9IixhIOft0JUiLC0iB4f///wBIgfktLQAAdQlJicZIiXj46wlIg+gISP/H69NIieVIgewSBAAASLhrZXJuZWwAAGoAULg/AQAASInnSDH2DwVJicC4AAAAAL8AAAAASInmugAEAAAPBUiJwkiD+gB+D7gBAAAATInHSInmDwXr1LhCAQAATInHagBIieZMifJIMclNMclNieJBuAAQAAAPBQ==|dd bs=1 seek=$[$(cat syscall|cut -f9 -d" ")]>&4' "$@"; }

# Example: 
#  cat /usr/bin/id | memexec 
#  cat /bin/ls | TIME_STYLE=+%s memexec -- -lah

