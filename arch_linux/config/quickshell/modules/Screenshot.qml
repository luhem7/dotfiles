import QtQuick
import Quickshell
import qs.components
import qs.services

BarButton {
	id: root

	text: Icons.camera
	onClicked: button => {
		if (button === Qt.LeftButton) Quickshell.execDetached(["hyprshot", "-m", "region", "--clipboard-only"]);
		else if (button === Qt.RightButton) Recorder.start();
	}

	HoverPopup {
		target: root
		show: root.hovered

		Label { text: "Left click: screenshot region · Right click: record window" }
	}
}
