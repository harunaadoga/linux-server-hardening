# 01 - Reducing the Attack Surface

▶ [Watch the video](https://www.youtube.com/watch?v=xQHweeFyLtQ)

Every installed package and running service is code that could have a vulnerability. Remove what the server doesn't need, then patch what's left.

## 1. See what's there

```bash
rpm -qa | wc -l                                     # number of installed packages
systemctl list-units --type=service --state=running
sudo ss -tulnp                                      # listening ports and the process behind each
```

`ss` flags: `t` TCP, `u` UDP, `l` listening only, `n` numeric (no DNS lookups), `p` show the process.

## 2. Stop, disable and mask what you don't need

Port 111 is `rpcbind`, needed only for NFS. Stop, disable and mask both the service and its socket. If you leave the socket, it can start the service again on demand.

```bash
sudo ss -tulnp | grep 111
sudo systemctl stop rpcbind.socket rpcbind.service
sudo systemctl disable rpcbind.socket rpcbind.service
sudo systemctl mask rpcbind.socket rpcbind.service
sudo ss -tulnp | grep 111                           # no output: port closed
```

`mask` links the unit to `/dev/null`, so nothing can start it, not even another package.

`gssproxy` is a Kerberos helper. Unless the server joins Active Directory or FreeIPA, or uses NFS, mask it:

```bash
sudo systemctl stop gssproxy
sudo systemctl disable gssproxy
sudo systemctl mask gssproxy
```

Cockpit isn't running on a minimal install, but its socket is there. Mask it:

```bash
systemctl status cockpit.socket
sudo systemctl mask cockpit.socket cockpit.service
```

## 3. Remove packages you don't need

```bash
rpm -q cups avahi nfs-utils                         # "not installed" on a minimal install
sudo dnf remove -y cups avahi nfs-utils             # only if they are installed

sudo dnf group list --installed
sudo dnf group remove -y "Server with GUI"          # only if a GUI is installed
```

Check the result:

```bash
rpm -qa | wc -l
sudo ss -tulnp
```

## 4. Check your package sources

Packages are signed with GPG keys. Make sure every repo checks those signatures.

```bash
rpm -qa gpg-pubkey*                                 # the keys your system trusts
grep -r gpgcheck /etc/yum.repos.d/                  # every repo should show gpgcheck=1
```

## 5. Patch, then keep patching automatically

```bash
sudo dnf update -y

sudo dnf install -y dnf-automatic
sudo systemctl enable --now dnf-automatic-install.timer
systemctl status dnf-automatic-install.timer        # active (waiting), enabled
```

`dnf-automatic-install.timer` downloads and installs updates daily, whatever `apply_updates` says in `/etc/dnf/automatic.conf`. By default it installs **all** updates. To install only security updates:

```bash
sudo vi /etc/dnf/automatic.conf
```

Set this line in the `[commands]` section, then save and quit:

```
upgrade_type = security
```

## 6. Final check

```bash
systemctl list-units --type=service --state=running   # recognise every service here
sudo ss -tulnp                                        # fewer ports than at the start
```

Then run the check script:

```bash
curl -O https://raw.githubusercontent.com/harunaadoga/linux-server-hardening/main/01-attack-surface/check.sh
sudo bash check.sh
```
