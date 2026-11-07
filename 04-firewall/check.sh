#!/bin/bash
# Episode 04 check: firewall with firewalld. Read-only. Run as root.

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

echo "firewalld"
check "firewalld running"               "systemctl is-active firewalld"
check "firewalld enabled at boot"       "systemctl is-enabled firewalld"
check "Default zone is public"          "[ \"\$(firewall-cmd --get-default-zone)\" = public ]"

echo "Rules (default zone, permanent)"
check "cockpit not allowed"             "! firewall-cmd --permanent --list-services | grep -qw cockpit"
check "dhcpv6-client not allowed"       "! firewall-cmd --permanent --list-services | grep -qw dhcpv6-client"
check "SSH allowed (service or rich rule)" "firewall-cmd --permanent --list-services | grep -qw ssh || firewall-cmd --permanent --list-rich-rules | grep -q 'service name=\"ssh\"'"
check "Permanent rules loaded (reload done)" "[ \"\$(firewall-cmd --list-services)\" = \"\$(firewall-cmd --permanent --list-services)\" ] && [ \"\$(firewall-cmd --list-rich-rules)\" = \"\$(firewall-cmd --permanent --list-rich-rules)\" ]"

echo "Logging"
check "Denied packets logged"           "[ \"\$(firewall-cmd --get-log-denied)\" != off ]"

echo
echo "Allowed services: $(firewall-cmd --list-services)"
echo "Score: $PASS passed, $FAIL failed"
