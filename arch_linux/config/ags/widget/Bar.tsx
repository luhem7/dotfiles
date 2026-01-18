import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createPoll } from "ags/time"
import GLib from "gi://GLib"
import Hyprland from "gi://AstalHyprland"

const LEFT_TRIANGLE = "" // Ctrl+v u e0b2
const RIGHT_TRIANGLE = "" // Ctrl+v u e0b0
const TITLE_MAX_LENGTH = 30
const HOUR_SEGMENTS = 24

// Singleton instances
const hyprland = Hyprland.get_default()

function getWorkspaces() {
	return hyprland.get_workspaces()
		.filter(ws => ws.id > 0)
		.sort((a, b) => a.id - b.id)
}

function truncate(text: string, maxLength: number): string {
	return text.length > maxLength ? text.slice(0, maxLength) + "…" : text
}

function initWorkspaces(container: Gtk.Box) {
	const buttons = new Map<number, Gtk.Button>()

	const createButton = (ws: Hyprland.Workspace, animate: boolean) => {
		const btn = new Gtk.Button()
		btn.set_child(new Gtk.Label({ label: `${ws.id}` }))
		btn.add_css_class("workspace")
		btn.connect("clicked", () => ws.focus())
		buttons.set(ws.id, btn)

		if (animate) {
			btn.add_css_class("entering")
			GLib.timeout_add(GLib.PRIORITY_DEFAULT, 10, () => {
				btn.remove_css_class("entering")
				return GLib.SOURCE_REMOVE
			})
		}
		return btn
	}

	const updateFocus = () => {
		const focusedId = hyprland.get_focused_workspace()?.id
		buttons.forEach((btn, id) => {
			btn[id === focusedId ? "add_css_class" : "remove_css_class"]("active")
		})
	}

	const sync = () => {
		const workspaces = getWorkspaces()
		const currentIds = new Set(workspaces.map(ws => ws.id))

		// Remove stale buttons
		buttons.forEach((btn, id) => {
			if (!currentIds.has(id)) {
				container.remove(btn)
				buttons.delete(id)
			}
		})

		// Clear and rebuild in order
		while (container.get_first_child()) {
			container.remove(container.get_first_child()!)
		}

		workspaces.forEach(ws => {
			const btn = buttons.get(ws.id) ?? createButton(ws, true)
			container.append(btn)
		})

		updateFocus()
	}

	// Initial build without animation
	getWorkspaces().forEach(ws => container.append(createButton(ws, false)))
	updateFocus()

	// Connect signals
	hyprland.connect("notify::workspaces", sync)
	hyprland.connect("notify::focused-workspace", updateFocus)
}

function initWindowTitle(label: Gtk.Label) {
	const update = () => {
		const title = hyprland.get_focused_client()?.get_title() || "Desktop"
		label.set_label(truncate(title, TITLE_MAX_LENGTH))
	}
	update()
	hyprland.connect("notify::focused-client", update)
}

function initHourSegments(container: Gtk.Box, hourPoll: ReturnType<typeof createPoll<number>>) {
	const segments: Gtk.Box[] = []

	for (let i = 0; i < HOUR_SEGMENTS; i++) {
		const segment = new Gtk.Box()
		segment.add_css_class("hour-segment")
		segment.set_hexpand(true)
		segments.push(segment)
		container.append(segment)
	}

	const update = () => {
		const currentHour = hourPoll.get()
		segments.forEach((seg, i) => {
			seg[i === currentHour ? "add_css_class" : "remove_css_class"]("active")
		})
	}

	update()
	hourPoll.subscribe(update)
}

export default function Bar(gdkmonitor: Gdk.Monitor) {
	const time = createPoll("", 1000, "date '+%A %Y-%m-%d %I:%M:%S %p'")
	const hour = createPoll(new Date().getHours(), 60000, () => new Date().getHours())
	const userhost = `${GLib.get_user_name()}@${GLib.get_host_name()}`

	const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

	return (
		<window
			visible
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
						<box class="workspaces" onRealize={initWorkspaces} />
						<label name="chevron-yellow-red" valign={Gtk.Align.CENTER} label={RIGHT_TRIANGLE} />
						<label class="window-title" onRealize={initWindowTitle} />
						<label name="chevron-right" valign={Gtk.Align.CENTER} label={RIGHT_TRIANGLE} />
					</box>
				</box>

				{/* Center: empty */}
				<box $type="center" />

				<box name="endbox" $type="end" hexpand halign={Gtk.Align.END}>
					<menubutton class="clock">
						<box orientation={Gtk.Orientation.VERTICAL}>
							<box>
								<label class="chevron" valign={Gtk.Align.CENTER} label={LEFT_TRIANGLE} />
								<label class="time" label={time} />
								<label class="chevron" name="chevron-right" valign={Gtk.Align.CENTER} label={LEFT_TRIANGLE} />
							</box>
							<box class="hour-segments" onRealize={(self) => initHourSegments(self, hour)} />
						</box>
						<popover>
							<Gtk.Calendar />
						</popover>
					</menubutton>
				</box>
			</centerbox>
		</window>
	)
}
