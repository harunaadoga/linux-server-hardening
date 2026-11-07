#!/bin/bash
# Episode 02 check: locking down user accounts. Read-only. Run as root.

PASS=0
FAIL=0
check() {
    if eval "$2" >/dev/null 2>&1; then
        echo "  PASS  $1"; PASS=$((PASS+1))
    else
        echo "  FAIL  $1"; FAIL=$((FAIL+1))
    fi
}
# Value of a "key = value" setting, from the main file and its drop-ins (last one wins)
pwq() {
    cat /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf 2>/dev/null |
        awk -F= -v k="$1" '{gsub(/[[:space:]]/,"")} $1==k {v=$2} END {print v}'
}

[ "$(id -u)" -eq 0 ] || { echo "Run as root: sudo bash check.sh"; exit 1; }

echo "Sudo and root"
check "admin user in wheel"              "id -nG admin | grep -qw wheel"
check "No NOPASSWD in sudoers"           "! grep -rEq '^[^#]*NOPASSWD' /etc/sudoers /etc/sudoers.d/"
check "root password locked"             "awk -F: '\$1==\"root\" {exit !(\$2 ~ /^!/)}' /etc/shadow"

echo "Password quality"
check "minlen 14 or more"                "[ \"\$(pwq minlen)\" -ge 14 ]"
check "minclass 4"                       "[ \"\$(pwq minclass)\" -ge 4 ]"
check "maxrepeat 3 or less"              "v=\$(pwq maxrepeat); [ -n \"\$v\" ] && [ \"\$v\" -gt 0 ] && [ \"\$v\" -le 3 ]"

echo "Account lockout"
check "faillock enabled in PAM"          "grep -q pam_faillock /etc/pam.d/system-auth"
check "deny = 3"                         "grep -Eq '^[[:space:]]*deny[[:space:]]*=[[:space:]]*3[[:space:]]*$' /etc/security/faillock.conf"
check "unlock_time = 900"                "grep -Eq '^[[:space:]]*unlock_time[[:space:]]*=[[:space:]]*900[[:space:]]*$' /etc/security/faillock.conf"
check "even_deny_root"                   "grep -Eq '^[[:space:]]*even_deny_root' /etc/security/faillock.conf"

echo "Password aging"
check "PASS_MAX_DAYS 90 or less"         "awk '\$1==\"PASS_MAX_DAYS\" {f=1; ok=(\$2<=90)} END {exit !(f && ok)}' /etc/login.defs"
check "PASS_MIN_DAYS 7 or more"          "awk '\$1==\"PASS_MIN_DAYS\" {f=1; ok=(\$2>=7)} END {exit !(f && ok)}' /etc/login.defs"
check "admin password max age 90 or less" "awk -F: '\$1==\"admin\" {exit !(\$5 != \"\" && \$5<=90)}' /etc/shadow"

echo "su and accounts"
check "su restricted to wheel"           "grep -Eq '^[[:space:]]*auth[[:space:]]+required[[:space:]]+pam_wheel.so' /etc/pam.d/su"
check "No accounts without a password"   "[ -z \"\$(awk -F: '\$2==\"\"' /etc/shadow)\" ]"
check "No system account with a login shell" "[ -z \"\$(awk -F: '\$3<1000 && \$1!=\"root\" && \$1!~/^(sync|shutdown|halt)\$/ && \$7!~/(nologin|false)\$/' /etc/passwd)\" ]"

echo "Banners"
for f in /etc/issue /etc/issue.net /etc/motd; do
    check "$f set"                       "[ -s $f ]"
done
check "Banners show no OS details"       "! grep -Eq '\\\\[mrsv]' /etc/issue /etc/issue.net"

echo
echo "Score: $PASS passed, $FAIL failed"
