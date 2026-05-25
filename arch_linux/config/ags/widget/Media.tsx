import { Gtk } from "ags/gtk4"
import { createExternal, createState, createComputed } from "ags"
import { createPoll } from "ags/time"
import Mpris from "gi://AstalMpris"
import { LEFT_TRIANGLE } from "../constants"
import { truncate, hasTallGlyphs } from "../util"

const MEDIA_MAX_LENGTH = 40
const PROGRESS_POLL_MS = 250

const mpris = Mpris.get_default()

function pickPlayer(): Mpris.Player | null {
  const players = mpris.players
  return (
    players.find(p => p.playback_status === Mpris.PlaybackStatus.PLAYING) ??
    players.find(p => p.playback_status === Mpris.PlaybackStatus.PAUSED) ??
    null
  )
}

// Separate state cells for properties that mutate on the same player object.
// createComputed only re-runs when its reactive source changes identity, so
// storing the player reference alone would silently miss in-place mutations
// (e.g. playback_status flip on play/pause while the same player stays active).
const [playbackStatus, setPlaybackStatus] = createState<Mpris.PlaybackStatus | null>(null)
const [displayText, setDisplayText] = createState("")
const [canPrev, setCanPrev] = createState(false)
const [canNext, setCanNext] = createState(false)

function syncDerived() {
  const p = pickPlayer()
  setPlaybackStatus(p?.playback_status ?? null)
  setDisplayText(p ? truncate(`${p.artist ?? ""} — ${p.title ?? ""}`, MEDIA_MAX_LENGTH) : "")
  setCanPrev(p?.can_go_previous ?? false)
  setCanNext(p?.can_go_next ?? false)
}

const activePlayer = createExternal<Mpris.Player | null>(null, set => {
  const playerHandlers = new Map<Mpris.Player, number[]>()

  const rebind = () => {
    for (const [player, ids] of playerHandlers) {
      for (const id of ids) player.disconnect(id)
    }
    playerHandlers.clear()

    set(pickPlayer())
    syncDerived()

    for (const player of mpris.players) {
      const ids = [
        player.connect("notify::playback-status", () => { set(pickPlayer()); syncDerived() }),
        player.connect("notify::title", () => { set(pickPlayer()); syncDerived() }),
        player.connect("notify::artist", () => { set(pickPlayer()); syncDerived() }),
        player.connect("notify::can-go-next", () => { set(pickPlayer()); syncDerived() }),
        player.connect("notify::can-go-previous", () => { set(pickPlayer()); syncDerived() }),
      ]
      playerHandlers.set(player, ids)
    }
  }

  const playersId = mpris.connect("notify::players", rebind)
  rebind()

  return () => {
    mpris.disconnect(playersId)
    for (const [player, ids] of playerHandlers) {
      for (const id of ids) player.disconnect(id)
    }
  }
})

export const mediaVisible = createComputed(() => activePlayer() !== null)

type ProgressSnapshot = {
  mode: "hidden" | "determinate" | "indeterminate"
  fraction: number
}

// Brute-force: re-read position/length/status from the active player every
// PROGRESS_POLL_MS. Keeps the implementation trivial — no baseline math, no
// signal handlers to keep in sync.
const progress = createPoll<ProgressSnapshot>(
  { mode: "hidden", fraction: 0 },
  PROGRESS_POLL_MS,
  () => {
    const p = pickPlayer()
    if (!p) return { mode: "hidden", fraction: 0 }
    const length = p.length ?? 0
    const position = p.position ?? 0
    if (length > 0) {
      return {
        mode: "determinate",
        fraction: Math.max(0, Math.min(1, position / length)),
      }
    }
    if (p.playback_status === Mpris.PlaybackStatus.PLAYING) {
      return { mode: "indeterminate", fraction: 0 }
    }
    return { mode: "hidden", fraction: 0 }
  }
)

export const progressVisible = createComputed(() => progress().mode !== "hidden")

export function initProgressBar(self: Gtk.Box) {
  const provider = new Gtk.CssProvider()
  self.get_style_context().add_provider(provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

  const apply = (snap: ProgressSnapshot) => {
    if (snap.mode === "determinate") {
      self.remove_css_class("shimmer")
      const p = Math.max(0, Math.min(100, snap.fraction * 100))
      const start = Math.max(0, p - 6)
      const end = Math.min(100, p + 1)
      const css = `* {
        background: linear-gradient(
          to right,
          #EA6926 0%,
          #EA6926 ${start}%,
          #FBC68A ${p}%,
          #1D2021 ${end}%,
          #1D2021 100%
        );
      }`
      provider.load_from_string(css)
    } else if (snap.mode === "indeterminate") {
      provider.load_from_string("")
      self.add_css_class("shimmer")
    } else {
      provider.load_from_string("")
      self.remove_css_class("shimmer")
    }
  }

  apply(progress.get())
  progress.subscribe(() => apply(progress.get()))
}

function initStaticIcon(name: string) {
  return (button: Gtk.Button) => {
    const icon = new Gtk.Image()
    icon.set_from_icon_name(name)
    icon.set_pixel_size(16)
    button.set_child(icon)
  }
}

function initPlayPauseIcon(button: Gtk.Button) {
  const icon = new Gtk.Image()
  icon.set_pixel_size(16)
  button.set_child(icon)

  const apply = () => {
    icon.set_from_icon_name(
      playbackStatus() === Mpris.PlaybackStatus.PLAYING
        ? "media-playback-pause-symbolic"
        : "media-playback-start-symbolic"
    )
  }
  apply()
  playbackStatus.subscribe(apply)
}

export function Media() {
  const mediaTextClass = createComputed(() =>
    hasTallGlyphs(displayText()) ? "media-text compact" : "media-text"
  )

  return (
    <box class="media-container" visible={mediaVisible} valign={Gtk.Align.START}>
      <label class="chevron" name="media-chevron-left" valign={Gtk.Align.CENTER} label={LEFT_TRIANGLE} />
      <button
        class="media-button"
        visible={canPrev}
        onClicked={() => activePlayer()?.previous()}
        onRealize={initStaticIcon("media-skip-backward-symbolic")}
      />
      <button
        class="media-button"
        onClicked={() => activePlayer()?.play_pause()}
        onRealize={initPlayPauseIcon}
      />
      <button
        class="media-button"
        visible={canNext}
        onClicked={() => activePlayer()?.next()}
        onRealize={initStaticIcon("media-skip-forward-symbolic")}
      />
      <label class={mediaTextClass} label={displayText} />
    </box>
  )
}
