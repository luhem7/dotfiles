import { Gtk, Gdk } from "ags/gtk4"
import { execAsync } from "ags/process"
import { startRecording } from "./Recording"

export function Screenshot() {
  // One GestureClick listening to all buttons (set_button(0)); branch on which button
  // fired. Button number is unambiguous, unlike reading Shift from the event state.
  // Left click: screenshot region. Right click: record a window.
  let setupDone = false
  const setup = (self: Gtk.Button) => {
    if (setupDone) return
    setupDone = true

    const click = new Gtk.GestureClick()
    click.set_button(0) // 0 = listen for any button
    click.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)
    click.connect("pressed", gesture => {
      const button = gesture.get_current_button()
      if (button === Gdk.BUTTON_SECONDARY) {
        startRecording()
      } else if (button === Gdk.BUTTON_PRIMARY) {
        execAsync(["hyprshot", "-m", "region", "--clipboard-only"]).catch(err =>
          console.error("hyprshot failed:", err),
        )
      }
    })
    self.add_controller(click)
  }

  return (
    <button
      class="volume-button"
      tooltip_text="Left click: screenshot region · Right click: record window"
      onRealize={setup}
    >
      <image iconName="camera-photo-symbolic" pixelSize={16} />
    </button>
  )
}
