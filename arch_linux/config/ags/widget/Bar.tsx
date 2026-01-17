import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { execAsync } from "ags/process"
import { createPoll } from "ags/time"
import GLib from "gi://GLib"

export default function Bar(gdkmonitor: Gdk.Monitor) {
	const time = createPoll("", 1000, "date '+%A %Y-%m-%d %I:%M:%S %p'")
	const userhost = `${GLib.get_user_name()}@${GLib.get_host_name()}`
	const left_triangle = ""
	const right_triangle = ""

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
						<label class="chevron" valign={Gtk.Align.CENTER} label={right_triangle} />
						<label class="userhost" label={userhost} />
						<label class="chevron" name="chevron-right" valign={Gtk.Align.CENTER} label={right_triangle} />
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
