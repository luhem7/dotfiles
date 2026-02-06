# Setting up a development environment

## Fonts
I like a particular monospace font!
```bash
sudo pacman -S ttf-jetbrains-mono-nerd
mkdir -p ~/.config/fontconfig
cp ./arch_linux/config/fontconfig/fonts.conf ~/.config/fontconfig/
fc-cache -rv
``` 
That should enable JetBrains as the default monospace font.

## Zsh plugins
Install syntax highlighting and autosuggestions for a better shell experience:
```bash
sudo pacman -S zsh-syntax-highlighting zsh-autosuggestions
```
The `.zshrc` in this repo will automatically source these if installed.

## Configuring Kitty
Kitty was installed earlier. We just need to copy over the config files and restart kitty.
```
cp ./arch_linux/config/kitty/*.conf ~/.config/kitty/
```
Then press Ctrl + Shift + F5

## Virtualbox
I started with the [Arch VirtualBox page](https://wiki.archlinux.org/title/VirtualBox)

```bash
sudo pacman -S virtualbox virtualbox-host-modules-arch
```
Then to load the virtual box module manually the first time (and apparently systemd-modules-load.service will load them subsequently)
```bash
sudo modprobe vboxdrv
```
Adding myself to the vboxusers user group to use the USB devices of my host
```bash
sudo usermod vboxusers -aG $(whoami)
```
Then, I rebooted.

## Installing node and npm
I did not install the arch linux nodejs and npm packages. I just installed and used the arch linux package instead:
```bash
sudo pacman -S nvm
```
Then it just worked right off the bat.

## Installing nvim
```bash
sudo pacman -S neovim
```
Then, I followed the instructions [here](https://lazy.folke.io/installation) to install the `lazy.vim` plugin manager.

## Useful packages

### lsd
A modern replacement for `ls` with colors and icons.
```bash
sudo pacman -S lsd
```
The `.zsh_linux.zsh` config will automatically alias `ls` to `lsd` if installed.

### bat
A `cat` replacement with syntax highlighting and line numbers.
```bash
sudo pacman -S bat
```

### ripgrep
A faster `grep` replacement with sane defaults, respects .gitignore.
```bash
sudo pacman -S ripgrep
```
Use with `rg <pattern>`.

### fzf
Fuzzy finder for files, command history, and more.
```bash
sudo pacman -S fzf
```
Press `Ctrl+R` for fuzzy history search.

### btop
Beautiful terminal-based process/resource monitor.
```bash
sudo pacman -S btop
```

### dust
A more intuitive `du` replacement with visual directory tree.
```bash
sudo pacman -S dust
```

### procs
A modern `ps` replacement with color output and search.
```bash
sudo pacman -S procs
```

### yazi
Fast terminal file manager with image preview support.
```bash
sudo pacman -S yazi
```

#### yazi plugins
I installed a plugin to maximize / minimize the preview window pane
```bash
ya pkg add yazi-rs/plugins:toggle-pane
```
