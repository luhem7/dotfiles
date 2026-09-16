#!/usr/bin/env bash
# Mount / unmount a (possibly LUKS-encrypted) USB drive.
#
# Device names like /dev/sdc1 can shift between boots or when other drives
# are plugged in. For a stable target, set USB_DEVICE to a by-uuid path in
# ~/.local_config.zsh, e.g.:
#   export USB_DEVICE=/dev/disk/by-uuid/<uuid from `lsblk -o NAME,UUID`>

set -euo pipefail

DEVICE="${USB_DEVICE:-/dev/sdc1}"
MAPPER_NAME="usb"
MAPPER="/dev/mapper/$MAPPER_NAME"
MOUNT_POINT="/mnt/usb"

usage() {
    echo "Usage: $(basename "$0") -m|--mount | -u|--unmount"
    exit 1
}

is_luks() {
    [[ "$(lsblk -no FSTYPE "$DEVICE")" == "crypto_LUKS" ]]
}

do_mount() {
    [[ -b "$DEVICE" ]] || { echo "Device $DEVICE not found." >&2; exit 1; }

    if mountpoint -q "$MOUNT_POINT"; then
        echo "$MOUNT_POINT is already mounted."
        exit 0
    fi

    sudo mkdir -p "$MOUNT_POINT"

    local source="$DEVICE"
    if is_luks; then
        if [[ -b "$MAPPER" ]]; then
            echo "$MAPPER already open, skipping cryptsetup."
        else
            sudo cryptsetup open "$DEVICE" "$MAPPER_NAME"
        fi
        source="$MAPPER"
    fi

    sudo mount "$source" "$MOUNT_POINT"
    echo "Mounted $source on $MOUNT_POINT."
}

do_unmount() {
    if mountpoint -q "$MOUNT_POINT"; then
        sudo umount "$MOUNT_POINT"
        echo "Unmounted $MOUNT_POINT."
    else
        echo "$MOUNT_POINT is not mounted."
    fi

    if [[ -b "$MAPPER" ]]; then
        sudo cryptsetup close "$MAPPER_NAME"
        echo "Closed $MAPPER."
    fi
}

[[ $# -eq 1 ]] || usage

case "$1" in
    -m|--mount)   do_mount ;;
    -u|--unmount) do_unmount ;;
    *)            usage ;;
esac
