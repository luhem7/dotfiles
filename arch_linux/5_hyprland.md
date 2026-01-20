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

## System Trash
I decided to use the `trash-cli` package in order to move things to a system trash instead of using `rm` for everything.

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
- Weight: Bold
- Style: Monospace throughout

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
