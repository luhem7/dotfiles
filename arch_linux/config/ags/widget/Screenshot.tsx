import { execAsync } from "ags/process"

export function Screenshot() {
  return (
    <button
      class="volume-button"
      tooltip_text="Screenshot region to clipboard"
      onClicked={() =>
        execAsync(["hyprshot", "-m", "region", "--clipboard-only"]).catch(err =>
          console.error("hyprshot failed:", err),
        )
      }
    >
      <image iconName="camera-photo-symbolic" pixelSize={16} />
    </button>
  )
}
