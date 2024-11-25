#! /bin/zsh

alias nvim='flatpak run io.neovim.nvim'

# Alias ls to lsd if lsd is installed.
lsd_install_path=~/.cargo/bin/lsd
if [ -f "$lsd_install_path" ]; then
    alias ls="$lsd_install_path"
fi

# Source locally installed applications
export PATH=$HOME/.local/bin:$HOME/applications:$PATH