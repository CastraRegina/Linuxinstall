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
```
sudo apt update && sudo apt upgrade -y
```
```
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


### Configure editor
Select `/usr/bin/vim.basic`
```
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
TODO



### Encrypt /home and pertinent encryption settings
#### Encrypt /home
See [Encrypting the Home Partition on an Existing Linux Installation](https://techblog.dev/posts/2022/03/encrypting-the-home-partition-on-an-existing-linux-installation/)  
and [What is the recommended method to encrypt the home directory in Ubuntu 21.04?](https://askubuntu.com/questions/1335006/what-is-the-recommended-method-to-encrypt-the-home-directory-in-ubuntu-21-04)  

Steps:
```
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
Logout completely and login as *pure root*:
```
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
  ```
  sudo apt install -y libpam-mount
  ```
- Update `/etc/crypttab` to use options `luks,discard,noauto` for the encrypted `/home`
  ```
  crypt_home   UUID=b3d517b3-6db0-4210-9c0a-44f0401cc729   none   luks,discard,noauto
  ``` 
- Get `partuuid` of encrypted partition
  ```
  sudo blkid $NEW_HOME_PARTITION
  ```
- Take the `partuuid` and use the path link, e.g.
  ```
  /dev/disk/by-partuuid/f0fe94b8-f61a-4433-ac1b-b3abfe530088
  ```
- Modify `/etc/security/pam_mount.conf.xml`, e.g. for user `install`
  ```
  <volume user="install" fstype="crypt" path="/dev/disk/by-partuuid/f0fe94b8-f61a-4433-ac1b-b3abfe530088" mountpoint="crypt_home" />
  <volume user="install" fstype="auto" path="/dev/mapper/crypt_home" mountpoint="/home" options="defaults,relatime,discard" />
  <cryptmount>cryptsetup open --allow-discards %(VOLUME) %(MNTPT)</cryptmount>
  <cryptumount>cryptsetup close %(MNTPT)</cryptumount>
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



### Setup group `data` and `/data` folder
```
sudo groupadd data   # create group 'data'
sudo usermod -aG data install
sudo usermod -aG data www
sudo usermod -aG data fk
sudo usermod -aG data bank
```
```
sudo mkdir /home/data
sudo chown root:data /home/data
sudo chmod 750 /home/data/
sudo ln -s /home/data /data
```
TODO: define subfolder structure




---
---
## User Settings
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
- Add extensions for Python
  - TODO



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
  - `fxxxxxf.freeddns.org:13031`  
    user: fk
  - `fxxxxx1.freeddns.org:13041`  
    user: fk
- Stop VNC server at remote host
  ```
  sudo systemctl stop vncserver-x11-serviced.service
  vncserver-virtual -kill :1
  cat ~/.vnc/*.pid
  ```


---
---
## HowTos, infos and command examples
- Mount NAS
  ```
  sudo mount -t cifs //192.168.2.5/test /mnt/lanas01_test -o username=test,uid=$(id -u),gid=$(id -g)
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

- Authenticator  
  Commandline tool to generate same output like *google's Authenticator*
  ```
  sudo apt install -y oathtool
  ```
  Example:
  ```
  oathtool --totp -b   qv...yourSecret...p6
  ```


- Find and replace special chars in txt-file  
  TODO


### Infos
- Access BIOS and boot menu
  - BIOS: F2 or (ESC)
  - Boot menu: F7 or (Entf)
- Info for `gparted`: 1 GB = 953.6743 MiB
