#! /bin/zsh

dotfiles=(".wezterm.lua" ".zshrc")
cp "${dotfiles[@]}" ~/

source ~/.zshrc