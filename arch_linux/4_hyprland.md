# This is where the ricing truly begins

## Aesthetic Notes

### Color Palette (Gruvbox Material)

The preferred color scheme is based on Gruvbox Material with the following hex values:

**Base Colors:**
| Name | Hex | Notes |
|------|-----|-------|
| Dark Background | `#1D2021` | Primary background, text on accents |
| Off-focus | `#433F3C` | Borders, inactive elements, base for brightness calculations |
| Highlight | `#EBDBB2` | Active indicators|

**Accent Colors:**
| Name | Hex | Notes |
|------|-----|-------|
| Blue | `#427F82` ||
| Yellow | `#D79921` ||
| Red | `#EA6926` ||
| Green | `#689D6A` ||
| Orange | `#E0944F` ||

### Powerline Subversion
I used to powerline a lot in the past, and then I stopped for a few years because I got tired of it. However I'm bringing it back now slowly with some modifications of the original aesthetic.

### Design Patterns

**Typography:**
- Font: JetBrainsMono Nerd Font
- Weight: Normal
- Style: Monospace throughout
- Size: 11

**Interactive Elements:**
- Active elements indicated by highlights (`box-shadow: 0 3px 0 0 #EBDBB2`)

**Solar-Aware Hour Segments:**
A 24-segment hour visualization that:
- Calculates actual sunrise/sunset times based on location coordinates
- Varies segment brightness using a cosine curve peaking at solar noon
- Daytime hours receive a subtle yellow tint
- Current hour highlighted with the `#EBDBB2` highlight color
- Recalculates sun times at midnight

### Visual Principles

1. **Warm earth tones** from Gruvbox palette
2. **Smooth transitions** (300ms standard, 100ms for micro-interactions)
3. **Functional decoration** (hour segments show time progression visually)
4. **Minimal borders** with hover-reveal accents. Prefer a rounded border as well.
5. **Consistent segment padding** (8px horizontal standard where possible)

## Taking screenshots with hyprshot
This is a wrapper around the grim + slurp utilities. Simple install:
```
sudo pacman -S hyprshot
```

## Notifications with Dunst

First I installed dunst and libnotify:
```bash
sudo pacman -S dunst libnotify
```

Dunst is added to Hyprland autostart in `hyprland.lua`:
```lua
hl.exec_cmd("dunst")
```

## Quickshell
The bar is built with [Quickshell](https://quickshell.org), a QtQuick toolkit for desktop shells configured in QML. Its built-in services cover PipeWire audio, MPRIS media, the system tray, desktop entries and Hyprland IPC, and its Hyprland integration keeps up with Hyprland's IPC changes, so no extra libraries are needed:
```bash
sudo pacman -S quickshell
```

The config is copied from `config/quickshell/` to `~/.config/quickshell/`, which `qs` loads by default. It is started from the Hyprland autostart in `hyprland.lua`:
```lua
hl.exec_cmd(logged("quickshell", "qs"))
```

Quickshell reloads the config whenever one of its files changes, and `qs log` prints the running instance's log. To try a config without copying it, run `qs -p <path-to-config-dir>`.

The config is laid out as:
- `shell.qml` — creates one `Bar` per screen
- `Bar.qml` — the panel and its layout
- `components/` — `Theme` (colors, sizes, `fontScale`), Nerd Font `Icons`, and shared widgets
- `modules/` — one file per bar section (workspaces, window title, media, audio, tray, clock, …)
- `services/` — shared state: special workspace, screen recorder, sunrise/sunset times

## System Trash
I decided to use the `trash-cli` package in order to move things to a system trash instead of using `rm` for everything.

## Rofi
I am using rofi as my application launcher as it now has wayland support by default:
```bash
sudo pacman -S rofi rofi-emoji rofi-calc
```
Then the rofi files need to be copied under ~/.config/rofi

## Apple Music with Sidra
For Apple Music on Linux I use [Sidra](https://github.com/wimpysworld/sidra) — a desktop wrapper around `music.apple.com` that exposes proper bi-directional MPRIS at `org.mpris.MediaPlayer2.sidra`. Picked over Cider because Cider hardcodes a 96 kHz `AudioContext` and double-resamples everything through a DSP chain; Sidra leaves audio untouched.
```bash
yay -S sidra-bin
```
Why this matters for the bar: Apple Music inside Firefox/Chromium exposes MPRIS via the browser's MediaSession bridge, and music.apple.com's MediaSession implementation is buggy — `nexttrack`/`previoustrack` handlers stop playback instead of advancing, and `setPositionState` reports `mpris:length` inconsistently (sometimes `-1`, sometimes the wrong units). Sidra owns the player state directly, so the bar's media skip buttons and track-progress line actually work.
