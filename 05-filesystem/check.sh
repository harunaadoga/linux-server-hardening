#!/bin/bash
# Episode 05 check: filesystem security. Read-only. Run as root.

PASS=0
FAIL=0
check() {
    if eval "$2" >/dev/null 2>&1; then
        echo "  PASS  $1"; PASS=$((PASS+1))
    else
        echo "  FAIL  $1"; FAIL=$((FAIL+1))
    fi
}

[ "$(id -u)" -eq 0 ] || { echo "Run as root: sudo bash check.sh"; exit 1; }

echo "/tmp and /dev/shm"
for m in /tmp /dev/shm; do
    check "$m is its own filesystem"    "findmnt -n $m"
    for opt in nodev nosuid noexec; do
        check "$m mounted $opt"         "findmnt -n -o OPTIONS $m | grep -qw $opt"
    done
done

echo "Login files"
check "/etc/passwd is 644 or stricter"  "[ \$(( 0\$(stat -c %a /etc/passwd) & 0133 )) -eq 0 ]"
check "/etc/group is 644 or stricter"   "[ \$(( 0\$(stat -c %a /etc/group) & 0133 )) -eq 0 ]"
check "/etc/shadow is 000"              "[ \"\$(stat -c %a /etc/shadow)\" = 0 ]"
check "/etc/gshadow is 000"             "[ \"\$(stat -c %a /etc/gshadow)\" = 0 ]"
check "Login files owned by root"       "[ -z \"\$(find /etc/passwd /etc/shadow /etc/group /etc/gshadow ! -user root)\" ]"

echo "Files (this takes a moment)"
check "No files writable by everyone"   "[ -z \"\$(find / -xdev -type f -perm -0002 -print -quit)\" ]"
check "No files with no owner"          "[ -z \"\$(find / -xdev -nouser -print -quit)\" ]"
check "No files with no group"          "[ -z \"\$(find / -xdev -nogroup -print -quit)\" ]"

echo
echo "SUID programs on this disk: $(find / -xdev -type f -perm -4000 | wc -l). Review them with: sudo find / -xdev -perm -4000"
echo "Immutable login files: $(lsattr /etc/passwd /etc/shadow /etc/group 2>/dev/null | awk '$1 ~ /i/' | wc -l) of 3"
echo "Score: $PASS passed, $FAIL failed"
