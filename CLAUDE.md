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

- **Root level**: Shell configs (`.zshrc`, `.zsh_linux.zsh`, `.zsh_macos.zsh`), terminal configs (`.wezterm.lua`), git config
- **`arch_linux/`**: Numbered setup guides (0-5) documenting system installation from scratch
- **`arch_linux/config/`**: Application configs meant for `~/.config/`:
  - `hypr/` - Hyprland window manager (hyprland.conf, hyprlock.conf, hypridle.conf)
  - `nvim/` - Neovim with Lazy plugin manager
  - And more are constantly being added.
- **`arch_linux/polkit/`**: Polkit rules (e.g., passwordless suspend)
- **`arch_linux/utils/`**: System utility scripts and services
- **`vscode/`**: VSCode settings.json

## Architecture Notes

- Cross-platform support: `.zshrc` sources OS-specific files (`.zsh_linux.zsh` or `.zsh_macos.zsh`)
- Machine-specific overrides: `.zshrc` sources `~/.local_config.zsh` if present
- VSCode paths handled per-OS in `manage_dotfiles.sh`
- Neovim uses Lazy plugin manager with config in `lua/config/lazy.lua`

## Hardware Context

- GPU: NVIDIA GeForce 4080 (nvidia-open driver)
- Monitor: 3440x1440@164.9Hz ultrawide
- Gaming: Steam with Gamescope/Gamemode
