# Notes on installing arch linux
These are the tips, tricks and choices that I used when installing Arch linux on my home pc.
- No wireless setup, because i connect to the internet using ethernet connected to my router
- I have an nVidia 4080 graphics card.

## Install Guide
I started from the [Official Install Guide](https://wiki.archlinux.org/title/Installation_guide) and burnt the ISO onto a USB drive.

## In the install environment

### Booting from live environment
No issues here

### Connect to the internet
No issues connecting to the internet using ethernet, DHCP enabled by default in the install environment.
I wish I read the note that says:
>  In the installation image, systemd-networkd, systemd-resolved, iwd and ModemManager are preconfigured and enabled by default. That will not be the case for the installed system.

### Partitioning the disks
In my install, I wanted to fully encrypt the file system OS was going to be on including the root partition. The main page for partitioning a disk is [dm-crypt](https://wiki.archlinux.org/title/Dm-crypt), however I mostly following the guide under [Encrypting an entire system](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system). The particular scenario I followed is [LUKS on a partition](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#Overview)


**Getting information about the disks**
`fdisk -l` worked well! Assume that the drive I wanted to partition is `/dev/sda` going forward

If one only needs the UUIDs for the drives, then `lsblk -f` suffices (and doesn't require root permissions)

**Doing the actual partitioning**
I used fdisk for this, it was easy enough to create the partition plans before applying them.
- First I deleted existing partitions on the disk
- Then I made a new GPT table on the disk
- First I created a partition of size +4G (That's +4 Gibibytes), then set it's type as boot. This was going to be `/boot` (partition /dev/sda1)
- Next, I created a partition that went to the end of the drive, then set it's type to Linux Root System 64 bit (it was type #23 in the list). This was going to be `/` (partiion /dev/sda2)
- Finally I wrote this partition scheme to the disk

**Preparing non-boot paritions**
I followed the steps [under the section of the same name exactly](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition)

**Preparing boot paritions**
I followed the steps [under the section of the same name exactly](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition)

**Mounting the partitions**
At this this point, the partitions where mounted, and I didn't have to do anything

### Installation
I went back to section **2. Installation** on the [Installation Guide](https://wiki.archlinux.org/title/Installation_guide)
The default pacman mirrors, worked and continue to work well for me.
These are the packages I installed:
`base linux linux-firmware intel-ucode vi vim man-db man-pages texinfo`
These are the packages I installed later that I wished I installed up front:
`sudo`

### Configure the filesystem
**Fstab**
I did not create a fstab file at this point. I might need to revise this later if it turns out to be needed.

**Chroot**
`arch-chroot /mnt`. From here, the boot parition is on `/boot`

**Time, Localization, Hostname**
I followed the guide verbatim

### Preparing the kernel and boot-loader
For this, I had to go back to [the 2.5 Configuring mkinitcpio section of the encryption setup guide](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition)

This is what I neded up putting in my `/etc/mkinitcpio.conf`:
`HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)`
(as in, I only added the single sd-encrypt before filesystems)

But, then i turned out that I needed to specify particular kernel parameters which lead to a long sidequest on boot-loaders and how to build the kernel. In the end, I decided to use a simple [Unified kernel image](https://wiki.archlinux.org/title/Unified_kernel_image)!

**TODO** Do I need to specify a pacman hook to rebuild the kernel whenever the nvidia driver package is updated?
