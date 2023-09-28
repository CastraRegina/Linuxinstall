# Linuxinstall
Personal guide to installing and setting up a Linux laptop


## System Settings
TODO

### Execute system setup scripts
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



### Execute user setup scripts
TODO



### Enable sound for su-users
Multi-User audio sharing work on Pipewire:  
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
Check it:
```
export SU_USER=www
pactl load-module module-native-protocol-tcp
xhost si:localuser:$SU_USER && sudo -u $SU_USER sh -c "PULSE_SERVER='tcp:127.0.0.1:4713' firefox "$@""
```
```
export SU_USER=www
pactl load-module module-native-protocol-tcp
xhost si:localuser:$SU_USER
su -s /bin/bash -c "PULSE_SERVER='tcp:127.0.0.1:4713' firefox" $SU_USER
```



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
- Specify your git global data
  ```
  git config --global user.email "git@github.com"
  git config --global user.name "fk"
  ```
- Enjoy the usual git workstyle
  ```
  git status
  git pull
  git add <file>
  git commit -m "message"
  git push
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

- Find and replace special chars in txt-file  
  TODO


### Infos
- Access BIOS and boot menu
  - BIOS: F2 or (ESC)
  - Boot menu: F7 or (Entf)
- Info for `gparted`: 1 GB = 953.6743 MiB
