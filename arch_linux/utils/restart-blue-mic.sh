#!/bin/bash
# Reset the Blue Mic by toggling authorization (forces re-enumeration)
VENDOR="046d"
PRODUCT="0ab7"

# Find the device in sysfs
for DIR in /sys/bus/usb/devices/*; do
    if [ -f "$DIR/idVendor" ] && [ -f "$DIR/idProduct" ]; then
        if grep -qi "$VENDOR" "$DIR/idVendor" && grep -qi "$PRODUCT" "$DIR/idProduct"; then
            echo "Found Blue Mic at $DIR"
            
            # Reset via authorized attribute
            echo "Deauthorizing device..."
            if [ "$EUID" -eq 0 ]; then
                echo 0 > "$DIR/authorized"
                sleep 2
                echo 1 > "$DIR/authorized"
            else
                echo 0 | sudo tee "$DIR/authorized" > /dev/null
                sleep 2
                echo 1 | sudo tee "$DIR/authorized" > /dev/null
            fi
            
            echo "Device re-authorized. Reset complete."
            exit 0
        fi
    fi
done

echo "Blue Mic ($VENDOR:$PRODUCT) not found in sysfs."
exit 1