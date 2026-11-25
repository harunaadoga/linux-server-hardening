# 05 - Filesystem Security

▶ [Watch the video](https://youtu.be/Ey51y6zvFD0)

Stop programs running from /tmp, find the programs that make you root, check the login files, and stop even root from changing them by accident.

## 1. Lock down /tmp and /dev/shm

Anyone can write to /tmp, so attackers use it to drop and run their tools. Check whether /tmp is its own filesystem:

```bash
df -hT
cat /etc/fstab
mount | grep /dev/shm                               # nosuid,nodev but no noexec
```

Add [the two lines](./files/tmp-mounts) to the end of `/etc/fstab`:

```bash
curl -O https://raw.githubusercontent.com/harunaadoga/linux-server-hardening/main/05-filesystem/files/tmp-mounts
cat tmp-mounts | sudo tee -a /etc/fstab
```

| Option | Meaning |
|--------|---------|
| `noexec` | Nothing can run from this filesystem |
| `nosuid` | SUID bits are ignored |
| `nodev` | No device files |

Then reboot to apply them:

```bash
sudo reboot
mount | grep -E '/tmp|/dev/shm'                     # nodev,nosuid,noexec on both
```

> The video applies them without a reboot (`sudo mount /tmp` and `sudo mount -o remount /dev/shm`). That works, but services that have their own private /tmp, such as Apache, then fail to reload until the next reboot. Reboot instead. On a production server, test first: some installers run programs from /tmp.

## 2. Find the programs that make you root

A SUID program runs as its owner. If root owns it, whoever runs it is root while it runs.

```bash
sudo find / -xdev -perm -4000                       # SUID
sudo find / -xdev -perm -2000                       # SGID, the group version
```

`-xdev` keeps the search on this disk. Expect standard tools such as `passwd`, `su`, `sudo`, `mount` and `crontab`. You should be able to explain every line.

## 3. Files anyone can change, and files with no owner

```bash
sudo find / -xdev -type f -perm -0002               # writable by everyone: should print nothing
sudo find / -xdev -nouser                           # no owner: should print nothing
sudo find / -xdev -nogroup                          # no group: should print nothing
```

Files with no owner are left behind when a user is deleted. A new account with the same UID would own them.

## 4. Check the login files

```bash
ls -l /etc/passwd /etc/shadow /etc/group /etc/gshadow
```

`passwd` and `group` should be 644 (`rw-r--r--`), `shadow` and `gshadow` 000 (`----------`). RHEL sets these by default. If yours are wrong:

```bash
sudo chmod 644 /etc/passwd /etc/group
sudo chmod 000 /etc/shadow /etc/gshadow
```

## 5. Immutable files with chattr

`chattr +i` stops a file being changed, deleted or renamed, even by root, until the flag is removed.

```bash
lsattr /etc/passwd /etc/shadow /etc/group           # all dashes
sudo chattr +i /etc/passwd /etc/shadow /etc/group
lsattr /etc/passwd /etc/shadow /etc/group           # an i on each
sudo useradd testuser                               # fails, even as root
```

Root can remove the flag, so this won't stop a skilled attacker. It stops scripts and accidents. To make a real change, remove it, make the change and put it back:

```bash
sudo chattr -i /etc/passwd /etc/shadow /etc/group
sudo useradd testuser
sudo userdel -r testuser
sudo chattr +i /etc/passwd /etc/shadow /etc/group
```

> While the flag is set, `passwd`, `useradd`, and installing packages that add users all fail. Remove it before you change users, and before episode 8.

## 6. Append-only logs

`chattr +a` lets new lines be added but stops existing lines being changed or deleted:

```bash
sudo chattr +a /var/log/messages
lsattr /var/log/messages                            # an a
sudo chattr -a /var/log/messages
```

It breaks log rotation, so only use it on logs you specifically want to protect.

## Check

```bash
curl -O https://raw.githubusercontent.com/harunaadoga/linux-server-hardening/main/05-filesystem/check.sh
sudo bash check.sh
```
