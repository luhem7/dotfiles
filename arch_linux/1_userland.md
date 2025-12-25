# Userland setup
Unlike the previous article, here everything happens while logged in as the primary user (and not root)

## Networking setup
Jumping forward a bit, we go to **7. Networking** on the [General Recommendations Guide](https://wiki.archlinux.org/title/General_recommendations)

I went to [Network Configuration](https://wiki.archlinux.org/title/Network_configuration).

There are a number of recommendations here, but the only things that I had to do was enable the [systemd-networkd.service](https://wiki.archlinux.org/title/Systemd-networkd) and the [systemd-resolved.service](https://wiki.archlinux.org/title/Systemd-resolved)

```bash
sudo systemctl enable systemd-networkd.service
sudo systemctl enable systemd-resolved.service
```

In addition to "To provide domain name resolution for software that reads /etc/resolv.conf directly, such as web browsers, Go, GnuPG and QEMU when using user networking":

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

**Ensure DRM is enabled**
`cat /sys/module/nvidia_drm/parameters/modeset` shoud output Y

At this point to support early module loading of the nvidia modules, I modified the `etc/mkinitcpio.conf` as so:

```
MODULES=(i915 nvidia nvidia_modeset nvidia_uvm nvidia_drm)
```
Then regenerated the initramfs using `sudo mkinitcpio -P`

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

After this, I installed Hyprland and also followed the installation guide on [their official website](https://wiki.hypr.land/Getting-Started/Master-Tutorial/)

During this setup I had to install the following mandatory and highly recommended packages:

```bash
sudo pacman -S pipewire wireplumber xdg-desktop-portal-hyprland xdg-desktop-portal-gtk hyprpolkitagent kitty dolphin wofi firefox qt5-wayland qt6-wayland
```

I believe that I'm supposed to be starting Hyprland via usm, but I'm happy enough starting it manually by typeing `Hyprland` on the command line after login!

**TODO** Being able to lock and unlock the screen

**TODO** having the screen lock before I put it to sleep

## Sound


## Fetch today's weather
`curl 'v2.wttr.in/Raleigh?u'`



