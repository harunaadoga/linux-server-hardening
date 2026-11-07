# 02 - Locking Down User Accounts

▶ [Watch the video](https://www.youtube.com/watch?v=fbEMHl9VFSw)

Most breaches start with weak credentials. Lock root, use a named admin with sudo, enforce strong passwords, lock out repeated failures, and add warning banners.

## 1. Check who has sudo

```bash
grep wheel /etc/group                               # members of wheel can use sudo
sudo cat /etc/sudoers
```

Look for `NOPASSWD`. A line like `%wheel ALL=(ALL) NOPASSWD: ALL` lets every wheel user run anything as root without a password. The safe line is:

```
%wheel ALL=(ALL) ALL
```

To change sudoers, always use `sudo visudo`, never a normal editor. `visudo` checks the syntax before saving, so a typo can't lock you out of sudo.

## 2. Create an admin user, then lock root

```bash
sudo useradd -m -G wheel admin
sudo passwd admin
```

Before locking root, make sure `admin` can use sudo:

```bash
su - admin
sudo -l                                             # should list (ALL) ALL
```

Then, as `admin`:

```bash
sudo passwd -l root
```

This puts `!` in front of root's password hash, so nobody can log in as root with a password. `sudo` still works, because it asks for your own password. To undo it in an emergency: `sudo passwd -u root`.

> With root locked, rescue and emergency mode can't ask for root's password. To recover a broken system, boot with `init=/bin/bash` added to the kernel line at the GRUB menu.

## 3. Password quality with pwquality

Put your rules in a drop-in file instead of editing the main config, so they survive package updates.

```bash
sudo mkdir -p /etc/security/pwquality.conf.d
sudo curl -o /etc/security/pwquality.conf.d/99-hardening.conf https://raw.githubusercontent.com/harunaadoga/linux-server-hardening/main/02-user-accounts/files/99-hardening.conf
cat /etc/security/pwquality.conf.d/99-hardening.conf
```

What [the file](./files/99-hardening.conf) sets:

| Setting | Meaning |
|---------|---------|
| `minlen = 14` | At least 14 characters |
| `minclass = 4` | Uppercase, lowercase, digits and special characters |
| `dcredit`, `ucredit`, `lcredit`, `ocredit = -1` | At least one digit, uppercase, lowercase and special character |
| `maxrepeat = 3` | No more than 3 identical characters in a row |
| `maxclassrepeat = 4` | No more than 4 characters of the same class in a row |

## 4. Account lockout with faillock

On RHEL, PAM is managed by `authselect`. Don't edit the files in `/etc/pam.d/` by hand: `authselect` overwrites them.

```bash
sudo authselect current
sudo authselect select sssd with-faillock --force
sudo vi /etc/security/faillock.conf
```

Add these lines at the end, then save and quit:

```
deny = 3
unlock_time = 900
even_deny_root
root_unlock_time = 60
```

| Setting | Meaning |
|---------|---------|
| `deny = 3` | Lock the account after 3 failed attempts |
| `unlock_time = 900` | Unlock automatically after 15 minutes |
| `even_deny_root` | Lock root too |
| `root_unlock_time = 60` | Root unlocks after 60 seconds |

To unlock an account by hand: `sudo faillock --user admin --reset`

## 5. Password aging

For an existing user:

```bash
sudo chage -M 90 -m 7 -W 14 admin                   # max 90 days, min 7, warn 14 days before
sudo chage -l admin
```

"Password expires" still shows `never` until the user changes their password. The 90 days count from the last change.

For users created from now on:

```bash
sudo vi /etc/login.defs
```

Change these lines to the following, then save and quit:

```
PASS_MAX_DAYS   90
PASS_MIN_DAYS   7
```

## 6. Restrict su to the wheel group

```bash
sudo vi /etc/pam.d/su
```

Find the two `pam_wheel.so` lines. Remove the `#` from the `required` line only, then save and quit:

```
auth           required        pam_wheel.so use_uid
```

Leave the `sufficient ... trust` line commented. It would let wheel users become root without a password.

## 7. Find weak accounts

```bash
sudo passwd -S -a | grep NP                         # accounts with no password: should print nothing
grep -v nologin /etc/passwd | grep -v /bin/false | grep -v root
```

Ignore `sync`, `shutdown` and `halt`. A system account such as `apache` or `mysql` with `/bin/bash` should get `/sbin/nologin`. For example, for `apache`:

```bash
sudo usermod -s /sbin/nologin apache
```

## 8. Warning banners

```bash
echo "Authorized users only. All activity is monitored and logged." | sudo tee /etc/issue /etc/issue.net
printf "Authorized users only. All activity is monitored and logged.\nUnauthorized access is prohibited.\n" | sudo tee /etc/motd
```

`/etc/issue.net` is shown before SSH login (episode 3 turns it on), `/etc/issue` before a console login, and `/etc/motd` after login. Keep them generic: no company name, OS version or kernel details.

## Check

```bash
curl -O https://raw.githubusercontent.com/harunaadoga/linux-server-hardening/main/02-user-accounts/check.sh
sudo bash check.sh
```
