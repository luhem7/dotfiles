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


## Allowing system suspend without needing password
Do these steps at this point for sanity's sake.
```bash
sudo cp ./arch_linux/polkit/10-enable-suspend-wheel.rules /etc/polkit-1/rules.d/10-enable-suspend-wheel.rules
sudo chown root:polkitd /etc/polkit-1/rules.d/10-enable-suspend-wheel.rules
sudo chmod 644 /etc/polkit-1/rules.d/10-enable-suspend-wheel.rules
sudo systemctl reload polkit
```




**TODO** Lots of good recommendations on this page, particularly around limiting vram usage for certain applications. See section **2.3 nvidia-application-profiles.rc.d** in [this section](https://wiki.archlinux.org/title/NVIDIA#Wayland_configuration)


