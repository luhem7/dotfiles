# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles for an Arch Linux environment with Hyprland (Wayland), Neovim, zsh, and gaming support. Includes both configuration files and setup documentation.

## Key Commands

### Dotfile Management
```bash
./manage_dotfiles.sh deploy   # Deploy dotfiles from repo to home directory
./manage_dotfiles.sh commit   # Pull dotfiles from home back into repo
```

### Utilities
```bash
./hypr-binds                  # Display Hyprland keybindings in readable format
./commit-push-changes.sh      # Automated git commit and push
```

## Repository Structure

- **Root level**: Shell configs (`.zshrc`, `.zsh_linux.zsh`, `.zsh_macos.zsh`), terminal config (`.wezterm.lua`), git config, plus the `manage_dotfiles.sh`, `hypr-binds`, `commit-push-changes.sh`, and `npm-supply-chain-scanner.sh` (read-only scanner for npm / Claude Code backdoors and the Atomic Arch AUR campaign, incl. nvim plugin sweep and a `--preview-aur` pre-upgrade PKGBUILD diff check) helpers
- **`vscode/`**: VSCode `settings.json`
- **`arch_linux/`**: Numbered setup guides plus all Arch-specific configs, polkit rules, kernel params, and utility scripts. See guide breakdown below.

### `arch_linux/` — setup guides

The numbered markdown files are meant to be read in order; they document a from-scratch install rather than being scripts to execute.

- **`Readme.md`** — Why-Arch intro and the "read the numbered files in order" pointer.
- **`0_init_install.md`** — Bare-metal install: USB boot, ethernet/DHCP, LUKS full-disk encryption (`/boot` + encrypted root), `mkinitcpio` with `sd-encrypt`, Unified Kernel Image setup, `efibootmgr` boot entry, root password, wheel-group user, `faillock` tweaks. Has a recovery-via-chroot aside.
- **`1_userland.md`** — Post-install as the primary user: `systemd-networkd`/`resolved` (with mDNS drop-in), NVIDIA (`nvidia-open`, early KMS, `nvidia-drm.modeset=1`), passwordless suspend via polkit, the s2idle-fallback freeze fix (`SuspendState=mem`), Hyprland + Hyprlock/Hypridle bootstrap, PipeWire/WirePlumber audio (incl. Schiit Magni Unity stuck-relay mute workaround via `audio-mute-toggle.sh`), `yay`, Timeshift backups.
- **`2_dev.md`** — Dev environment: JetBrainsMono Nerd Font + fontconfig, zsh plugins (syntax highlighting, autosuggestions), Ghostty config, VirtualBox, Podman (with `crun`), Node via `nvm`, Neovim + Lazy + `tree-sitter-cli` + `wl-clipboard`, and modern CLI replacements (`lsd`, `bat`, `ripgrep`, `fzf`, `btop`, `dust`, `procs`, `yazi` w/ toggle-pane plugin).
- **`3_gaming.md`** — Steam, locking the monitor to 3440x1440@164.9Hz in Hyprland, `gamescope` + `gamemode` install/group setup, and the recommended Steam per-game launch command.
- **`4_hyprland.md`** — Ricing/aesthetics: Gruvbox Material palette (with exact hex values), typography rules, design principles, solar-aware hour-segment concept, Dunst notifications, AGS (Aylur's GTK Shell) + Astal tray/wireplumber libs, `trash-cli`, and Rofi (with `rofi-emoji` and `rofi-calc`).
- **`tips_and_tricks.md`** — Standalone (unnumbered) notes on techniques worth remembering, written in first person. Currently: using `systemd-cat` to recover logs from processes Hyprland spawns (it redirects their stdout/stderr to `/dev/null`).

### `arch_linux/config/` — application configs (deployed to `~/.config/`)

- `ags/` — Aylur's GTK Shell (bar/widgets)
- `dunst/` — notification daemon
- `fontconfig/` — fonts.conf (JetBrainsMono as default monospace)
- `ghostty/` — Ghostty terminal
- `hypr/` — Hyprland window manager (`hyprland.lua`, `hyprlock.conf`, `hypridle.conf`)
- `kitty/` — Kitty terminal
- `nvim/` — Neovim with Lazy plugin manager (`lua/config/lazy.lua`)
- `rofi/` — Rofi application launcher
- `swayimg/` — image viewer
- `wireplumber/` — PipeWire session manager config snippets (e.g. deprioritize HDMI/optical outputs)
- `yazi/` — terminal file manager
- `gamemode.ini` — Feral GameMode config (lives at `~/.config/gamemode.ini`, not a subdir)

### Other `arch_linux/` subdirs

- **`arch_linux/polkit/`** — Polkit rules. `10-enable-suspend-wheel.rules` allows wheel-group passwordless suspend.
- **`arch_linux/utils/`** — Scripts and systemd units:
  - `audio-mute-toggle.sh` — workaround for Schiit Magni Unity stuck mute relay (profile bounce on unmute)
  - `fix_lens.zsh` — webcam/lens fix utility
  - `restart-blue-mic.sh` + `restart-blue-mic.service` — systemd unit to recover the Blue mic when it gets wedged
- **`arch_linux/kernel_params/`** — currently empty; reserved for kernel cmdline drop-ins (the live ones documented in the guides live under `/etc/cmdline.d/`).
- **`arch_linux/.claude/`** — Claude Code project metadata.

## Architecture Notes

- Cross-platform support: `.zshrc` sources OS-specific files (`.zsh_linux.zsh` or `.zsh_macos.zsh`)
- Machine-specific overrides: `.zshrc` sources `~/.local_config.zsh` if present
- VSCode paths handled per-OS in `manage_dotfiles.sh`
- Neovim uses Lazy plugin manager with config in `lua/config/lazy.lua`

## Hardware Context

- GPU: NVIDIA GeForce 4080 (nvidia-open driver)
- Monitor: 3440x1440@164.9Hz ultrawide
- Gaming: Steam with Gamescope/Gamemode
