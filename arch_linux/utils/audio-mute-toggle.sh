#!/usr/bin/env bash
# Toggle mute on the default audio sink, with a workaround for the
# Schiit Magni Unity: its USB Audio Class hardware mute engages an
# anti-pop relay that does not reliably release on unmute, leaving
# the analog stage silent. After unmuting, bounce the device profile
# off -> on to force a USB re-init and release the relay.

set -euo pipefail

SCHIIT_NODE_NAME="alsa_output.usb-Schiit_Audio_Schiit_Magni_Unity-00.analog-stereo"
SCHIIT_DEV_NAME="Schiit Magni Unity"

wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

# Nothing more to do if we just muted.
if wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED; then
    exit 0
fi

# Workaround only applies when the default sink is the Schiit.
default_node_name=$(wpctl inspect @DEFAULT_AUDIO_SINK@ \
    | awk -F'"' '/^[ \t*]*node\.name = /{print $2; exit}')
[[ "$default_node_name" == "$SCHIIT_NODE_NAME" ]] || exit 0

# Locate the Schiit device id from `wpctl status`'s Devices section.
dev_id=$(wpctl status \
    | awk '/Devices:/,/Sinks:/' \
    | grep -F "$SCHIIT_DEV_NAME" \
    | grep -oE '[0-9]+\.' | tr -d '.' | head -1)
[[ -n "$dev_id" ]] || exit 0

# Bounce profile to force USB re-init.
# Profile 0 = Off; profile 1 = analog-stereo (the only useful profile
# on this DAC). If you ever set a different profile, update this.
wpctl set-profile "$dev_id" 0
sleep 0.3
wpctl set-profile "$dev_id" 1
