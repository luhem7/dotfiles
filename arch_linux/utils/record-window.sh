#!/usr/bin/env bash
# Record a single window on Wayland/Hyprland via gpu-screen-recorder's portal.
# On Wayland, `portal` is the only per-window capture path (focused/window are X11-only).
#
# Usage:
#   record-window.sh -o <output_dir> [--last]
#
#   -o, --output-dir DIR   (required) directory to write the recording into
#   -l, --last             re-record the previously selected window (skip the picker)
#   -h, --help             show this help
#
# Stop a recording with Ctrl+C; the file is finalized on exit.
#
# If the picker ever shows a stale/outdated window list, the portal has drifted
# (usually after very long uptime). Reset it with:
#   systemctl --user restart xdg-desktop-portal-hyprland.service

set -euo pipefail

TOKEN="${XDG_CONFIG_HOME:-$HOME/.config}/gpu-screen-recorder/restore_token"

usage() { sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

# Post a desktop notification (shown by dunst) if a notifier is present; never fail the script.
notify() {
  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send -a "record-window" "$@" || true
}

output_dir=""
reuse_last=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output-dir) output_dir="${2:-}"; shift 2 ;;
    -l|--last)       reuse_last=1; shift ;;
    -h|--help)       usage 0 ;;
    *) echo "record-window: unknown argument: $1" >&2; usage 1 ;;
  esac
done

if [[ -z "$output_dir" ]]; then
  echo "record-window: -o/--output-dir is required" >&2
  usage 1
fi

mkdir -p "$output_dir"

if [[ "$reuse_last" -eq 1 ]]; then
  if [[ ! -f "$TOKEN" ]]; then
    echo "record-window: no previous window saved yet — run once without --last to pick one" >&2
    exit 1
  fi
else
  # Fresh pick: drop the saved session so the portal shows the picker again.
  rm -f "$TOKEN"
fi

outfile="$output_dir/recording-$(date +%Y-%m-%d_%H-%M-%S).mp4"

# gsr keeps running after a capture error (e.g. a mid-recording window resize breaks
# pipewire format negotiation), muxing frozen frames — so a non-empty file alone doesn't
# mean the recording is good. These markers in gsr's output flag such a failure.
error_re='gsr error:|no more input formats|new state: "error"'
log="$(mktemp -t record-window.XXXXXX.log)"

# -restore-portal-session yes: reuse the saved window if a token exists (see --last),
# otherwise show the picker and save the pick for next time.
# Tee output to $log (still shown live) so we can scan it for capture errors.
gpu-screen-recorder \
  -w portal -restore-portal-session yes \
  -f 60 -a default_output \
  -o "$outfile" > >(tee "$log") 2>&1 &
gsr_pid=$!

# Background watcher: fire "started" once capture actually begins (gsr opens the file only
# after you pick a window), and a critical toast the instant a capture error appears — so a
# freeze is reported when it happens, not only at the end.
( started=0; warned=0
  while kill -0 "$gsr_pid" 2>/dev/null; do
    if [[ "$started" -eq 0 && -e "$outfile" ]]; then
      notify -i media-record "Recording started" "$(basename "$outfile")"
      started=1
    fi
    if [[ "$warned" -eq 0 ]] && grep -qE "$error_re" "$log" 2>/dev/null; then
      notify -u critical -i dialog-warning "Recording problem" \
        "Capture error — video is likely frozen. $(basename "$outfile")"
      warned=1
    fi
    sleep 0.5
  done ) &

# Ctrl+C reaches both this script and gsr. Forward it so gsr finalizes the file,
# then keep waiting until gsr has fully exited before reporting the result.
trap 'kill -INT "$gsr_pid" 2>/dev/null || true' INT TERM
while kill -0 "$gsr_pid" 2>/dev/null; do
  wait "$gsr_pid" 2>/dev/null || true
done

# Report: a non-empty file is necessary but not sufficient — also check for capture errors.
if [[ ! -s "$outfile" ]]; then
  notify -u critical -i dialog-error "Recording failed" "No file written. Log: $log"
elif grep -qE "$error_re" "$log" 2>/dev/null; then
  notify -u critical -i dialog-warning "Recording saved with errors" \
    "$outfile likely has frozen frames. Log: $log"
else
  notify -i media-playback-stop "Recording saved" "$outfile ($(du -h "$outfile" | cut -f1))"
  rm -f "$log"   # clean run: no need to keep the log
fi
