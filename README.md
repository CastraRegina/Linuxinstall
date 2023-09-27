# Linuxinstall
Personal guide to installing and setting up a Linux laptop


## System Settings
TODO

### Execute system setup scripts
TODO

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