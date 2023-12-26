#! /bin/zsh

# Alias ls to lsd if lsd is installed.
if command -v lsd &> /dev/null; then
    alias ls=lsd
fi
