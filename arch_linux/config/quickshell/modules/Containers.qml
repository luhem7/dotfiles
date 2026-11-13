import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.components

BarButton {
	id: root

	property var rows: []

	readonly property var cells: {
		const out = ["", "Container", "Status", "Image", "Started", "Command", "Ports"]
			.map(text => ({ text, color: Theme.textMuted, bold: true }));
		for (const row of rows) {
			out.push({ text: "●", color: stateColor(row), bold: false });
			out.push({ text: row.name, color: Theme.text, bold: true });
			for (const text of [cleanStatus(row.status), row.image, row.created.slice(0, 16),
					row.command || "—", row.ports.trim() || "—"])
				out.push({ text, color: Theme.textMuted, bold: false });
		}
		return out;
	}

	function stateColor(row) {
		const s = row.status.toLowerCase();
		if (row.state === "paused" || s.includes("(paused)")) return Theme.blue;
		if (s.includes("(unhealthy)")) return Theme.red;
		if (s.includes("(starting)")) return Theme.accent;
		if (row.state === "running") return Theme.green;
		return Theme.textMuted;
	}

	// The dot already conveys health/pause state.
	function cleanStatus(status) {
		return status.replace(/\s*\((healthy|unhealthy|starting|paused)\)\s*$/i, "").trim();
	}

	function parse(text) {
		return text.split("\n").map(l => l.trim()).filter(Boolean).map(l => {
			const f = l.split("\t");
			return {
				name: f[0] ?? "", state: f[1] ?? "", status: f[2] ?? "", image: f[3] ?? "",
				created: f[4] ?? "", command: f[5] ?? "", ports: f[6] ?? "",
			};
		});
	}

	text: `${Icons.docker} ${rows.length}`
	fontSize: Theme.fontSize
	textColor: rows.length > 0 ? Theme.text : Theme.textMuted
	onClicked: ps.running = true

	Process {
		id: ps
		command: ["podman", "ps", "--format",
			["{{.Names}}", "{{.State}}", "{{.Status}}", "{{.Image}}", "{{.CreatedAt}}", "{{.Command}}", "{{.Ports}}"].join("\t")]
		stdout: StdioCollector {
			id: out
			onStreamFinished: root.rows = root.parse(out.text)
		}
	}

	Timer {
		interval: 5000
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: ps.running = true
	}

	HoverPopup {
		target: root
		show: root.hovered

		Label {
			visible: root.rows.length === 0
			text: "No running containers"
		}

		GridLayout {
			visible: root.rows.length > 0
			columns: 7
			rowSpacing: 4
			columnSpacing: 12

			Repeater {
				model: root.cells

				Label {
					required property var modelData
					text: modelData.text
					color: modelData.color
					font.bold: modelData.bold
				}
			}
		}
	}
}
