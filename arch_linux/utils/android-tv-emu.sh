#!/usr/bin/env bash
# Set up and run an Android TV (Google TV) emulator using Google's official
# SDK. Everything lives under $ANDROID_HOME and ~/.android; delete both to
# undo. Needs /dev/kvm. Don't run VirtualBox VMs at the same time.
#
# Per-machine overrides (environment):
#   ANDROID_HOME    SDK location (default ~/Android/Sdk)
#   ATV_IMAGE       system image, e.g. "system-images;android-34;google-tv;x86_64"
#                   (default: newest google-tv x86_64 image available)
#   ATV_AVD         AVD name (default tv)
#   ATV_GPU         emulator -gpu mode (default host; swiftshader_indirect if
#                   rendering is broken)
#   ATV_PROXY_PORT  mitmdump port (default 8080)

set -euo pipefail

export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
AVD="${ATV_AVD:-tv}"
GPU="${ATV_GPU:-host}"
AVD_CONFIG="$HOME/.android/avd/$AVD.avd/config.ini"
PROXY_PORT="${ATV_PROXY_PORT:-8080}"
PROXY_ADDON="$(dirname "$(realpath "$0")")/android-tv-proxy.py"
SELF="$(basename "$0")"

# From https://developer.android.com/studio#command-line-tools-only
TOOLS_ZIP="commandlinetools-linux-15859902_latest.zip"
TOOLS_SHA256="4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583"

BIN="$ANDROID_HOME/cmdline-tools/latest/bin"
export PATH="$BIN:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"

usage() {
    cat <<EOF
Usage: $SELF [options] [-- emulator args...]
       $SELF setup

Runs the emulator unless 'setup' is given: cold boot, with traffic routed
through mitmdump (LAN blocked, logged to /tmp).

Options:
  -np, --no-proxy   skip the proxy (LAN reachable, nothing logged)
       --allow-lan  keep the proxy but let traffic reach LAN/private addresses
       --snapshot   use Quick Boot snapshots instead of cold booting
  -h,  --help       show this help

Examples:
  $SELF --no-proxy
  $SELF -- -wipe-data
EOF
}

bad_usage() {
    echo "$SELF: $1" >&2
    echo "Try '$SELF --help'." >&2
    exit 2
}

install_cmdline_tools() {
    if [[ -x "$BIN/sdkmanager" ]]; then
        echo "cmdline-tools already installed."
        return
    fi

    local tmp
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"; trap - RETURN' RETURN

    curl -fL -o "$tmp/$TOOLS_ZIP" "https://dl.google.com/android/repository/$TOOLS_ZIP"
    echo "$TOOLS_SHA256  $tmp/$TOOLS_ZIP" | sha256sum -c -
    unzip -q "$tmp/$TOOLS_ZIP" -d "$tmp"

    mkdir -p "$ANDROID_HOME/cmdline-tools"
    mv "$tmp/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
}

newest_tv_image() {
    sdkmanager --list 2>/dev/null \
        | grep -oE 'system-images;android-[0-9]+;google-tv;x86_64' \
        | sort -uV | tail -1
}

has_avd() {
    avdmanager list avd -c | grep -qx "$AVD"
}

avd_prop() {
    sed -n "s/^$1=//p" "$AVD_CONFIG"
}

print_summary() {
    cat <<EOF

Android TV emulator ready
  AVD:     $AVD ($(dirname "$AVD_CONFIG"))
  Image:   $(avd_prop image.sysdir.1)
  Screen:  $(avd_prop hw.lcd.width)x$(avd_prop hw.lcd.height) ($(avd_prop hw.device.name))
  Input:   keyboard=$(avd_prop hw.keyboard), dpad=$(avd_prop hw.dPad)

  Run:        $SELF   (proxied: LAN blocked, logs to /tmp)
  No proxy:   $SELF --no-proxy
  Quick Boot: $SELF --snapshot
  Wipe data:  $SELF -- -wipe-data
  Install:    $ANDROID_HOME/platform-tools/adb install app.apk
EOF
}

do_setup() {
    [[ -e /dev/kvm ]] || { echo "/dev/kvm not found; enable virtualization." >&2; exit 1; }

    install_cmdline_tools
    sdkmanager --licenses

    local image="${ATV_IMAGE:-$(newest_tv_image)}"
    [[ -n "$image" ]] || { echo "No google-tv image found; set ATV_IMAGE." >&2; exit 1; }
    echo "Using $image"

    sdkmanager "emulator" "platform-tools" "$image"

    if has_avd; then
        echo "AVD '$AVD' already exists."
    else
        # avdmanager asks whether to create a custom hardware profile
        echo no | avdmanager create avd -n "$AVD" -k "$image" -d tv_1080p
        # avdmanager can print errors and still exit 0
        has_avd || { echo "AVD '$AVD' was not created." >&2; exit 1; }
        # Defaults to no, which also drops input from the emulator's D-pad
        sed -i '/^hw\.keyboard=/d' "$AVD_CONFIG"
        echo "hw.keyboard=yes" >> "$AVD_CONFIG"
    fi

    print_summary
}

start_proxy() {
    command -v mitmdump >/dev/null || { echo "mitmdump not found; install mitmproxy or use --no-proxy." >&2; exit 1; }
    [[ -f "$PROXY_ADDON" ]] || { echo "Add-on $PROXY_ADDON not found." >&2; exit 1; }

    PROXY_LOG="/tmp/android-tv-proxy-$(date +%Y%m%d-%H%M%S).log"
    # Holds portal URLs, cookies and the box's MAC
    (umask 077 && : > "$PROXY_LOG")

    # The add-on passes TLS through undecrypted (Google Play images can't be
    # made to trust mitmproxy's CA) and blocks LAN access. Large bodies are
    # streamed, otherwise live video buffers forever.
    mitmdump --listen-host 127.0.0.1 --listen-port "$PROXY_PORT" -s "$PROXY_ADDON" \
        --set allow_lan="$1" --set flow_detail=2 --set stream_large_bodies=1m \
        >> "$PROXY_LOG" 2>&1 &
    PROXY_PID=$!
    trap 'kill "$PROXY_PID" 2>/dev/null; echo "Proxy log: $PROXY_LOG"' EXIT

    sleep 1
    kill -0 "$PROXY_PID" 2>/dev/null || { echo "mitmdump failed to start:" >&2; cat "$PROXY_LOG" >&2; exit 1; }

    echo "Proxy log: $PROXY_LOG  (tail -f it to watch live)"
}

if [[ "${1:-}" == setup ]]; then
    [[ $# -eq 1 ]] || bad_usage "setup takes no arguments"
    do_setup
    exit
fi

proxy=true allow_lan=false snapshot=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        -np|--no-proxy) proxy=false ;;
        --allow-lan)    allow_lan=true ;;
        --snapshot)     snapshot=true ;;
        -h|--help)      usage; exit 0 ;;
        --)             shift; break ;;
        *)              bad_usage "unknown option '$1' (emulator args go after --)" ;;
    esac
    shift
done

if $allow_lan && ! $proxy; then
    bad_usage "--allow-lan conflicts with --no-proxy"
fi

command -v emulator >/dev/null || { echo "Emulator not installed; run '$SELF setup' first." >&2; exit 1; }

args=(-avd "$AVD" -gpu "$GPU")

# Restoring Quick Boot snapshots has crashed the emulator, so cold boot
# unless asked otherwise
if $snapshot; then
    echo "Snapshots: on"
else
    echo "Snapshots: off (cold boot)"
    args+=(-no-snapshot)
fi

if $proxy; then
    start_proxy "$allow_lan"
    if $allow_lan; then
        echo "LAN access: ALLOWED"
    else
        echo "LAN access: blocked"
    fi
    args+=(-http-proxy "http://127.0.0.1:$PROXY_PORT")
else
    echo "Proxy: OFF (LAN reachable, nothing logged)"
fi

emulator "${args[@]}" "$@"
