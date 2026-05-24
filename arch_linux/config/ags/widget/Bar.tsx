import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createBinding, createComputed, createExternal, createState, For, With, onMount } from "ags"
import { createPoll } from "ags/time"
import { execAsync } from "ags/process"
import GLib from "gi://GLib"
import Hyprland from "gi://AstalHyprland"
import Gtk4LayerShell from "gi://Gtk4LayerShell"
import { getSunTimes, getHourBrightness, brightnessToColor } from "../sun"
import { SysTray } from "./Tray"
import { Speaker, Microphone } from "./Volume"
import { LEFT_TRIANGLE, RIGHT_TRIANGLE } from "../constants"
import { truncate } from "../util"
import { Media, mediaVisible } from "./Media"

const TITLE_MAX_LENGTH = 30
const HOUR_SEGMENTS = 24

const HIGHLIGHT_COLOR = "#EBDBB2"
const YELLOW_ACCENT = "#D79921"
const BASE_COLOR = "#433F3C"

const hyprland = Hyprland.get_default()

const regularWorkspaces = createBinding(hyprland, "workspaces").as(ws =>
	ws.filter(w => w.id > 0).sort((a, b) => a.id - b.id),
)

const specialWorkspace = createBinding(hyprland, "workspaces").as(ws =>
	ws.find(w => w.id < 0) ?? null,
)

const focusedWorkspace = createBinding(hyprland, "focusedWorkspace")
const focusedClient = createBinding(hyprland, "focusedClient")

// True when the focused monitor is currently displaying a special workspace.
// Why custom: there's no top-level Hyprland property for this — it's per-monitor.
// We re-subscribe to each monitor's special-workspace signal when the monitor
// list changes, and disconnect cleanly on scope teardown.
const isSpecialActive = createExternal(false, set => {
	const monitorListeners = new Map<Hyprland.Monitor, number>()
	const refresh = () => set(!!hyprland.focusedMonitor?.specialWorkspace)

	const rebindMonitors = () => {
		for (const [m, id] of monitorListeners) m.disconnect(id)
		monitorListeners.clear()
		for (const m of hyprland.get_monitors()) {
			monitorListeners.set(m, m.connect("notify::special-workspace", refresh))
		}
		refresh()
	}

	const focusedId = hyprland.connect("notify::focused-monitor", refresh)
	const monitorsId = hyprland.connect("notify::monitors", rebindMonitors)
	rebindMonitors()

	return () => {
		hyprland.disconnect(focusedId)
		hyprland.disconnect(monitorsId)
		for (const [m, id] of monitorListeners) m.disconnect(id)
	}
})


// State-flip drives the entering animation via the .entering CSS class on
// .workspace (existing transition handles the fade). Pure @keyframes can't be
// used here: <For> re-parents existing children on every update (unmap+map),
// which would replay keyframe animations on every workspace change.
function createEnteringFlag() {
	const [entering, setEntering] = createState(true)
	onMount(() => {
		GLib.timeout_add(GLib.PRIORITY_DEFAULT, 10, () => {
			setEntering(false)
			return GLib.SOURCE_REMOVE
		})
	})
	return entering
}

function classes(...parts: (string | false | null | undefined)[]): string {
	return parts.filter(Boolean).join(" ")
}

// Workspace clicks dispatch via hyprctl using the new Lua syntax instead of
// ws.focus(). Since Hyprland 0.55, IPC dispatch is interpreted as Lua, so the
// legacy "dispatch workspace <id>" payload that AstalHyprland still emits
// (verified in libastal-hyprland's workspace.c) gets rejected with a parse
// error. The special-workspace toggle below has the same problem. Revisit
// once libastal-hyprland-git updates upstream (broken as of 2026-05-19).
function WorkspaceButton({ ws }: { ws: Hyprland.Workspace }) {
	const entering = createEnteringFlag()
	const className = createComputed(() =>
		classes(
			"workspace",
			focusedWorkspace()?.id === ws.id && !isSpecialActive() && "active",
			entering() && "entering",
		),
	)

	return (
		<button
			class={className}
			onClicked={() => execAsync(["hyprctl", "dispatch", `hl.dsp.focus({ workspace = ${ws.id} })`])}
		>
			<label label={`${ws.id}`} />
		</button>
	)
}

function SpecialWorkspaceButton({ ws }: { ws: Hyprland.Workspace }) {
	const entering = createEnteringFlag()
	const rawName = ws.get_name()
	const name = rawName.startsWith("special:") ? rawName.slice(8) : ""
	const className = createComputed(() =>
		classes("workspace", isSpecialActive() && "active", entering() && "entering"),
	)

	return (
		<button
			class={className}
			onClicked={() => execAsync(["hyprctl", "dispatch", `hl.dsp.workspace.toggle_special("${name}")`])}
		>
			<label label="*" />
		</button>
	)
}

function WindowTitle() {
	const label = focusedClient.as(c => truncate(c?.get_title() || "Desktop", TITLE_MAX_LENGTH))
	return <label class="window-title" label={label} />
}

function initHourSegments(container: Gtk.Box, hourPoll: ReturnType<typeof createPoll<number>>) {
	const segments: Gtk.Box[] = []
	const providers: Gtk.CssProvider[] = []
	let sunTimes = getSunTimes()
	let segmentColors: string[] = []

	const calculateColors = () => {
		segmentColors = []
		for (let i = 0; i < HOUR_SEGMENTS; i++) {
			const brightness = getHourBrightness(i, sunTimes)
			const isDaytime = i >= sunTimes.sunrise && i < sunTimes.sunset

			if (isDaytime) {
				segmentColors.push(brightnessToColor(brightness, BASE_COLOR, 20, YELLOW_ACCENT, 0.3))
			} else {
				segmentColors.push(brightnessToColor(brightness, BASE_COLOR, 10))
			}
		}
	}

	const applyColor = (index: number, color: string) => {
		const segment = segments[index]
		if (providers[index]) {
			segment.get_style_context().remove_provider(providers[index])
		}
		const provider = new Gtk.CssProvider()
		provider.load_from_string(`* { background: ${color}; }`)
		segment.get_style_context().add_provider(provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
		providers[index] = provider
	}

	for (let i = 0; i < HOUR_SEGMENTS; i++) {
		const segment = new Gtk.Box()
		segment.add_css_class("hour-segment")
		segment.set_hexpand(true)
		segments.push(segment)
		container.append(segment)
	}

	calculateColors()

	let prevHour = -1

	const update = () => {
		const currentHour = hourPoll.get()
		if (currentHour === prevHour) return

		if (currentHour === 0) {
			sunTimes = getSunTimes()
			calculateColors()
		}

		if (prevHour >= 0) {
			applyColor(prevHour, segmentColors[prevHour])
		}
		applyColor(currentHour, HIGHLIGHT_COLOR)

		prevHour = currentHour
	}

	segments.forEach((_, i) => applyColor(i, segmentColors[i]))

	update()
	hourPoll.subscribe(update)
}

export default function Bar(gdkmonitor: Gdk.Monitor) {
	const time = createPoll("", 1000, "date '+%A %Y-%m-%d %I:%M:%S %p'")
	const hour = createPoll(new Date().getHours(), 60000, () => new Date().getHours())
	const userhost = `${GLib.get_user_name()}@${GLib.get_host_name()}`

	const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

	const win = (
		<window
			visible={false}
			name="bar"
			class="Bar"
			gdkmonitor={gdkmonitor}
			exclusivity={Astal.Exclusivity.EXCLUSIVE}
			anchor={TOP | LEFT | RIGHT}
			application={app}
		>
			<centerbox cssName="centerbox">
				<box name="startbox" $type="start" hexpand halign={Gtk.Align.START}>
					<box>
						<label name="chevron-open" valign={Gtk.Align.CENTER} label={RIGHT_TRIANGLE} />
						<label class="userhost" label={userhost} />
						<label name="chevron-mid" valign={Gtk.Align.CENTER} label={RIGHT_TRIANGLE} />
						<box class="workspaces">
							<For each={regularWorkspaces} id={ws => ws.id}>
								{ws => <WorkspaceButton ws={ws} />}
							</For>
							<With value={specialWorkspace}>
								{ws => ws && <SpecialWorkspaceButton ws={ws} />}
							</With>
						</box>
						<label name="chevron-yellow-red" valign={Gtk.Align.CENTER} label={RIGHT_TRIANGLE} />
						<WindowTitle />
						<label name="chevron-right" valign={Gtk.Align.CENTER} label={RIGHT_TRIANGLE} />
					</box>
				</box>

				<box $type="center" />

				<box name="endbox" $type="end" hexpand halign={Gtk.Align.END}>
					<Media />
					<box class={mediaVisible.as(v => v ? "tray-container media-active" : "tray-container")} valign={Gtk.Align.START}>
						<label class="chevron" name="tray-chevron-left" valign={Gtk.Align.CENTER} label={LEFT_TRIANGLE} />
						<Speaker />
						<Microphone />
						<SysTray />
					</box>
					<menubutton class="clock">
						<box orientation={Gtk.Orientation.VERTICAL}>
							<box>
								<label class="chevron" valign={Gtk.Align.CENTER} label={LEFT_TRIANGLE} />
								<label class="time" label={time} />
								<label class="chevron" name="chevron-clock-right" valign={Gtk.Align.CENTER} label={LEFT_TRIANGLE} />
							</box>
							<box class="hour-segments" onRealize={(self) => initHourSegments(self, hour)} />
						</box>
						<popover>
							<Gtk.Calendar />
						</popover>
					</menubutton>
					<box class="power-container" valign={Gtk.Align.START}>
						<button
							class="sleep-button"
							tooltip_text="Sleep"
							onClicked={() => execAsync(["systemctl", "suspend"])}
						>
							<label label="󰖔" />
						</button>
						<label class="chevron" name="chevron-power-right" valign={Gtk.Align.CENTER} label={LEFT_TRIANGLE} />
					</box>
				</box>
			</centerbox>
		</window>
	) as Astal.Window

	// Set layer BEFORE showing window (must be done before mapping)
	Gtk4LayerShell.set_layer(win, Gtk4LayerShell.Layer.BOTTOM)
	win.set_visible(true)

	return win
}
