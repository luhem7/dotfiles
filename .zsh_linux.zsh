#! /bin/zsh

alias nvim='flatpak run io.neovim.nvim'

alias popos_upgrade_all='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && flatpak update -y'

# Alias ls to lsd if lsd is installed.
lsd_install_path=~/.cargo/bin/lsd
if [ -f "$lsd_install_path" ]; then
    alias ls="$lsd_install_path"
fi

# Source locally installed applications
export PATH=$HOME/.local/bin:$HOME/applications:$PATH