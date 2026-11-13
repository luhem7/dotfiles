import QtQuick
import Quickshell.Hyprland
import qs.components
import qs.services

Row {
	id: root

	// Special workspaces have no numeric id since Hyprland 0.57; match by name.
	readonly property var all: Array.from(Hyprland.workspaces.values)
	readonly property var regular: all
		.filter(ws => ws.id > 0 && !ws.name.startsWith("special:"))
		.sort((a, b) => a.id - b.id)
	readonly property var special: all.find(ws => ws.name.startsWith("special:")) ?? null

	spacing: 2

	Repeater {
		model: root.regular

		BarButton {
			required property HyprlandWorkspace modelData

			text: String(modelData.id)
			fontSize: Theme.fontSize
			highlighted: modelData.focused && !SpecialWorkspace.active
			onClicked: modelData.activate()
		}
	}

	BarButton {
		visible: root.special !== null
		text: "*"
		fontSize: Theme.fontSize
		highlighted: SpecialWorkspace.active
		onClicked: SpecialWorkspace.toggle(root.special.name)
	}
}
