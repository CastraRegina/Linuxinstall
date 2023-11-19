# Linuxinstall
Personal guide to installing and setting up a Linux laptop

[System Settings](#system-settings)  
[User Settings](#user-settings)  
[HowTos, infos and command examples](#howtos-infos-and-command-examples)

## System Settings
First user name:  
`install` with id `1000`

### Setup Wi-Fi connection
Check Settings to be stored „for all user w/o encryption“,  
see: Netzwerk --> Verbindungen --> Wi-Fi

### Install first packages
```bash
sudo apt update && sudo apt upgrade -y
```
```bash
sudo apt install -y vim
sudo apt install -y gparted
sudo apt install -y net-tools
sudo apt install -y ecryptfs-utils rsync lsof
sudo apt install -y cryptsetup
sudo apt install -y open-iscsi
sudo apt install -y usb-creator-gtk
sudo apt install -y software-properties-common apt-transport-https wget
sudo apt install -y libpam-mount
sudo apt install -y baobab        # Disk Usage Analyzer
sudo apt install -y gdebi-core    # resolve deb-dependicies
```

### Install a Live System on USB drive
- See [Ubuntu.com: create-a-usb-stick-on-ubuntu](https://ubuntu.com/tutorials/create-a-usb-stick-on-ubuntu#1-overview)  
- Download Ubuntu iso-file from [https://ubuntu.com/download/desktop](https://ubuntu.com/download/desktop)
- Use "Startup Disk Creator" to copy the iso-file onto the USB-stick (and make it bootable)


### Execute system setup scripts
Change into folder [01_setup_system](01_setup_system) and execute files
- `010_install_packages.sh`
- TODO


### Configure editor
Select `/usr/bin/vim.basic`
```bash
sudo update-alternatives --config editor
```


### Install VS Code
```
sudo apt install -y software-properties-common apt-transport-https wget
```
```
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
```
```
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
```
```
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg]  https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
```
```
rm -f packages.microsoft.gpg
```
```
sudo apt update && sudo apt install -y code
```


### Change partition table
Remark: do a `sudo swapoff -a` before changing swap partition(s).  
Use e.g. `gparted` to create and resize partitions.  
Use the *live linux on USB-stick* to resize the root partition.
```
sudo fdisk -l
```
```
Disk /dev/nvme0n1: 1.82 TiB, 2000398934016 bytes, 3907029168 sectors
Disk model: Samsung SSD 990 PRO 2TB                 
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: C38612F2-FC68-497E-8F56-E2CE20A4EACA

Device              Start        End    Sectors  Size Type
/dev/nvme0n1p1       2048    1050623    1048576  512M EFI System - /boot/efi
/dev/nvme0n1p2    1050624  205850623  204800000 97.7G Linux - / 100000 MiB root
/dev/nvme0n1p3  205850624  410650623  204800000 97.7G Linux -   100000 MiB root 2
/dev/nvme0n1p4  410650624 3871770623 3461120000  1.6T Linux - /home 1690000 MiB
/dev/nvme0n1p5 3871770624 3888154623   16384000  7.8G Linux swap - 8000MiB
/dev/nvme0n1p6 3888154624 3896346623    8192000  3.9G Linux - /mnt/tinyraid1 4000 MiB


Disk /dev/nvme1n1: 3.64 TiB, 4000787030016 bytes, 7814037168 sectors
Disk model: CT4000P3PSSD8                           
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 64B365E4-830D-48AF-8842-DD0B66045FCF

Device              Start        End    Sectors  Size Type
/dev/nvme1n1p1       2048    1050623    1048576  512M EFI System - /boot/efi
/dev/nvme1n1p2    1050624  205850623  204800000 97.7G Linux - / 100000 MiB root
/dev/nvme1n1p3  205850624  410650623  204800000 97.7G Linux -   100000 MiB root 2
/dev/nvme1n1p4  410650624 4097050623 3686400000  1.7T Linux - /mnt/bakhome 1800000 MiB
/dev/nvme1n1p5 4097050624 7783450623 3686400000  1.7T Linux - /mnt/bakmlc4 1800000 MiB
/dev/nvme1n1p6 7783450624 7799834623   16384000  7.8G Linux swap - 8000MiB
/dev/nvme1n1p7 7799834624 7808026623    8192000  3.9G Linux - /mnt/tinyraid1 4000 MiB
```


### Create mount point folders on `/mnt`
```
/mnt/bakhome
/mnt/bakmlc4
/mnt/lanas01_bakmlc4
/mnt/lanas01_bakmlc5
/mnt/lanas01_test
/mnt/tinyraid1
```


### Switch swap off permanently
Disable by removing (commenting out) the swap-partition entry in `/etc/fstab`#
```
swapoff -a 
mount -a
free -h
```
Check systemctl:
```
systemctl --type swap
```
```
sudo systemctl mask "dev-nvme0n1p5.swap"
sudo systemctl mask "dev-nvme1n1p6.swap" 
```


### Create /tmp in memory 
Add following line to `/etc/fstab` and clean `/tmp` by a different (live) linux before activating:
```
tmpfs /tmp tmpfs defaults,noatime,nosuid,nodev,noexec,mode=1777,size=8192M 0 0
```


### Create encrypted partition
#### Setup
```
lsblk
blkid
sudo fdisk -l
```
```
export NEW_PARTITION=/dev/nvme1n1p4
sudo cryptsetup --cipher aes-xts-plain64 --key-size 512 --hash sha512 -v luksFormat $NEW_PARTITION
sudo cryptsetup config --label="crypt_bakhome" $NEW_PARTITION
sudo cryptsetup luksDump $NEW_PARTITION
```
Get the output of `blkid | grep $NEW_PARTITION`
```
/dev/nvme1n1p4: UUID="0fc8cdf8-59c1-4839-91c2-34ad2f20302d" LABEL="crypt_bakhome" TYPE="crypto_LUKS" PARTUUID="e072239d-4eaa-4c9f-b752-478a7bbef61b"
```
or `sudo cryptsetup luksUUID $NEW_PARTITION`
```
0fc8cdf8-59c1-4839-91c2-34ad2f20302d
```
... and modify `/etc/crypttab`
```
crypt_bakhome           UUID=0fc8cdf8-59c1-4839-91c2-34ad2f20302d               none            luks,discard,noauto
```
Create filesystem
```
sudo cryptsetup luksOpen $NEW_PARTITION crypt_bakhome
sudo mkfs.btrfs -L "crypt_bakhome" /dev/mapper/crypt_bakhome
sudo mount /dev/mapper/crypt_bakhome /mnt/bakhome
sudo btrfs fi df /mnt/bakhome    # just to check systemdata&metadata=DUP
```
Make backup of LUKS header of the encrypted partition
```
sudo cryptsetup -v luksHeaderBackup /dev/nvme1n1p4 --header-backup-file /root/encrypted_partitions_LUKS_backup/LUKSheaderbak_nvme1n1p4_bakhome.bin
```

#### Make it easy mountable by user
Modify
- /etc/fstab
- /etc/crypttab
- /etc/security/pam_mount.conf.xml





### Encrypt /home and pertinent encryption settings
#### Encrypt /home
See [Encrypting the Home Partition on an Existing Linux Installation](https://techblog.dev/posts/2022/03/encrypting-the-home-partition-on-an-existing-linux-installation/)  
and [What is the recommended method to encrypt the home directory in Ubuntu 21.04?](https://askubuntu.com/questions/1335006/what-is-the-recommended-method-to-encrypt-the-home-directory-in-ubuntu-21-04)  

Steps:
```bash
sudo apt install -y libpam-mount
cryptsetup benchmark    # to check for best performance (usually standard)
lsblk   # or 'sudo fdisk -l'  to get a list of partitions

export NEW_HOME_PARTITION=/dev/nvme0n1p4   # check CAREFULLY!!!
sudo umount $NEW_HOME_PARTITION
sudo cryptsetup --cipher aes-xts-plain64 --key-size 512 --hash sha512 -v luksFormat $NEW_HOME_PARTITION    # use same password as at login

sudo umount $NEW_HOME_PARTITION
sudo cryptsetup -v luksOpen $NEW_HOME_PARTITION crypt_home
sudo mkfs -t ext4 -L crypt_home /dev/mapper/crypt_home
sudo lsblk -f /dev/mapper/crypt_home

sudo cryptsetup luksUUID $NEW_HOME_PARTITION
export NEW_PARTITION_UUID=$(sudo cryptsetup luksUUID $NEW_HOME_PARTITION)
echo $NEW_PARTITION_UUID    # check if uuid is retrieved

echo "luks-$NEW_PARTITION_UUID   UUID=$NEW_PARTITION_UUID   none   luks,discard,noauto" | sudo tee -a /etc/crypttab
```

Make backup of LUKS header of the encrypted partition
```bash
sudo cryptsetup -v luksHeaderBackup /dev/nvme0n1p4 --header-backup-file /root/encrypted_partitions_LUKS_backup/LUKSheaderbak_nvme0n1p4_home.bin
```

Logout completely and login as *pure root*:
```bash
# as pure root do:
export NEW_HOME_PARTITION=/dev/nvme0n1p4
sudo cryptsetup -v luksOpen $NEW_HOME_PARTITION crypt_home
sudo mkdir -p /mnt/crypt_home
sudo mount /dev/mapper/crypt_home /mnt/crypt_home
sudo rsync -avP /home/ /mnt/crypt_home/
### sudo rsync -avP /home/.[^.]* /mnt/crypt_home/    # not used
sudo mv -i /home /home_old
sudo mkdir /home
sudo umount /mnt/crypt_home
sudo mount /dev/mapper/crypt_home /home
```

#### Unlock /home at login automatically
See [Unlocking Encrypted Home Partition on Login](https://www.doof.me.uk/2019/09/22/unlocking-encrypted-home-partition-on-login/)

- For auto-mount at login install package `libpam-mount`
  ```bash
  sudo apt install -y libpam-mount
  ```
- Update `/etc/crypttab` to use options `luks,discard,noauto` for the encrypted `/home`
  ```bash
  crypt_home   UUID=b3d517b3-6db0-4210-9c0a-44f0401cc729   none   luks,discard,noauto
  ```
- Get `partuuid` of encrypted partition
  ```bash
  sudo blkid $NEW_HOME_PARTITION
  ```
- Take the `partuuid` and use the path link, e.g.
  ```bash
  /dev/disk/by-partuuid/f0fe94b8-f61a-4433-ac1b-b3abfe530088
  ```
- Modify `/etc/security/pam_mount.conf.xml`, e.g. for user `install`
  ```bash
  <volume user="install" fstype="crypt" path="/dev/disk/by-partuuid/f0fe94b8-f61a-4433-ac1b-b3abfe530088" mountpoint="crypt_home" />
  <volume user="install" fstype="auto" path="/dev/mapper/crypt_home" mountpoint="/home" options="defaults,relatime,discard" />
  <cryptmount>cryptsetup open --allow-discards %(VOLUME) %(MNTPT)</cryptmount>
  <cryptumount>cryptsetup close %(MNTPT)</cryptumount>
  ```

### Create raid1 `/mnt/tinyraid1`
Only user `bank` should automount & decrypt the two partitions on both disks.

See [https://gist.github.com/MaxXor/ba1665f47d56c24018a943bb114640d7](https://gist.github.com/MaxXor/ba1665f47d56c24018a943bb114640d7)  
TODO

### Convert ext4 partition to btrfs
```
sudo fsck -N /dev/mapper/crypt_home          # which version ext2/3/4 is it?
sudo fsck.ext4 -f /dev/mapper/crypt_home     # check partition first
sudo btrfs-convert /dev/mapper/crypt_home
```
Remove suvolume and image file `ext2_saved/image`
```
sudo btrfs subvolume delete /home/ext2_saved
```
Defrag file system
```
sudo btrfs filesystem defrag -v -r -f -t 32M /home 
```
Balance file system
```
sudo btrfs balance start -m /home 
```
Check file system
```
sudo btrfsck --check --force /dev/mapper/crypt_home
```

### Optional: Backup `/home`, create filesystem and copy data back
```bash
sudo cryptsetup luksOpen /dev/nvme0n1p4 crypt_home
sudo cryptsetup luksOpen /dev/nvme1n1p4 crypt_bakhome
sudo mount /dev/mapper/crypt_home /home
sudo mount /dev/mapper/crypt_bakhome /mnt/bakhome
sudo rsync -avP /home/ /mnt/bakhome/
sudo diff -rq /home /mnt/bakhome
sudo rm -rf /mnt/bakhome/ext2_saved
sudo rm -rf /mnt/bakhome/lost+found
sudo umount /home
sudo mkfs.btrfs -L "home" /dev/mapper/crypt_home   # use -f
sudo mount /dev/mapper/crypt_home /home
sudo rsync -avP /mnt/bakhome/ /home/
sudo diff -rq /home /mnt/bakhome
sudo umount /home
sudo umount /mnt/bakhome
```


### Create backup-SAN on NAS
- On NAS use SAN-Manager:
  - Create iSCSI-LUN: `Target-3`  
    ... automatically creates `LUN-3`
  - Result: `iqn.2000-01.com.synology:lanas01.Target-3.b0913d77d79`
- On `mlc5`:
  ```bash
  export IP="192.168.2.5"
  export PORTAL="${IP}:3260"
  export TARGETNAME="iqn.2000-01.com.synology:lanas01.Target-1.46259ce278"
  export TARGETNAME="iqn.2000-01.com.synology:lanas01.Target-2.b0913d77d79"
  export TARGETNAME="iqn.2000-01.com.synology:lanas01.Target-3.b0913d77d79"
  iscsiadm -m discovery -t st -p "${IP}" 
  iscsiadm -m node
  iscsiadm -m node --targetname "${TARGETNAME}" --portal "${PORTAL}" --login
  dmesg # --> find device
  cryptsetup --cipher aes-xts-plain64 --key-size 512 --hash sha512 -v luksFormat /dev/sda
  cryptsetup config --label="crypt_lanas01_bakmlc5" /dev/sda
  cryptsetup luksDump /dev/sda
  cryptsetup -v luksHeaderBackup /dev/sda --header-backup-file /root/encrypted_partitions_LUKS_backup/LUKSheaderbak_lanas01_bakmlc5.bin
  ```
  ```bash
  cryptsetup luksOpen /dev/sda crypt_lanas01_bakmlc5
  mkfs.btrfs -L "lanas01_bakmlc5" /dev/mapper/crypt_lanas01_bakmlc5
  mkdir /mnt/lanas01_bakmlc5
  mount /dev/mapper/crypt_lanas01_bakmlc5 /mnt/lanas01_bakmlc5 
  btrfs fi df /mnt/lanas01_bakmlc5     # just to check systemdata&metadata=DUP
  cd /mnt/lanas01_bakmlc5/
  btrfs subvolume create /mnt/lanas01_bakmlc5/data
  mkdir -p data/mlc05/backup
  mkdir snapshots
  ```
  ```bash
  umount /mnt/lanas01_bakmlc5
  cryptsetup luksClose crypt_lanas01_bakmlc5
  iscsiadm -m node --targetname "${TARGETNAME}" --portal "${PORTAL}" -u
  iscsiadm -m node -o delete -T "${TARGETNAME}"
  iscsiadm -m session
  ```


### Create user accounts
- User ids and names
  - 1000 - install
  - 1001 - www
    ```
    useradd -m -s /bin/bash -G cdrom,audio,dip,plugdev,netdev,bluetooth,lpadmin www
    ```
  - 1002 - fk
    ```
    useradd fk -m -s /bin/bash -G adm,cdrom,audio,dip,video,plugdev,systemd-journal,kvm,netdev,bluetooth,lpadmin,vboxusers
    ```
  - 1003 - bank
    ```
    useradd -m -s /bin/bash -G cdrom,audio,dip,video,plugdev,netdev,bluetooth,lpadmin bank
    ```
- Activate users by setting password for each
  ```
  passwd <username>
  ```
- Make user `install` able to do a `sudo` without password:  
  Use editor `visudo` to edit file `/etc/sudoers`.  
  Add following line **at the end of the file** (otherwise it can be withdrawn by later entries):
  ```
  install ALL=(ALL) NOPASSWD:ALL
  ```
- Update file `/etc/security/pam_mount.conf.xml` for all user accounts,
  see *Unlock /home at login automatically*
- Remark: 
  To enable audio the user must be in group `audio`
- Further helpful commands
  ```
  sudo usermod -a -G video bank   # add user 'bank' to group 'video'
  sudo adduser bank video   # add user 'bank' to group 'video'
  sudo deluser --remove-home --remove-all-files www   # delete user 'www' with all its files
  ```



### Switch user account without password
- Setup overview  
  ```
  fk --> bank
  fk --> www
  ```
- ~~Modify `/etc/sudoers` by using `visudo`~~
- Add lines `/etc/pam.d/su` right after entry `auth  sufficient pam_rootok.so`
  ```
  auth  [success=ignore default=1] pam_succeed_if.so user = bank
  auth  sufficient                 pam_succeed_if.so use_uid user = fk
  auth  [success=ignore default=1] pam_succeed_if.so user = www
  auth  sufficient                 pam_succeed_if.so use_uid user = fk
  ```
- Modify `/etc/pam.d/common-auth` to avoid password request when mounting encrypted partition:  
  add `disable_interactive` in the line right after `pam_mount.so` separated by space(s)
  ```
  auth    optional        pam_mount.so disable_interactive
  ```
- Modify `/etc/pam.d/common-session` to avoid password request when mounting encrypted partition:  
  add `disable_interactive` in the line right after `pam_mount.so` separated by space(s)
  ```
  session optional        pam_mount.so disable_interactive
  ```
Now `su www` or `su bank` should work without any password request for user `fk`



### Setup groups `data`, `users`, `private` and `/data`-folder
```bash
# add users to group 'users'
sudo usermod -aG users install
sudo usermod -aG users www
sudo usermod -aG users fk
sudo usermod -aG users bank
```
```bash
sudo groupadd data   # create group 'data'
sudo usermod -aG data install
sudo usermod -aG data www
sudo usermod -aG data fk
sudo usermod -aG data bank
```
```bash
sudo groupadd private   # create group 'private'
sudo usermod -aG private fk
sudo usermod -aG private bank
```
```bash
sudo mkdir /home/data
sudo chown root:data /home/data
sudo chmod 750 /home/data/
sudo ln -s /home/data /data
```
```bash
sudo mkdir /home/data/documents
sudo chown fk:private /home/data/documents
sudo chmod 750 /home/data/documents
sudo chmod g+s /home/data/documents
```
TODO: define subfolder structure



### Set partition labels
```
findmnt --verify    # verify entries in /etc/fstab
```
```
sudo swaplabel -L "swap" /dev/nvme0n1p5
sudo swaplabel -L "swap" /dev/nvme1n1p6

sudo e2label /dev/mapper/crypt_home home
sudo e2label /dev/nvme0n1p2 root

sudo cryptsetup config --label="crypt_bakmlc4" /dev/nvme1n1p5
sudo cryptsetup config --label="crypt_bakhome" /dev/nvme1n1p4

# sudo btrfs filesystem label /dev/XXX "new label"
```


### Content of modified files
TODO show:  
- /etc/fstab
- /etc/crypttab
- /etc/security/pam_mount.conf.xml



### Install latest python
- Install latest Python version: 
  - Create folder /opt/python
  - Download version `3.12.0` from [python.org/downloads](https://www.python.org/downloads/)
  - `wget https://www.python.org/ftp/python/3.12.0/Python-3.12.0.tgz`
  - Extract in folder `/opt/python` : `tar xzf Python-3.12.0.tgz`
  - Change into `/opt/python/Python-3.12.0` and execute `./configure --prefix=/opt/python --enable-optimizations`
  - Execute `make -s -j4`
  - Execute `make test`
  - Execute `make install`
  - Update `$HOME/.bashrc` (if wanted)  
    `export PATH=/opt/python/Python-3.12.0:/opt/python/bin:$PATH`  
    `export PYTHONPATH=opt/python/Python-3.12.0`
- Upgrade `pip`: `/opt/python/bin/pip3 install --upgrade pip`  
    Check pip-version: `python3 -m pip --version`


### Hide `HPLIPS`-systray icon
- Go into folder `/etc/xdg/autostart`
- Copy file `/etc/xdg/autostart/hplip-systray.desktop` into folder
  `$HOME/.config/autostart/`
- Add following line to file `$HOME/.config/autostart/hplip-systray.desktop`:  
  `Hidden=true`
  


### Create regular snapshots of `/home`
- copy `010_makeSnapshotOfHomeDaily.sh` to `/root/bin/`
- modify root's crontab: `sudo crontab -e`
  ```
  0 * * * * /bin/bash /root/bin/010_makeSnapshotOfHomeDaily.sh
  ```
- The script is executed hourly and 
  only creates a new snapshot if at the current day a snapshot has not been taken yet.












---
---
## User Settings

### Setup for user `root` only
```
ln -s /data/git/Linuxinstall/02_setup_user/HOME_root/makebackup $HOME/makebackup
```


### Desktop / KDE Settings
- Batterymanagement: Long lifetime  
  (Tuxedo Control Center --> Einstellungen --> Akku-Ladeoptionen)  
  Check also BIOS settings - but looks like BIOS does not support any further options.

- Display Scale 100%  
  Hardware --> Anzeige und Monitor --> Anzeige-Einrichtung  
  Globale Skalierung: 100%

- Energymanagement  
  Hardware --> Energieverwaltung --> Energiesparmodus
  - "Am Netzkabel" & "Im Akkubetrieb":  
    - X Bildschirm abdunkeln: Nach 2 Min
    - X Bildschirm-Energieverwaltung: Ausschalten nach 5 Min
    - O Sitzung in den Standby-Modus versetzen
    - O Knopf-Ereignsibehandlung  
  - "Im Akkubetrieb bei niedrigem Ladestand"
    - Keep settings as they are

- Virtual Desktops + Shortcuts  
  - Arbeitsbereich --> Verhalten des Arbeitsbereichs --> Virtuelle Arbeitsfläche  
  4 Virtual Desktops in a row
  - Shortcuts  
    Arbeitsbereich --> Kurzbefehle --> Kurzbefehle --> Systemeinstellungen --> KWin
    - Eine Arbeitsfläche nach links: Meta+Strg+Links, Strg+Alt+Links
    - Eine Arbeitsfläche nach rechts: Meta+Strg+Rechts, Strg+Alt+Rechts

- Quick-switch by mouse at corner/edges  
  Arbeitsbereich --> Verhalten des Arbeitsbereichs --> Bildschirmränder  
  50ms + 100ms
  - left-top: Fenster zeigen - Aktuelle Arbeitsfläche
  - right-bottom: Arbeitsflächen-Umschalter (Raster)

- Desktop background  
  Right-click on Desktop: Arbeitsfläche und Hintergrund einrichten...  
  Select „Zu dunkler Stunde“

- Taskbar / Symbolleiste
  - Settings / Systemeinstellungen
  - Discover
  - Dolphin (Filemanager)
  - Firefox
  - Konsole
  - Visual Studio Code
  - KCalc (Calculator)

- Switch off Bluetooth



### Customize Firefox
- Show menues by right-click on Tabs --> X Menüleiste
- Settings
  - Datenschutz & Sicherheit
    - X Cookies und Website-Daten beim Beenden von Firefox löschen
    - O Fragen, ob Zugangsdaten und Passwörter für Websites gespeichert werden sollen
    - O Kreditkarten automatisch einfügen
    - Chronik
      - Firefox wird eine Chronik `nach benutzerdefinierten Einstellungen anlegen`
      - O Immer den Privaten Modus verwenden
        - O Besuchte Seiten und Download-Chronik speichern
        - O Eingegebene Suchbegriffe und Formulardaten speichern
        - X Die Chronik löschen, wenn Firefox geschlossen wird  
          `Einstellungen` --> Tick all (X)
  - Dateien und Anwendungen
    - Downloads: create sub-folder of this year, e.g. `$HOME/Downloads/2023`



### Execute user setup scripts
Change into folder [02_setup_user](02_setup_user) and execute files
- `010_copy_home_bin_files.sh`
- `020_copy_home_Desktop_files.sh`



### Enable sound for su-users
Multi-User audio sharing works on Pipewire:  
See: [How does Multi-User audio sharing work on Pipewire?](https://www.reddit.com/r/archlinux/comments/s3zn00/how_does_multiuser_audio_sharing_work_on_pipewire/?rdt=57318)  
and: [Migrate PulseAudio --> `module-native-protocol-tcp`](https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Migrate-PulseAudio#module-native-protocol-tcp)

```
mkdir -p $HOME/.config/pipewire/
cp -i /usr/share/pipewire/pipewire-pulse.conf $HOME/.config/pipewire/pipewire-pulse.conf
```
Modify section `libpipewire-module-protocol-pulse` of file `$HOME/.config/pipewire/pipewire-pulse.conf`:
```
vi $HOME/.config/pipewire/pipewire-pulse.conf
```
```
    { name = libpipewire-module-protocol-pulse
        args = {
            server.address = [
                "unix:native"
                "tcp:4713"
            ]
        }
    }
```
Check if `firefox` starts and plays sound:
```
export SU_USER=www
pactl load-module module-native-protocol-tcp
xhost si:localuser:$SU_USER && su $SU_USER sh -c "PULSE_SERVER='tcp:127.0.0.1:4713' firefox "$@""
```
It should start without asking for a password if above configurations were done correctly,  
see section [Switch user account without password](#switch-user-account-without-password).


### Customize Visual Code

- Help --> Welcome
  Choose the look you want: Dark Modern 
- Install extensions for Python and others  
  Press Ctrl+P and type `ext install <extension>`  
  or from command-line `code --install-extension <extension>`
  - Markdownlint (DavidAnson.vscode-markdownlint)
  - Python extension for Visual Studio Code (ms-python.python)
  - Python indent (KevinRose.vsc-python-indent)
  - autoDocstring - Python Docstring Generator (njpwerner.autodocstring)
  - Pylance (ms-python.vscode-pylance) (seems to be already installed by ms-python.python)
  - Pylint (ms-python.pylint)
  - GitLens - Git supercharged (eamodio.gitlens) (if it is really needed?)
  - Markdown Preview Mermaid Support (bierner.markdown-mermaid) for diagrams and flowcharts
  - XML (redhat.vscode-xml)
  - Code Spell Checker (streetsidesoftware.code-spell-checker)
  - Todo Tree (Gruntfuggly.todo-tree)
  - Flake8 (ms-python.flake8)
  - autopep8 (ms-python.autopep8)
  - Black (ms-python.black-formatter)
- Setup / modify settings (`File->Preferences->Settings [Ctrl+,]`):
  - Editor: Format On Save: check-on
  - Editor: Default Formatter: ~~Python (ms-python.python)~~
      Black Formatter(ms-python.black-formatter)
  - Python > Analysis: Type Checking Mode: basic
  - Python Select Interpreter: `./venv/bin/python`
  - Edit `$HOME/.config/Code/User/settings.json`:  

    ```json
    {
        "workbench.colorTheme": "Default Dark Modern",
        "window.zoomLevel": 1,
        "editor.formatOnSave": true,
        "editor.defaultFormatter": "ms-python.black-formatter",
        "python.analysis.typeCheckingMode": "basic",
        "python.defaultInterpreterPath": "./venv/bin/python",
        "editor.rulers": [
            79,
            88,
            100,
            120
        ],
        "redhat.telemetry.enabled": false,
        "[xml]": {
            "editor.defaultFormatter": "redhat.vscode-xml"
        },
        "[python]": {
            "editor.formatOnType": true
        }
    }
    ```

  - Add keyboard shortcut (`File->Preferences->Keyboard Shortcuts [Ctrl+K Ctrl+S]`, `keybindings.json`)
    - `Crtl+RETURN`  Python: Run Python File in Terminal

- Helpful Keyboard Shortcuts (`File->Preferences->Keyboard Shortcuts [Ctrl+K Ctrl+S]`, `keybindings.json`)
  - `Ctrl+Shift+P` to open the Command Palette
  - `Crtl+Shift+7` Fold All Block Comments
  - `Crtl+x`       Remove whole line (if nothing is selected)
  - `Crtl+RETURN`  Python: Run Python File in Terminal (assigned by using `Ctrl+Shift+P`)  


### Setup ssh github access
Using [github's guide to generating SSH keys](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- Check for existing ssh-keys first, then create a new ssh-key
  ```
  ls -al ~/.ssh
  ```
  ```
  ssh-keygen -t ed25519 -C "git@github.com"
  ```
- Login to [github.com](https://github.com)
- Goto [profile-->settings](https://github.com/settings/profile)
- Goto [SSH and GPG keys](https://github.com/settings/keys)
- Add ssh-key to `SSH keys` using the `New SSH key` button  
  - `Title` like "fk at mlc5"
  - use `Key type` = `Authentication Key`  
  - add whole line, i.e. `ssh-ed25519 AA.....MY git@github.com`
  
  ```
  cat ~/.ssh/id_ed25519.pub
  ``` 
- check ssh connection, see [testing-your-ssh-connection](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/testing-your-ssh-connection)
  ```
  ssh -T git@github.com
  ```
  ... should show something like:
  ```
  Hi <UserName>! You've successfully authenticated, but GitHub does not provide shell access.
  ``` 
- Clone this project
  ```
  git clone git@github.com:CastraRegina/Raspinstall.git
  ```
- Specify your git global data (contributor email address)
  ```
  git config --global user.email "castraregina@xyz.net"   # replace by correct email-address, see github-settings
  git config --global user.name "fk"
  ```
  Check setting:
  ```
  git config --global user.email
  ```
- Enjoy the usual git workstyle
  ```
  git status
  git pull
  git add <file>
  git commit -m "message"
  git push
  ```



### VNC setup
- Download [realvnc viewer](https://www.realvnc.com/de/connect/download/viewer/linux/)
  ```
  wget https://downloads.realvnc.com/download/file/viewer.files/VNC-Viewer-7.6.1-Linux-x64.deb
  ```
- Install deb file
  ```
  sudo gdebi VNC-Viewer-7.6.1-Linux-x64.deb
  ```
  

- Start VNC server at remote host
  ```
  sudo systemctl start vncserver-x11-serviced.service
  vncserver-virtual -geometry 1800x1000
  ```
- Connect with vnc viewer using *RealVNC Viewer*   
  Sample settings:  
  - `fxxxxgf.freeddns.org:13031`  
    user: fk
  - `fxxxx11.freeddns.org:13041`  
    user: fk
- Stop VNC server at remote host
  ```
  sudo systemctl stop vncserver-x11-serviced.service
  vncserver-virtual -kill :1
  cat ~/.vnc/*.pid
  ```


### Setup VirtualBox
- Settings "Expert Mode"  
  - Name: ubuntu-22.04.3-BC  
  - Folder: /data/nobackup/VMs  
  - ISO: /data/nobackup/fk/isos/ubuntu-22.04.3-desktop-amd64.iso  
  - Type: Linux
  - Version: Ubuntu-64  
  - RAM: 4096 MB  
  - CPUs: 4
  - HDD: 25GB  
  - HDD-Type: VDI
- Start  
  - User: Install
  - Name: MLC5-VB-ubuntu-22.04.3
- Further Settings VM-Image
  - General -> Advanced -> Shared-Clipboards: bidirectional  (but does not work)
- Settings - Ubuntu  
  - Display: 1920x1440
  - Do a `sudo apt update && sudo apt upgrade`
- Installation
  - [BB-Software](https://bitbox.swiss/de/download/)  
    Check checksum: `sha256sum BB.deb`   
    Install deb-file: `sudo apt install BB.deb`

  


---
---
## HowTos, infos and command examples
- Mount NAS
  ```
  sudo mount -t cifs //192.168.2.5/test /mnt/lanas01_test -o username=test,uid=$(id -u),gid=$(id -g)
  ```

- Remount a filesystem as read/write  
  ```
  sudo mount -o remount,rw /dev/mapper/crypt_bakmlc4 /mnt/bakmlc4
  ```

- List partitions
  ```
  lsblk -o name,mountpoint,label,size,uuid
  ```

- Copy folder recursively using `rsync`
  ```
  time rsync -avP --delete source_path/ destination-path/
  #      with P = --partial --progress 
  ```

- Direct root login at commandline
  - Enable: 
    ```
    sudo -i passwd root
    ```
  - Disable:
    ```
    sudo -i passwd -dl root
    ```

- Rename username
  - Change username from `data` to `install`
    ```
    usermod -l install data
    ```
  - Change groupname from `data` to `install`
    ```
    groupmod -n install data
    ```
  - Change homedir
    ```
    usermod -d /home/install -m install
    ```

- Check health of harddrive
  ```bash
  smartctl --test=short /dev/nvme0n1
  smartctl --test=long  /dev/nvme0n1
  nvme device-self-test -s 1h /dev/nvme0n1  # short
  nvme device-self-test -s 2h /dev/nvme0n1  # long
  smartctl -a /dev/nvme0n1
  smartctl -H /dev/nvme0n1
  nvme list
  nvme smart-log /dev/nvme0n1
  nvme error-log /dev/nvme0n1
  nvme self-test-log /dev/nvme0n1
  nvme endurance-log /dev/nvme0n1  # does not work 
  ```

- Handling `btrfs`
  ```
  btrfs subvolume list /mnt/home
  btrfs subvolume delete /mnt/home/snapshots/snap_20231024_081500
  btrfs subvolume snapshot -r /home /home/snapshots/snap_20231024_081500
  btrfs check --force /dev/mapper/crypt_home
  btrfsck --check --force /dev/mapper/crypt_home
  ```

- Authenticator  
  Commandline tool to generate same output like *google's Authenticator*
  ```
  sudo apt install -y oathtool
  ```
  Example:
  ```
  oathtool --totp -b   qv...yourSecret...p6
  ```

- Backup and restore the LUKS header of the encrypted partition
  ```
  sudo cryptsetup -v luksHeaderBackup  $CRYPT_PARTITION --header-backup-file LuksHeaderBackup.bin
  sudo cryptsetup -v luksHeaderRestore $CRYPT_PARTITION --header-backup-file LuksHeaderBackup.bin
  ```

- Convert utf-8 file (`README.md`) to ascii:
  ```
  cat README.md | iconv -f utf-8 -t ascii//TRANSLIT > output.txt
  ```

### Infos
- Access BIOS and boot menu
  - BIOS: F2 or (ESC)
  - Boot menu: F7 or (Entf)
- Info for `gparted`: 1 GB = 953.6743 MiB

---
---
---

# TODOs / next steps
bank: tinyraid1 + regular snapshots + auto-backup to USB-sticks  
done root: internal backup + regular snapshots  
done root: home regular snapshots  
root: backup to NAS  
fk: VM  

