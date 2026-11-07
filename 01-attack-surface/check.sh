#!/bin/bash
# Episode 01 check: reducing the attack surface. Read-only. Run as root.

PASS=0
FAIL=0
check() {
    if eval "$2" >/dev/null 2>&1; then
        echo "  PASS  $1"; PASS=$((PASS+1))
    else
        echo "  FAIL  $1"; FAIL=$((FAIL+1))
    fi
}
# Passes if the unit is masked, or not installed at all
masked_or_absent() {
    state=$(systemctl is-enabled "$1" 2>/dev/null)
    [ "$state" = masked ] || [ -z "$state" ] || [ "$state" = not-found ]
}

[ "$(id -u)" -eq 0 ] || { echo "Run as root: sudo bash check.sh"; exit 1; }

echo "Services"
for unit in rpcbind.socket rpcbind.service gssproxy.service cockpit.socket; do
    check "$unit masked or not installed" "masked_or_absent $unit"
done
check "Port 111 (rpcbind) not listening" "! ss -tuln | grep -q ':111 '"

echo "Packages"
for pkg in cups avahi nfs-utils; do
    check "$pkg not installed" "! rpm -q $pkg"
done
check "No GUI installed" "! rpm -q gnome-shell"

echo "Package sources"
check "No repo has gpgcheck=0" "! grep -rEq '^[[:space:]]*gpgcheck[[:space:]]*=[[:space:]]*0' /etc/yum.repos.d/"

echo "Automatic updates"
check "dnf-automatic installed" "rpm -q dnf-automatic"
check "dnf-automatic-install.timer enabled" "systemctl is-enabled dnf-automatic-install.timer"
check "dnf-automatic-install.timer active" "systemctl is-active dnf-automatic-install.timer"

echo
echo "Score: $PASS passed, $FAIL failed"
