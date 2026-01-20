import { Gtk } from "ags/gtk4"
import Wp from "gi://AstalWp"

const wp = Wp.get_default()

function initSpeaker(button: Gtk.Button) {
  const speaker = wp?.get_default_speaker()
  if (!speaker) return

  const icon = new Gtk.Image()
  icon.set_from_icon_name(speaker.get_volume_icon())
  icon.set_pixel_size(16)
  button.set_child(icon)

  // Update icon when volume or mute changes
  const updateIcon = () => {
    icon.set_from_icon_name(speaker.get_volume_icon())
  }

  speaker.connect("notify::volume-icon", updateIcon)

  // Update tooltip with volume percentage and device name
  const updateTooltip = () => {
    const vol = Math.round(speaker.get_volume() * 100)
    const muted = speaker.get_mute()
    const device = speaker.get_description() || "Unknown"
    const status = muted ? "Muted" : `${vol}%`
    button.set_tooltip_text(`${device}\n${status}`)
  }

  speaker.connect("notify::volume", updateTooltip)
  speaker.connect("notify::mute", updateTooltip)
  updateTooltip()

  // Click to toggle mute
  button.connect("clicked", () => {
    speaker.set_mute(!speaker.get_mute())
  })

  // Scroll to adjust volume
  const scrollController = new Gtk.EventControllerScroll()
  scrollController.set_flags(Gtk.EventControllerScrollFlags.VERTICAL)
  scrollController.connect("scroll", (_ctrl, _dx, dy) => {
    const step = 0.05
    const current = speaker.get_volume()
    const newVol = Math.max(0, Math.min(1.5, current - dy * step))
    speaker.set_volume(newVol)
    return true
  })
  button.add_controller(scrollController)
}

function initMicrophone(button: Gtk.Button) {
  const mic = wp?.get_default_microphone()
  if (!mic) return

  const icon = new Gtk.Image()
  icon.set_from_icon_name(mic.get_volume_icon())
  icon.set_pixel_size(16)
  button.set_child(icon)

  // Update icon when volume or mute changes
  const updateIcon = () => {
    icon.set_from_icon_name(mic.get_volume_icon())
  }

  mic.connect("notify::volume-icon", updateIcon)

  // Update tooltip with volume percentage and device name
  const updateTooltip = () => {
    const vol = Math.round(mic.get_volume() * 100)
    const muted = mic.get_mute()
    const device = mic.get_description() || "Unknown"
    const status = muted ? "Muted" : `${vol}%`
    button.set_tooltip_text(`${device}\n${status}`)
  }

  mic.connect("notify::volume", updateTooltip)
  mic.connect("notify::mute", updateTooltip)
  updateTooltip()

  // Click to toggle mute
  button.connect("clicked", () => {
    mic.set_mute(!mic.get_mute())
  })

  // Scroll to adjust volume
  const scrollController = new Gtk.EventControllerScroll()
  scrollController.set_flags(Gtk.EventControllerScrollFlags.VERTICAL)
  scrollController.connect("scroll", (_ctrl, _dx, dy) => {
    const step = 0.05
    const current = mic.get_volume()
    const newVol = Math.max(0, Math.min(1.5, current - dy * step))
    mic.set_volume(newVol)
    return true
  })
  button.add_controller(scrollController)
}

export function Speaker() {
  return <button class="volume-button" onRealize={initSpeaker} />
}

export function Microphone() {
  return <button class="volume-button" onRealize={initMicrophone} />
}
