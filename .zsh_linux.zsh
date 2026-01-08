#! /bin/zsh

# Alias ls to lsd if lsd is installed.
lsd_install_path=~/.cargo/bin/lsd
if [ -f "$lsd_install_path" ]; then
    alias ls="$lsd_install_path"
fi

# Source locally installed applications
export PATH=$HOME/.local/bin:$HOME/applications:$PATH

# Ensure we make a system backup before running a full system upgrade
alias system_update="sudo timeshift --check --scripted && yay -Syu"
