import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createBinding } from "ags"
import { execAsync } from "ags/process"
import { createPoll } from "ags/time"
import GLib from "gi://GLib"
import Hyprland from "gi://AstalHyprland"

export default function Bar(gdkmonitor: Gdk.Monitor) {
	const time = createPoll("", 1000, "date '+%A %Y-%m-%d %I:%M:%S %p'")
	const hour = createPoll(new Date().getHours(), 60000, () => new Date().getHours())
	const userhost = `${GLib.get_user_name()}@${GLib.get_host_name()}`
	const left_triangle = ""
	const right_triangle = ""

	const hyprland = Hyprland.get_default()

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
						<label name="chevron-open" valign={Gtk.Align.CENTER} label={right_triangle} />
						<label class="userhost" label={userhost} />
						<label name="chevron-mid" valign={Gtk.Align.CENTER} label={right_triangle} />
						<box
							class="workspaces"
							onRealize={(self) => {
								const buttons = new Map<number, Gtk.Button>()

								const createButton = (ws: Hyprland.Workspace, animate: boolean) => {
									const btn = new Gtk.Button()
									const label = new Gtk.Label({ label: `${ws.id}` })
									btn.set_child(label)
									btn.add_css_class("workspace")
									if (animate) btn.add_css_class("entering")
									btn.connect("clicked", () => ws.focus())
									buttons.set(ws.id, btn)
									if (animate) {
										GLib.timeout_add(GLib.PRIORITY_DEFAULT, 10, () => {
											btn.remove_css_class("entering")
											return GLib.SOURCE_REMOVE
										})
									}
									return btn
								}

								const syncWorkspaces = () => {
									const workspaces = hyprland.get_workspaces()
										.filter(ws => ws.id > 0)
										.sort((a, b) => a.id - b.id)
									const currentIds = new Set(workspaces.map(ws => ws.id))
									const existingIds = new Set(buttons.keys())

									// Remove buttons for workspaces that no longer exist
									existingIds.forEach(id => {
										if (!currentIds.has(id)) {
											const btn = buttons.get(id)
											if (btn) self.remove(btn)
											buttons.delete(id)
										}
									})

									// Rebuild the box in correct order, creating new buttons as needed
									while (self.get_first_child())
										self.remove(self.get_first_child()!)

									workspaces.forEach(ws => {
										const isNew = !existingIds.has(ws.id)
										let btn = buttons.get(ws.id)
										if (!btn) {
											btn = createButton(ws, true)
										}
										self.append(btn)
									})

									updateFocus()
								}

								const updateFocus = () => {
									const focusedId = hyprland.get_focused_workspace()?.id
									buttons.forEach((btn, id) => {
										if (id === focusedId) {
											btn.add_css_class("active")
										} else {
											btn.remove_css_class("active")
										}
									})
								}

								// Initial build (no animation)
								hyprland.get_workspaces()
									.filter(ws => ws.id > 0)
									.sort((a, b) => a.id - b.id)
									.forEach(ws => {
										const btn = createButton(ws, false)
										self.append(btn)
									})
								updateFocus()

								hyprland.connect("notify::workspaces", syncWorkspaces)
								hyprland.connect("notify::focused-workspace", updateFocus)
							}}
						/>
						<label name="chevron-right" valign={Gtk.Align.CENTER} label={right_triangle} />
					</box>
				</box>
				{/* <button
					$type="start"
					onClicked={() => execAsync("echo hello").then(console.log)}
					hexpand
					halign={Gtk.Align.CENTER}
				>
					<label label="Welcome to AGS!" />
				</button> */}
				<box $type="center" />
				<box name="endbox" $type="end" hexpand halign={Gtk.Align.END}>
					<menubutton class="clock">
						<box orientation={Gtk.Orientation.VERTICAL}>
							<box>
								<label class="chevron" valign={Gtk.Align.CENTER} label={left_triangle}/>
								<label class="time" label={time} />
								<label class="chevron" name="chevron-right" valign={Gtk.Align.CENTER} label={left_triangle} />
							</box>
							<box
								class="hour-segments"
								onRealize={(self) => {
									const segments: Gtk.Box[] = []

									// Create 24 hour segments
									for (let i = 0; i < 24; i++) {
										const segment = new Gtk.Box()
										segment.add_css_class("hour-segment")
										segment.set_hexpand(true)
										segments.push(segment)
										self.append(segment)
									}

									// Update active segment based on current hour
									const updateHour = () => {
										const currentHour = hour.get()
										segments.forEach((seg, i) => {
											if (i === currentHour) {
												seg.add_css_class("active")
											} else {
												seg.remove_css_class("active")
											}
										})
									}

									updateHour()
									hour.subscribe(updateHour)
								}}
							/>
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
