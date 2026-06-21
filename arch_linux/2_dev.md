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

## Configuring Ghostty
Ghostty was installed earlier. We just need to copy over the config files and restart ghostty.
```
cp ./arch_linux/config/ghostty/* ~/.config/ghostty/
```

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
sudo usermod -aG vboxusers $(whoami)
```
Then, I rebooted.

## Podman
I went with [Podman](https://wiki.archlinux.org/title/Podman) over Docker because it runs daemonless and supports rootless containers out of the box.

```bash
sudo pacman -S podman
```
When prompted for an OCI runtime, select `crun` — it's Podman's default runtime, written in C, lighter and faster than `runc`, with excellent rootless support.

Verify the install:
```bash
podman info
podman run --rm hello-world
```

## Installing node and npm
I did not install the arch linux nodejs and npm packages. I just installed and used nvm instead:
```bash
sudo pacman -S nvm
```
Then it just worked right off the bat.

### Hardening npm against supply-chain attacks
Through 2025–2026 there was a wave of npm supply-chain worms (the "Miasma" /
TeamPCP / "Shai-Hulud" campaigns) that hijack maintainer accounts, publish
poisoned package versions, and run a payload **during `npm install`** via
`preinstall` hooks or a weaponized `binding.gyp`. The payload steals every
credential it can find and plants persistence inside editor configs
(`~/.claude/settings.json` SessionStart hooks, `.vscode/tasks.json`), so it
survives uninstalling the package.

The single highest-leverage defense is to stop install-time scripts from running
automatically:
```bash
npm config set ignore-scripts true   # writes ~/.npmrc
```
**Trade-off:** this also blocks *legitimate* native builds (`node-gyp`, `esbuild`,
`sharp`, `@parcel/watcher`, …), so those packages may not compile their binaries.
When you trust a specific package and need its build step, opt in per-install:
```bash
npm install <pkg> --foreground-scripts   # runs scripts, but shows their output
```
`~/.npmrc` is **not** tracked in this repo (it's in `.gitignore`) because it can
hold registry auth tokens and this repo is public — set it locally per machine.

Other hygiene worth keeping: commit your `package-lock.json`, use `npm ci`
(not `npm install`) in CI, and wait a few days before adopting brand-new
package releases — most malicious versions are caught within hours.

### Checking for compromise
`npm-supply-chain-scanner.sh` (repo root) is a **read-only** scanner for the
indicators of the campaigns above: malicious editor hooks, planted persistence
files, weaponized `binding.gyp`, affected packages in lockfiles, known-bad
hashes, and C2 network indicators. It also covers the **Atomic Arch** AUR
campaign (pacman history, yay/paru build caches, eBPF rootkit maps, systemd
persistence) and sweeps the nvim (lazy.nvim) plugin tree for the same IOCs. It
never deletes or modifies anything — if it finds something it prints the safe
remediation order (disconnect → clean by hand → rotate secrets **from a
different, trusted machine**, since the malware retaliates against revocation).
```bash
./npm-supply-chain-scanner.sh            # scans $HOME
./npm-supply-chain-scanner.sh ~/workspace # or specific project dirs (faster)
sudo HOME="$HOME" ./npm-supply-chain-scanner.sh  # full coverage (/sys/fs/bpf) while keeping your caches in scope
./npm-supply-chain-scanner.sh --preview-aur  # diff pending AUR upgrades BEFORE yay -Syu
```

## Installing nvim
```bash
sudo pacman -S neovim
```
Then, I followed the instructions [here](https://lazy.folke.io/installation) to install the `lazy.vim` plugin manager.

### tree-sitter-cli
Required by `nvim-treesitter` to compile language parsers when running `:TSInstall <lang>` or `:TSUpdate`. Without it, `:checkhealth nvim-treesitter` reports `tree-sitter-cli not found` and parser installs fail.
```bash
sudo pacman -S tree-sitter-cli
```

### wl-clipboard
Needed for nvim's `unnamedplus` clipboard integration to share yanks with the Wayland system clipboard. `init.lua` only enables system-clipboard sharing when `wl-copy` is on PATH.
```bash
sudo pacman -S wl-clipboard
```

### Markdown rendering (render-markdown.nvim)
The `render-markdown.nvim` plugin renders Markdown directly in the buffer. LaTeX math rendering needs a converter to turn formulas into unicode:
```bash
sudo pacman -S python-pylatexenc
```
It also relies on a few treesitter parsers — install them once from inside nvim:
```vim
:TSInstall markdown markdown_inline latex html yaml
```

### Completion and language servers
Completion comes from `blink.cmp`, which compiles a Rust fuzzy matcher on install (see [Installing Rust](#installing-rust) below — without it, blink warns once and falls back to a slower pure-Lua matcher).

The intelligence (autocomplete, diagnostics, go-to-definition) comes from language servers. Install the ones for languages you actually use — the nvim config only enables servers whose binary is present on PATH, so a partial install (or a different machine) won't produce errors.
```bash
sudo pacman -S lua-language-server rust-analyzer pyright \
               typescript-language-server typescript \
               bash-language-server shellcheck shfmt
```
`shellcheck` and `shfmt` back the bash server's diagnostics and formatting. The HTML, CSS, and JSON servers ship together in a single AUR package:
```bash
yay -S vscode-langservers-extracted
```

## Installing Rust
Instructions [here](https://wiki.archlinux.org/title/Rust). I went ahead and installed rustup:
```bash
sudo pacman -S rustup
```
and then installed the latest stable rust toolchain (includes cargo):
```bash
rustup toolchain install stable
```


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
