# This is where the ricing truely begins

## Notifications with Dunst

First I installed dunst and libnotify:
```bash
sudo pacman -S dunst libnotify
```

Dunst is added to Hyprland autostart in `hyprland.conf`:
```bash
exec-once = dunst
```

## Installing AGS
I installed AGS via yay:
```bash
yay -S aylurs-gtk-shell
```

### AGS Bar Configuration
The AGS bar configuration lives in `~/.config/ags/` with the following structure:
