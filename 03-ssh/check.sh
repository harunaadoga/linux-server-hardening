#!/bin/bash
# Episode 03 check: hardening SSH. Read-only. Run as root.
# Uses "sshd -T", which shows the settings sshd actually uses.

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

SSHD=$(sshd -T 2>/dev/null)
if [ -z "$SSHD" ]; then
    echo "sshd -T failed. Run 'sshd -t' to see the error in your SSH config."
    exit 1
fi
# Effective value of an sshd setting
opt() {
    echo "$SSHD" | awk -v k="$1" '$1==k {$1=""; sub(/^ /,""); print; exit}'
}

echo "Crypto policy"
check "SHA-1 disabled (NO-SHA1)"        "update-crypto-policies --show | grep -q NO-SHA1"

echo "SSH settings in effect"
check "PermitRootLogin no"              "[ \"\$(opt permitrootlogin)\" = no ]"
check "PasswordAuthentication no"       "[ \"\$(opt passwordauthentication)\" = no ]"
check "PermitEmptyPasswords no"         "[ \"\$(opt permitemptypasswords)\" = no ]"
check "MaxAuthTries 3 or less"          "[ \"\$(opt maxauthtries)\" -le 3 ]"
check "AllowUsers set"                  "[ -n \"\$(opt allowusers)\" ]"
check "ClientAliveInterval 300"         "[ \"\$(opt clientaliveinterval)\" = 300 ]"
check "ClientAliveCountMax 2"           "[ \"\$(opt clientalivecountmax)\" = 2 ]"
check "X11Forwarding no"                "[ \"\$(opt x11forwarding)\" = no ]"
check "HostbasedAuthentication no"      "[ \"\$(opt hostbasedauthentication)\" = no ]"
check "PermitUserEnvironment no"        "[ \"\$(opt permituserenvironment)\" = no ]"
check "LoginGraceTime 60 or less"       "[ \"\$(opt logingracetime)\" -le 60 ]"
check "MaxStartups 10:30:60"            "[ \"\$(opt maxstartups)\" = 10:30:60 ]"
check "MaxSessions 4 or less"           "[ \"\$(opt maxsessions)\" -le 4 ]"
check "Banner /etc/issue.net"           "[ \"\$(opt banner)\" = /etc/issue.net ]"
check "LogLevel VERBOSE"                "[ \"\$(opt loglevel)\" = VERBOSE ]"

echo "File permissions"
check "sshd_config owned by root, 600 or 644" "[ \"\$(stat -c %U:%a /etc/ssh/sshd_config)\" = root:600 ] || [ \"\$(stat -c %U:%a /etc/ssh/sshd_config)\" = root:644 ]"
for key in /etc/ssh/ssh_host_*_key; do
    check "$(basename "$key") is 600 or 640" "case \$(stat -c %a $key) in 600|640) true ;; *) false ;; esac"
done

echo
echo "Score: $PASS passed, $FAIL failed"
