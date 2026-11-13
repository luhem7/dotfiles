import QtQuick
import Quickshell
import qs.components

BarButton {
	id: root

	text: Icons.sleep
	onClicked: Quickshell.execDetached(["systemctl", "suspend"])

	HoverPopup {
		target: root
		show: root.hovered

		Label { text: "Sleep" }
	}
}
