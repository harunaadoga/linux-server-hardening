# 03 - Hardening SSH

▶ [Watch the video](https://www.youtube.com/watch?v=xPjogpvOukA)

SSH is the front door to your server. Disable SHA-1 system-wide, switch to SSH keys, and apply a hardening config that rejects everything you haven't allowed.

> **Keep your current SSH session open for the whole episode.** Only close it after you've logged in successfully from a second terminal. If something goes wrong, you can still fix it, or use the VM console.

## 1. See the attacks

```bash
sudo grep "Failed password" /var/log/secure | tail -20
sudo grep "Invalid user" /var/log/secure | tail -20
```

On a server reachable from the internet, these show bots guessing passwords and usernames.

## 2. Disable SHA-1 with crypto policies

RHEL manages algorithm strength for SSH, TLS, IPsec and Kerberos in one place: system-wide crypto policies.

```bash
sudo update-crypto-policies --show                  # DEFAULT
sudo curl -o /etc/crypto-policies/policies/modules/NO-SHA1.pmod https://raw.githubusercontent.com/harunaadoga/linux-server-hardening/main/03-ssh/files/NO-SHA1.pmod
cat /etc/crypto-policies/policies/modules/NO-SHA1.pmod
sudo update-crypto-policies --set DEFAULT:NO-SHA1
sudo update-crypto-policies --show                  # DEFAULT:NO-SHA1
```

[The module](./files/NO-SHA1.pmod) removes SHA-1 from hashes (`hash = -SHA1`), signatures (`sign = -*-SHA1`) and certificates (`sha1_in_certs = 0`).

Services pick up the new policy when they restart, and Red Hat recommends a reboot to apply it everywhere. Your current SSH session stays connected, and modern keys (Ed25519, RSA with SHA-2) keep working.

## 3. Set up SSH keys

**On your own computer**, not the server. Check for an existing Ed25519 key, and create one if there isn't:

```bash
ls ~/.ssh/id_ed25519.pub
ssh-keygen -t ed25519 -C "admin@yourname"           # only if you don't have one; use a passphrase
```

Copy it to the server and test it. Replace `192.168.64.3` with your server's IP:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub admin@192.168.64.3
ssh -i ~/.ssh/id_ed25519 admin@192.168.64.3
```

Do this **before** step 4, which turns off password logins.

If the server itself needs to log in elsewhere (GitHub, other servers), give it its own key. Never copy your personal key onto a server. On the server:

```bash
ssh-keygen -t ed25519 -C "server@node1"
cat ~/.ssh/id_ed25519.pub                           # add this to GitHub under Settings > SSH and GPG keys
```

## 4. Apply the hardening config

Use a drop-in file instead of editing `/etc/ssh/sshd_config`, so your changes survive package updates.

For each setting, sshd uses the **first** value it reads, and it reads `/etc/ssh/sshd_config.d/` in alphabetical order. RHEL already ships `50-redhat.conf` there, which sets `X11Forwarding`, and the installer may add `01-permitrootlogin.conf`. So the hardening file is named `00-hardening.conf`, to be read first and win every setting.

> The video names it `99-hardening.conf`. That name loses to `50-redhat.conf`, so `X11Forwarding no` is ignored. Use `00-`.

```bash
sudo ls /etc/ssh/sshd_config.d/
sudo curl -o /etc/ssh/sshd_config.d/00-hardening.conf https://raw.githubusercontent.com/harunaadoga/linux-server-hardening/main/03-ssh/files/00-hardening.conf
sudo vi /etc/ssh/sshd_config.d/00-hardening.conf
```

Check the `AllowUsers` line. It must list **your** SSH user, or you'll be locked out. Change it if your user isn't `admin`, then save and quit:

```
AllowUsers admin
```

What [the file](./files/00-hardening.conf) sets:

| Setting | Meaning |
|---------|---------|
| `PermitRootLogin no` | No root logins over SSH. Use sudo |
| `PasswordAuthentication no` | Keys only. Password guessing becomes pointless |
| `PermitEmptyPasswords no` | Accounts with an empty password can't log in |
| `MaxAuthTries 3` | 3 attempts per connection (default 6) |
| `AllowUsers admin` | Only the listed users can log in |
| `ClientAliveInterval 300`, `ClientAliveCountMax 2` | Drop a connection after 10 minutes if the client stops responding, for example a laptop that went to sleep |
| `X11Forwarding no` | No graphical apps over SSH |
| `HostbasedAuthentication no` | No login based on the client's hostname |
| `PermitUserEnvironment no` | Users can't set environment variables through SSH |
| `LoginGraceTime 60` | 60 seconds to log in, then disconnect |
| `MaxStartups 10:30:60` | Limit unauthenticated connections: start dropping 30% after 10, refuse all after 60 |
| `MaxSessions 4` | 4 sessions per connection (default 10) |
| `Banner /etc/issue.net` | Show the warning banner from episode 2 |
| `LogLevel VERBOSE` | Log more detail, including the key used for each login |

## 5. File permissions

```bash
ls -l /etc/ssh/sshd_config                          # root root, 600
ls -l /etc/ssh/ssh_host_*_key                       # private host keys
sudo chmod 600 /etc/ssh/ssh_host_*_key
sudo chmod 644 /etc/ssh/ssh_host_*_key.pub
```

If others can read the private host keys, your server can be impersonated. 600 lets only root read them. RHEL's default, 640 with group `ssh_keys`, is also fine.

## 6. Test, restart, test again

```bash
sudo sshd -t                                        # no output means the config is valid
sudo systemctl restart sshd
sudo sshd -T | grep -Ei '^(permitrootlogin|passwordauthentication|x11forwarding|allowusers) '
```

`sshd -T` shows the settings sshd is actually using. You should see `permitrootlogin no`, `passwordauthentication no`, `x11forwarding no` and your `allowusers`.

Now, **without closing your current session**, open a second terminal on your own computer:

```bash
ssh -i ~/.ssh/id_ed25519 admin@192.168.64.3
```

Only close the first session once this works. If it fails, fix it from the first session, or from the VM console.

## Check

```bash
curl -O https://raw.githubusercontent.com/harunaadoga/linux-server-hardening/main/03-ssh/check.sh
sudo bash check.sh
```
