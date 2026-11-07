# 04 - Firewall with firewalld

▶ [Watch the video](https://www.youtube.com/watch?v=e-GcC3mW6gs)

Deny everything by default, then allow only what the server needs.

## 1. Check firewalld and zones

```bash
sudo systemctl status firewalld                     # active (running)
sudo systemctl enable --now firewalld               # only if it isn't running
sudo firewall-cmd --state                           # running
sudo firewall-cmd --list-all                        # current zone, interfaces and allowed services
```

A zone is a set of rules applied to a network interface. An interface that isn't assigned to a zone uses the default zone, usually `public`.

```bash
sudo firewall-cmd --get-default-zone
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --get-zones
```

| Zone | Use |
|------|-----|
| `drop` | Drops everything silently |
| `block` | Rejects everything with an ICMP message |
| `public` | Untrusted networks. The usual zone for a server |
| `trusted` | Allows everything. Almost never use it |
| `dmz` | Servers that need limited public access |
| `external`, `internal` | The outside and inside of a router |
| `home`, `work` | Desktops, not servers |

To change the default zone, or move an interface to another zone (replace `enp0s1` with your interface from `--get-active-zones`):

```bash
sudo firewall-cmd --set-default-zone=public
sudo firewall-cmd --zone=internal --change-interface=enp0s1
sudo firewall-cmd --zone=public --change-interface=enp0s1      # back to public
```

## 2. Default deny

Remove what RHEL allows by default and the server doesn't need, then add back only what it does. This example server runs SSH and a web server:

```bash
sudo firewall-cmd --permanent --remove-service=cockpit
sudo firewall-cmd --permanent --remove-service=dhcpv6-client
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
sudo firewall-cmd --list-all                        # services: ssh http https
```

`--permanent` saves the rule, but it only takes effect after `--reload`. Without `--permanent`, a rule applies straight away but is gone after a reboot.

Service names come from `/usr/lib/firewalld/services/`, so `http` means port 80/tcp. They are clearer than port numbers.

## 3. Allow SSH from one network only

A rich rule can match on source address. This allows SSH only from `192.168.64.0/24`. Use your own management network:

```bash
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.64.0/24" service name="ssh" accept'
sudo firewall-cmd --permanent --remove-service=ssh
sudo firewall-cmd --reload
sudo firewall-cmd --list-all                        # ssh gone from services, rich rule listed
```

The rich rule and the `ssh` service add up: while `ssh` is still in the services list, SSH is open to everyone. That's why the `ssh` service is removed.

> Existing connections survive a reload, so keep your session open and test a **new** SSH connection before closing it. If you lock yourself out, fix it from the VM console.

To go back to allowing SSH from anywhere:

```bash
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload
```

## 4. Log denied traffic and compare with what's listening

```bash
sudo firewall-cmd --set-log-denied=all
```

This one saves and applies immediately, with no `--permanent` or `--reload` needed.

```bash
sudo ss -tulnp                                      # what is listening
sudo firewall-cmd --list-all                        # what is allowed
sudo dmesg | grep REJECT                            # traffic the firewall rejected
```

They should match: every allowed service has something listening, and anything listening that shouldn't be reachable from outside stays blocked.

## Check

```bash
curl -O https://raw.githubusercontent.com/harunaadoga/linux-server-hardening/main/04-firewall/check.sh
sudo bash check.sh
```
