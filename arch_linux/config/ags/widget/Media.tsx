import { Gtk } from "ags/gtk4"
import { createExternal, createState, createComputed } from "ags"
import Mpris from "gi://AstalMpris"
import { LEFT_TRIANGLE } from "../constants"
import { truncate, hasTallGlyphs } from "../util"

const MEDIA_MAX_LENGTH = 40

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

function syncDerived() {
  const p = pickPlayer()
  setPlaybackStatus(p?.playback_status ?? null)
  setDisplayText(p ? truncate(`${p.artist ?? ""} — ${p.title ?? ""}`, MEDIA_MAX_LENGTH) : "")
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

export function Media() {
  const playPauseIcon = createComputed(() =>
    playbackStatus() === Mpris.PlaybackStatus.PLAYING ? "󰏤" : "󰐊"
  )
  const mediaTextClass = createComputed(() =>
    hasTallGlyphs(displayText()) ? "media-text compact" : "media-text"
  )

  return (
    <box class="media-container" visible={mediaVisible} valign={Gtk.Align.START}>
      <label class="chevron" name="media-chevron-left" valign={Gtk.Align.CENTER} label={LEFT_TRIANGLE} />
      <button
        class="media-button"
        onClicked={() => activePlayer()?.play_pause()}
      >
        <label label={playPauseIcon} />
      </button>
      <label class={mediaTextClass} label={displayText} />
    </box>
  )
}
