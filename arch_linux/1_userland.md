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

`cat /sys/module/nvidia_drm/parameters/modeset` shoud output Y

**Early KMS**

At this point to support early module loading of the nvidia modules, I modified the `etc/mkinitcpio.conf` as so:
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

## Setting up a Desktop
I'm currently going with the [hyprland eco-system](https://wiki.archlinux.org/title/Hyprland). As noted on the page, it is good to take a look at the [Hyprland Nvidia page](https://wiki.hypr.land/Nvidia/), but I had already implemented the recommendations here!

Next, I copied a default Hyprland config over to my user config:
```bash
cp /usr/share/hypr/hyprland.conf ~/.config/hypr/hyprland.conf
```
and then I added the following lines to the top of that file
```
env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
```
But really, this is already present in the included hyprland config in this repo.

Along with installing Hyprland I had to install the following mandatory and highly recommended packages:

```bash
sudo pacman -S pipewire wireplumber wiremix hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk hyprpolkitagent kitty dolphin wofi firefox qt5-wayland qt6-wayland
```

After this, I also followed the installation guide on [their official website](https://wiki.hypr.land/Getting-Started/Master-Tutorial/)

I believe that I'm supposed to be starting Hyprland via usm, but I'm happy enough starting it manually by typeing `start-hyprland` on the command line after login!

**Locking the screen before going to sleep**
Hyprlock takes care of locking the screen and Hypridle is a idle management daemon that takes care of firing off events related to the desktop being idle or going to sleep.

First, copy over the config files in this repo to `~/.config/hypr/`. Then install the required packages. It is important that we copy over the config files first as hyprlock might just draw a blank screen instead of 
```
sudo pacman -S hyprlock hypridle
```
Logout of the desktop and login to verify that these changes have taken effect.



## Sound
This section is something I need to refine. What I found is that arch was able to successfully detect my audio device, but it didn't make it the default. I'm currently targetting using [pipewire](https://wiki.archlinux.org/title/PipeWire) and [wireplumber](https://wiki.archlinux.org/title/WirePlumber) for all of the sound manangement and trying not to use pulse audio as much as possible.

First, I wanted to lower the priority of my motherboard's optical and HDMI outputs. I wrote the necessary configuration user directory + snippets under `./config/wireplumber/` that should be copied to the corresponding directory structure in the home directory. Notably, I had to ensure that I was using configuration snippets in the `wireplumber.conf.d` directory because if I supplied just a single configuration file, it never read the global configuration file and wireplumber fails to start!

After copying the config snippets, we can restart the service (which is running at the user level!) and check the status as so:
```bash
systemctl --user start wireplumber
systemctl --user status wireplumber
```
If the service fails to start use the following command to check what failed `journalctl --user -u wireplumber -n 50`. After fixing the issue, the systemctl failure status flag needs to be reset before restarting the service: `systemctl --user reset-failed wireplumber`

We can run `speaker-test -c 2 -l 1` to play a sound through the front stereo speakers to see if the settings are working.

### Useful Sound utilities
- `wiremix` a feature rich TUI with the ability to set default sources and sinks and even do application specific routing of sources of sinks. This is like the old pavucontrol!
- `qpwgraph` A utility has been useful so far in ensuring I have the right sets of inputs and puts setup hooked up together.


## Fetch today's weather
`curl 'v2.wttr.in/Raleigh?u'`



