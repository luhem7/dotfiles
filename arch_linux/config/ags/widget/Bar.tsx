import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createBinding } from "ags"
import { execAsync } from "ags/process"
import { createPoll } from "ags/time"
import GLib from "gi://GLib"
import Hyprland from "gi://AstalHyprland"

export default function Bar(gdkmonitor: Gdk.Monitor) {
	const time = createPoll("", 1000, "date '+%A %Y-%m-%d %I:%M:%S %p'")
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

								const rebuildButtons = () => {
									// Remove old children
									while (self.get_first_child())
										self.remove(self.get_first_child()!)
									buttons.clear()

									// Add new children
									const focusedId = hyprland.get_focused_workspace()?.id
									hyprland.get_workspaces()
										.filter(ws => ws.id > 0)
										.sort((a, b) => a.id - b.id)
										.forEach(ws => {
											const btn = new Gtk.Button()
											const label = new Gtk.Label({ label: `${ws.id}` })
											btn.set_child(label)
											btn.add_css_class("workspace")
											if (ws.id === focusedId) btn.add_css_class("active")
											btn.connect("clicked", () => ws.focus())
											self.append(btn)
											buttons.set(ws.id, btn)
										})
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

								rebuildButtons()
								hyprland.connect("notify::workspaces", rebuildButtons)
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
						<box>
							<label class="chevron" valign={Gtk.Align.CENTER} label={left_triangle}/>
							<label class="time" label={time} />
							<label class="chevron" name="chevron-right" valign={Gtk.Align.CENTER} label={left_triangle} />
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
