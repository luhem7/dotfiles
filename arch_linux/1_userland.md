# Userland setup
Unlike the previous article, here everything happens while logged in as the primary user (and not root)

## Networking setup
Jumping forward a bit, we go to **7. Networking** on the [General Recommendations Guide](https://wiki.archlinux.org/title/General_recommendations)

First I went through the setup guide for [systemd-networkd](https://wiki.archlinux.org/title/Systemd-networkd). In particular, I created a link so that networkd could manage my ethernet connection:
```bash
ln -s /usr/lib/systemd/network/89-ethernet.network.example /etc/systemd/network/89-ethernet.network
```

Then, I went to [Network Configuration](https://wiki.archlinux.org/title/Network_configuration).


There are a number of recommendations here, but the only things that I had to do was enable the [systemd-networkd.service](https://wiki.archlinux.org/title/Systemd-networkd) and the [systemd-resolved.service](https://wiki.archlinux.org/title/Systemd-resolved)

```bash
sudo systemctl enable systemd-networkd.service
sudo systemctl enable systemd-resolved.service
```

In addition "To provide domain name resolution for software that reads /etc/resolv.conf directly, such as web browsers, Go, GnuPG and QEMU when using user networking", I made the following link:

```bash
ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

### Enabling mDNS for .local hostname resolution
mDNS is needed to resolve `.local` hostnames on the LAN (e.g., `raspberrypi.local`). Create a drop-in override so it doesn't get overwritten on upgrades:
```bash
sudo mkdir -p /etc/systemd/network/89-ethernet.network.d
sudo vim /etc/systemd/network/89-ethernet.network.d/mdns.conf
```
Add the following lines:
```ini
[Network]
MulticastDNS=yes
```
Then restart networkd:
```bash
sudo systemctl restart systemd-networkd
```

**TODO** Setup firewalls here when you decide to open up this system to LAN.



## nVidia Setup
Picking up where we left off, we continue to follow the [General Recommendations Guide](https://wiki.archlinux.org/title/General_recommendations) continuing from the **4 Graphical user interface** section.

Wayland comes installed by default.

[This is](https://wiki.archlinux.org/title/NVIDIA) the main article for nVidia. 
For my GeForce 4080, it was enough to install the `nvidia-open` package. This should also include `nvidia-utils` along with it.

**Ensuring CONFIG_DRM_SIMPLEDRM=y**
Run this command that searches for the config key in `/proc/config.gz` (which has the kernel's config file):
```bash
zgrep CONFIG_DRM_SIMPLEDRM /proc/config.gz
```

Then, do a reboot before going to the next section

**Ensure DRM is enabled**

`cat /sys/module/nvidia_drm/parameters/modeset` should output Y

**Early KMS**

At this point to support early module loading of the nvidia modules, I modified the `/etc/mkinitcpio.conf` as so:
1. Added the following to the modules parameter:
```
MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
```
2. Removed `kms` from the hooks parameter

After that, I added the following additional kernel parameters to optimize the boot experience:
```bash
sudo echo "rw loglevel=3 quiet nvidia-drm.modeset=1 nvidia_drm.fbdev=1" > /etc/cmdline.d/51-early-kms.conf
```
> rw - skip kernel fsck, not needed for ext4 format
> loglevel=3 quiet - Print only errors or worse
> nvidia-drm.modeset=1 : Tell graphics driver to take over the display immediately 
> nvidia_drm.fbdev=1 : Provides a proper Linux framebuffer device, to help eliminate a black gap during KMS switch over.

Then regenerated the initramfs using `sudo mkinitcpio -P`

**Testing nVidia setup**

At this point, I restarted just to ensure that the drivers were loading up right. It was also at this point that suspending and resuming the system worked stably via `sudo systemctl suspend`.

Running `nvidia-smi` should print my current GPU name and VRAM usage.

There's also a neat utility called `nvtop` that works like `htop` but for nVidia GPU utilization!

**TODO** Lots of good recommendations on this page, particularly around limiting vram usage for certain applications. See section **2.3 nvidia-application-profiles.rc.d** in [this section](https://wiki.archlinux.org/title/NVIDIA#Wayland_configuration)


## Allowing system suspend without needing password
Do these steps at this point for sanity's sake.
```bash
sudo cp ./arch_linux/polkit/10-enable-suspend-wheel.rules /etc/polkit-1/rules.d/10-enable-suspend-wheel.rules
sudo chown root:polkitd /etc/polkit-1/rules.d/10-enable-suspend-wheel.rules
sudo chmod 644 /etc/polkit-1/rules.d/10-enable-suspend-wheel.rules
sudo systemctl reload polkit
```

## Fixing suspend freeze with NVIDIA and s2idle fallback
On systems with NVIDIA GPUs, a failed S3 (deep) suspend can cause the system to fall back to s2idle (modern standby), which often results in a complete system freeze requiring a hard reboot.

**The problem:** When suspend fails (e.g., due to a USB device being busy), Linux falls back to s2idle. The NVIDIA driver doesn't handle s2idle well, causing the system to hang.

**Diagnosis:** Check previous boot logs for suspend failures:
```bash
journalctl -b -1 --priority=0..3 --no-pager | tail -100
```
Look for errors like:
```
xhci_hcd 0000:00:14.0: PM: failed to suspend async: error -16
PM: Some devices failed to suspend, or early wake event detected
PM: suspend entry (s2idle)
```

**The fix:** Disable s2idle fallback so failed suspends fail cleanly instead of freezing:
```bash
sudo mkdir -p /etc/systemd/sleep.conf.d
echo -e "[Sleep]\nSuspendState=mem" | sudo tee /etc/systemd/sleep.conf.d/no-s2idle.conf
```

This forces systemd to only use S3 (deep) sleep. If S3 fails, the suspend aborts cleanly rather than falling back to s2idle. No reboot required.

## Preserving VRAM across suspend

Forcing S3 (above) means the GPU loses power during sleep, so anything held in VRAM is discarded and has to be rebuilt on resume.

**The catch:** `NVreg_PreserveVideoMemoryAllocations` already defaults to `1`, but that only declares the intent. The actual save/restore is done by systemd units shipped with `nvidia-utils`, and those are disabled by default.

**The fix:**
```bash
sudo systemctl enable nvidia-suspend.service nvidia-resume.service nvidia-hibernate.service
```

`nvidia-suspend.service` runs before `systemd-suspend.service` and dumps VRAM to `NVreg_TemporaryFilePath` (`/var/tmp`, which is on the encrypted root here). `nvidia-resume.service` restores it on wake.

**Tradeoff:** the dump goes to disk, so suspend time scales with how much VRAM is in use. An idle desktop (~1 GiB) costs a couple of seconds. A game or a local LLM holding 10–20 GiB can take tens of seconds and look like the machine has hung — it hasn't, it's still writing. That is also the case where preservation is most worth having, since the alternative is reloading all of it on resume.

## Setting up a Desktop
I'm currently going with the [hyprland eco-system](https://wiki.archlinux.org/title/Hyprland). As noted on the page, it is good to take a look at the [Hyprland Nvidia page](https://wiki.hypr.land/Nvidia/), but I had already implemented the recommendations here!

Hyprland 0.55 deprecated the old hyprlang `hyprland.conf` format in favour of Lua, and no longer ships a sample `hyprland.conf` at all. `hyprland.lua` is the only config this setup uses.

Next, I copied a default Hyprland config over to my user config:
```bash
cp /usr/share/hypr/hyprland.lua ~/.config/hypr/hyprland.lua
```
and then I added the following lines to the top of that file
```lua
hl.env("LIBVA_DRIVER_NAME",         "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
```
But really, this is already present in the included hyprland config in this repo.

Along with installing Hyprland I had to install the following mandatory and highly recommended packages:

```bash
sudo pacman -S pipewire wireplumber wiremix hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk hyprpolkitagent ghostty dolphin wofi firefox qt5-wayland qt6-wayland noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-jetbrains-mono-nerd dunst libnotify
```

After this, I also followed the installation guide on [their official website](https://wiki.hypr.land/Getting-Started/Master-Tutorial/)

I believe that I'm supposed to be starting Hyprland via usm, but I'm happy enough starting it manually by typing `start-hyprland` on the command line after login!

**Locking the screen before going to sleep**
Hyprlock takes care of locking the screen and Hypridle is a idle management daemon that takes care of firing off events related to the desktop being idle or going to sleep.

First, copy over the config files in this repo to `~/.config/hypr/`. Then install the required packages. It is important that we copy over the config files first as hyprlock might just draw a blank screen instead of actually creating a password widget I can use to unlock the system!
```
sudo pacman -S hyprlock hypridle
```
Logout of the desktop and login to verify that these changes have taken effect.

**Where hypridle runs from, and where to find its logs**

hypridle is started by Hyprland itself, from the autostart section of `hyprland.lua`. That is the correct choice for this setup: the wiki only recommends `systemctl --user enable --now hypridle.service` when Hyprland is launched through uwsm, and this machine starts it manually with `start-hyprland` instead.

Hyprland does not forward stdout or stderr from the processes it spawns — it points them at `/dev/null`. Left alone, hypridle's logs are therefore discarded completely: not in the journal, not in `hyprland.log`, nowhere. Since those logs are the only way to debug the lock-before-sleep path, pipe it through `systemd-cat` so its output lands in the journal under its own tag:
```lua
hl.exec_cmd("systemd-cat -t hypridle hypridle")
```
```bash
journalctl -t hypridle -f
```

Do not use `systemctl --user start hypridle` to pick up a config change. That launches a *second* daemon alongside the one Hyprland already spawned, and both will hold sleep inhibitors and fire their own lock commands, which breaks locking in confusing ways. To reload the config, replace the running instance:
```bash
pkill hypridle
hyprctl dispatch 'hl.dsp.exec_cmd("systemd-cat -t hypridle hypridle")'
```



## Sound
This section is something I need to refine. What I found is that arch was able to successfully detect my audio device, but it didn't make it the default. I'm currently targetting using [pipewire](https://wiki.archlinux.org/title/PipeWire) and [wireplumber](https://wiki.archlinux.org/title/WirePlumber) for all of the sound management and trying not to use pulse audio as much as possible.

First, I wanted to lower the priority of my motherboard's optical and HDMI outputs. I wrote the necessary configuration user directory + snippets under `./config/wireplumber/` that should be copied to the corresponding directory structure in the home directory. Notably, I had to ensure that I was using configuration snippets in the `wireplumber.conf.d` directory because if I supplied just a single configuration file, it never read the global configuration file and wireplumber fails to start!

After copying the config snippets, we can restart the service (which is running at the user level!) and check the status as so:
```bash
systemctl --user start wireplumber
systemctl --user status wireplumber
```
If the service fails to start use the following command to check what failed `journalctl --user -u wireplumber -n 50`. After fixing the issue, the systemctl failure status flag needs to be reset before restarting the service: `systemctl --user reset-failed wireplumber`

We can run `speaker-test -c 2 -l 1` to play a sound through the front stereo speakers to see if the settings are working.

### `pipewire-alsa` — don't skip it, or ALSA-only apps break
Installing `pipewire`, `pipewire-audio` and `pipewire-pulse` is *not* enough. Anything that talks raw ALSA rather than pulse will fail to open the default device:
```
speaker-test -D default
  → Playback open error: -2,No such file or directory
```
...while `speaker-test -D pipewire` and `-D pulse` both work fine. That split is the tell: the sound stack is healthy, but ALSA's `default` PCM is pointing somewhere useless.

The cause is a missing symlink. `pipewire-audio` ships the file that redirects ALSA's default at PipeWire:
```
/usr/share/alsa/alsa.conf.d/99-pipewire-default.conf   # defines pcm.!default { type pipewire }
```
but **ALSA only reads `/etc/alsa/conf.d/`**, and the symlink into that directory is owned by the separate `pipewire-alsa` package. Without it, `pcm.!default` is never defined and ALSA falls back to its built-in default of **card 0**.

That fallback is the nasty part, because card 0 is whatever the kernel enumerated first — not necessarily anything that can play sound. On this machine:
```bash
cat /proc/asound/cards    # 0 = Logitech BRIO (the webcam!)
ls /proc/asound/BRIO/     # pcm0c only — capture, no playback (pcm*p) at all
aplay -l                  # card 0 isn't even listed as a playback device
```
So ALSA's `default` resolves to a capture-only webcam, and opening it for output returns `ENOENT`. The error message blames a missing file, which sends you hunting in entirely the wrong direction.

The fix:
```bash
sudo pacman -S pipewire-alsa
```
No daemon restart is needed — ALSA reads its config when an application opens the device — but any app that already failed has to be restarted to pick it up.

Worth checking after any install where the audio stack was assembled package-by-package:
```bash
ls -la /etc/alsa/conf.d/ | grep 99-   # should show 99-pipewire-default.conf
```

### Schiit Magni Unity mute workaround
The Schiit Magni Unity exposes a USB Audio Class hardware mute control (visible to ALSA as `numid=2,iface=MIXER,name='PCM Playback Switch'`). When wireplumber translates a `wpctl set-mute` into a toggle of that hardware control, the Magni Unity's anti-pop output relay engages — and on unmute, the relay does not reliably release. The software state correctly reports "unmuted" while the analog stage stays silent until the USB device is reinitialized (a reboot, a USB replug, or a profile bounce).

Things that were tried but did **not** work:
- `api.alsa.soft-mixer = true` as a `monitor.alsa.rules` action against the Schiit's `node.name`. The property is happily set on the node, but the installed PipeWire's ALSA backend (`/usr/lib/spa-0.2/alsa/libspa-alsa.so`) does not consume it — strings in that lib only reference `api.alsa.bind-ctls`, `api.alsa.bind-ctl.%s`, `api.alsa.disable-mixer-path`, etc. Wireplumber still flips `PCM Playback Switch` on every mute toggle and the relay still gets stuck.

The pragmatic workaround:
1. `./utils/audio-mute-toggle.sh` toggles mute, and on the unmute leg bounces the Schiit's device profile (`wpctl set-profile <dev_id> 0` → `sleep 0.3` → `set-profile 1`). The profile bounce forces a USB re-init which releases the relay.
2. Install it: `mkdir -p ~/.local/bin && install -m 0755 ./utils/audio-mute-toggle.sh ~/.local/bin/audio-mute-toggle.sh`
3. The `XF86AudioMute` binding in `config/hypr/hyprland.lua` calls this script instead of `wpctl set-mute` directly.

Recovery command if you ever hit the stuck-relay state manually (e.g. via the system tray icon, which still calls `wpctl set-mute` and is not yet routed through the script):
```bash
SCHIIT_DEV=$(wpctl status | awk '/Devices:/,/Sinks:/' | grep -F "Schiit Magni Unity" | grep -oE '[0-9]+\.' | tr -d '.' | head -1)
wpctl set-profile "$SCHIIT_DEV" 0 && sleep 0.3 && wpctl set-profile "$SCHIIT_DEV" 1
```

## yay for AUR packages
This is probably a good time to go about setting up yay so I can use it for installing and updating packages from the AUR.


### Useful Sound utilities
- `pipewire-pulse` Some games / applications might expect to still talk to pulseaudio, so this compatibility layer sets that up for them.
- `pipewire-alsa` The equivalent compatibility layer for applications that talk raw ALSA. Easy to overlook because the other pipewire packages install fine without it — see the section above for the confusing failure mode it causes.
- `wiremix` a feature rich TUI with the ability to set default sources and sinks and even do application specific routing of sources of sinks. This is like the old pavucontrol!
- `qpwgraph` A utility that has been useful so far in ensuring I have the right sets of inputs and outputs hooked up together.


## System Backups
Because I am using a full drive encryption with LUKS over a ext4 file system, I decided to use [timeshift](https://wiki.archlinux.org/title/Timeshift) for my system backup solution. However, I didn't follow the instructions on the wiki page entirely. My configuration was much simpler:
First, I installed timeshift:
```bash
sudo pacman -S timeshift
```
Then I ran the following command to see if it could detect and mount all my drives as I wanted to store the backup on a second encrypted external drive:
```bash
sudo timeshift --list-devices
```
As part of this command, it automatically detected my second encrypted external drive. For this section, let's pretend that drive was /dev/sda. It actually asked me for the password to unencrypt the drive. I believe that because this was the first drive it went ahead and decided that this drive would be the default snapshot device. It did some setup automatically:
```
First run mode (config file not found)
Selected default snapshot type: RSYNC
Enter passphrase for /dev/sda2: 

Mounted '/dev/dm-2 (sda2)' at '/run/timeshift/130670/backup'
Selected default snapshot device: /dev/dm-2

Devices with Linux file systems:
[...etc]
```

Anyways, instead of copying over the default config and modifying the config like it says in the wiki, I decided to go through the GUI first time setup wizard instead (this is why I did this step after setting up hyprland):
```bash
sudo timeshift-gtk
```
During the setup, I ensured that I select rsync as I have a ext4 file system.
Now, it listed out all the devices eligible for backup, I went ahead and select /dev/sda again for device backup. I also chose to set up 7 days of daily backups along with weekly and monthly backups.

Then I created the backup through the GUI as well.

I validated that the backup was created by mounting that drive and viewing the backup in the corresponding `/timeshift` directory.

I also validated that the timeshift config at `/etc/timeshift/timeshift.json` reflected the configuration selections I made in the GUI.

I can create a timeshift (when a backup is due) by running the following command:
```bash
sudo timeshift --check --scripted
```
This command is safe to run any time as it only creates backups when they are due based on the cadence specified in the config file. If the backup drive is encrypted, it will prompt for the password to unencrypt the drive.

I even made a custom alias called `system_update` that takes care of running a timeshift backup before doing a full system upgrade using `yay`!



## Fetch today's weather
`curl 'v2.wttr.in/Raleigh?u'`

