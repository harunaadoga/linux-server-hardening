# Linux Server Hardening

Linux server hardening, step by step, with a video and a check script for every episode. Each episode builds on the one before it.

Written for RHEL, Rocky Linux and AlmaLinux 9 and 10.

> **Test on a VM first, and take a snapshot before each episode.** Some of these changes can lock you out of a server if you get them wrong. Keep a console open (or your current SSH session) until you have tested that you can still log in.

## Episodes

| # | Episode | Steps | Check | Video |
|---|---------|-------|-------|-------|
| 01 | Reducing the Attack Surface | [Steps](./01-attack-surface/README.md) | [check.sh](./01-attack-surface/check.sh) | [▶ Watch](https://www.youtube.com/watch?v=xQHweeFyLtQ) |
| 02 | Locking Down User Accounts | [Steps](./02-user-accounts/README.md) | [check.sh](./02-user-accounts/check.sh) | [▶ Watch](https://www.youtube.com/watch?v=fbEMHl9VFSw) |
| 03 | Hardening SSH | [Steps](./03-ssh/README.md) | [check.sh](./03-ssh/check.sh) | [▶ Watch](https://www.youtube.com/watch?v=xPjogpvOukA) |
| 04 | Firewall with firewalld | [Steps](./04-firewall/README.md) | [check.sh](./04-firewall/check.sh) | [▶ Watch](https://www.youtube.com/watch?v=e-GcC3mW6gs) |

New episodes are added as they are published.

## How to Use

1. Watch the episode
2. Follow the steps in its folder on your own VM
3. Run its check script to confirm the changes are in place:

```bash
curl -O https://raw.githubusercontent.com/harunaadoga/linux-server-hardening/main/01-attack-surface/check.sh
sudo bash check.sh
```

Each check script only reads your system. It changes nothing.

## Debian and Ubuntu

The ideas are the same, but some tools differ: ufw instead of firewalld, no `authselect` or system-wide crypto policies, `apt` instead of `dnf`, and SSH logs in `/var/log/auth.log` instead of `/var/log/secure`.

## Disclaimer

The settings follow the CIS Benchmark for RHEL. This is an independent project, not affiliated with CIS or Red Hat. Review every change before you apply it to a production server.

## License

Copyright (C) 2026 Haruna Adoga. Licensed under [GPL-3.0](./LICENSE).
