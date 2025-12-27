# Setting up a development environment

## Fonts
I like a particular monospace font!
```bash
sudo pacman ttf-jetbrains-mono-nerd
mkdir -p ~/.config/fontconfig
cp ./arch_linux/config/fontconfig/fonts.conf ~/.config/fontconfig/
fc-cache -rv
``` 
That should enable JetBrains as the default monospace font.

## OMZ
OMZ install worked perfectly from the command line!

**TODO Resolve the 1-cell Nerd Font icons size**
