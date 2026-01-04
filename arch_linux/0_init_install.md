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
- First I created a partition of size +4G (That's +4 Gibibytes), then set it's type as `EFI boot` (This was option 1 in the list). This was going to be `/boot` (partition /dev/sda1)
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
`base linux linux-firmware intel-ucode vim man-db man-pages texinfo`
These are the packages I installed later that I wished I installed up front:
`sudo vi polkit zsh htop usbutils wl-clipboard base-devel`
I think it's best not to install nVidia related things at this point.

### Configure the filesystem
**Fstab**
I did not create a fstab file at this point. I might need to revise this later if it turns out to be needed.

**Chroot**
`arch-chroot /mnt`. From here, the boot parition is on `/boot`

## In the ch-root environment
Following the same guide from above:

**Time, Localization, Hostname**
I followed the guide verbatim.

### Preparing the kernel and boot-loader
For this, I had to go back to [the 2.5 Configuring mkinitcpio section of the encryption setup guide](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition)

Picking up from **2.5 Configuring mkinitcpio**:

This is what I neded up putting in my `/etc/mkinitcpio.conf`:
```
HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)
```
(as in, I only added the single sd-encrypt before filesystems)

And then under **2.6 Configuing the boot loader**:

Turns out that I needed to specify particular kernel parameters which lead to a long sidequest on boot-loaders and how to build the kernel. In the end, I decided to use a simple [Unified kernel image](https://wiki.archlinux.org/title/Unified_kernel_image)!

And specifically under that, I decided to go with the more tedious vanilla option of having mkinitcpio assemble the UKI for me. On this page describing the generation of the UKI, `esp` mapped to `/boot/` because I was in the chroot environment. 

Back on the `luks_on_a_partition` page (yes, lots of flipping back and forth between references here) where it says that we need to specify a kernel parameter that looks like this:
```
rd.luks.name=1082fcb1-9b0a-480f-86b8-fc52c135a563=root root=/dev/mapper/root
```
I put my corresponding setting into `/etc/cmdline.d/unencrypt.conf` using the following command: (again, in this example /dev/sda/ was the OS drive, with sda2 being the cryto LUKS partition)
```bash
echo "rd.luks.name=$(lsblk -dno UUID /dev/sda2)=root root=/dev/mapper/root" > /etc/cmdline.d/unencrypt.conf
```

Now, back on the `Unified_kernel_image` page under **1.1.2 .preset file**
Like above, the `esp` on this page mapped to `/boot` for me. It pretty much worked for me, including the splash image!

After that I followed the steps on the same page under sections **1.1.3 pacman hook** and **1.1.4 Building the UKIs**. After the kernel images were built, I verified by `ls /boot/EFI/Linux/` and making sure I see a `arch-linux.efi` file there.

Note: At this point `mkinitcpio -P` should;ve run successfully atleast once.

### Testing the setup
At this point, I rebooted the system using `systemctl reboot` and checked to see if I could boot into the installed OS successfully.

-------------------------------------------------------------
    **Aside on Troubleshooting the boot loader**
    During this process, there were many times when I rebooted and realised that I messed up some configuration somewhere. During this time, I simply booted from the install medium again, unencrypted the partition, mounted the partition and chroot'ed into the partition.
    - Unencrypting the root partition:
    ```bash
    cryptsetup open /dev/sda2 root
    ```
    - Mounting the partitions:
    ```bash
    mount /dev/mapper/root /mnt 
    mount /dev/sda1 /mnt/boot
    ```
    - Chroot into the parition: `arch-chroot /mnt`. 
    - Then proceed where you left off.
-------------------------------------------------------------

### Setting the root password
`passwd` as simple as that

### User setup
Here we switch over to the [General Recommendations Guide](https://wiki.archlinux.org/title/General_recommendations). Starting with **1.1 Users and Groups**

This actually takes us to the [Users and groups](https://wiki.archlinux.org/title/Users_and_groups#User_management) which honestly is pretty straight forward. I setup a user account and made sure to make them part of the `wheel` group. I forgot to do this, but now is a good time to specify zsh as the default shell for this user.

Next we take a slight tangent to [Sudo config](https://wiki.archlinux.org/title/Sudo). As part of this, we use `visudo` and just ensure that all members of the group wheel have sudo access. There are some good tips here, including disabling root access, but I'm too chicken shit to actually do that on this system.

There are some good recommendations on the [Security page](https://wiki.archlinux.org/title/Security), but I only followed two of them that involved modifying `/etc/security/faillock.conf`:
- allow 5 login attempts before a user is timed out instead of 3.
- make lock time outs persist across system reboots


# Conclusion
At this point, I had a minimal arch os setup on my drive. My next steps are [detailed here](./arch_linux/0_userland.md)

**TODO** Do I need to specify a pacman hook to rebuild the kernel whenever the nvidia driver package is updated?
