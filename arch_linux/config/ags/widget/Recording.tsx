import { createComputed } from "ags"
import { createPoll } from "ags/time"
import { execAsync } from "ags/process"

const RECORD_SCRIPT = "$HOME/.local/bin/record-window.sh"
const OUTPUT_DIR = "$HOME/Videos"

// Match the process NAME (comm), not the full command line, so the poll's own shell can't
// match itself. comm is truncated to 15 chars, so "gpu-screen-rec" is a truncation-safe
// substring of "gpu-screen-recorder".
const PROC = "gpu-screen-rec"

// Poll for a running recorder so the bar reflects reality even if a recording is started
// or stopped outside AGS (e.g. from a terminal), and survives an AGS config reload.
const recordingState = createPoll(
  "no",
  1000,
  `sh -c 'pgrep ${PROC} >/dev/null && echo yes || echo no'`,
)

export const isRecording = createComputed(() => recordingState().trim() === "yes")

// Start only if nothing is already recording (guard against concurrent captures). Detach
// with `setsid -f` so the recorder survives an AGS reload; it inherits AGS's Wayland/DBus
// environment, so the portal picker still works. (setsid avoids depending on Hyprland's
// dispatch API, whose exec syntax changed in 0.56.)
export function startRecording() {
  execAsync([
    "sh",
    "-c",
    `pgrep ${PROC} >/dev/null || setsid -f ${RECORD_SCRIPT} -o ${OUTPUT_DIR}`,
  ]).catch(err => console.error("start recording failed:", err))
}

// Stop with SIGINT so gpu-screen-recorder finalizes the file cleanly; the record script's
// own handler then fires its "saved" notification and exits.
export function stopRecording() {
  execAsync(["pkill", "-INT", PROC]).catch(err =>
    console.error("stop recording failed:", err),
  )
}

export function RecordingIndicator() {
  return (
    <button
      class="recording-button"
      visible={isRecording}
      tooltip_text="Recording — click to stop"
      onClicked={() => stopRecording()}
    >
      <image iconName="media-record-symbolic" pixelSize={16} />
    </button>
  )
}
