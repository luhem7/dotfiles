#!/bin/bash
# Reset the Blue Mic by its hardware ID
ID="046d:0ab7" # <--- REPLACE WITH YOUR ID FROM LSUSB
DEV=$(lsusb -d "$ID" | head -n 1)
echo 
if [ -n "$DEV" ]; then
    BUS=$(echo "$DEV" | awk '{print $2}')
    DEV_ADDR=$(echo "$DEV" | awk '{print $4}' | sed 's/://')
    sudo usbreset "/dev/bus/usb/$BUS/$DEV_ADDR"
fi
