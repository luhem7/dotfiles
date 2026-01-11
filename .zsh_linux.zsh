#! /bin/zsh

# Alias ls to lsd if lsd is installed.
if command -v lsd &> /dev/null; then
    alias ls=lsd
fi

# Source locally installed applications
export PATH=$HOME/.local/bin:$HOME/applications:$PATH

# Ensure we make a system backup before running a full system upgrade
alias system_update="sudo timeshift --check --scripted && yay -Syu"
