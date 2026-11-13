import QtQuick
import qs.components
import qs.services

BarButton {
	id: root

	visible: Recorder.recording
	text: Icons.record
	fontSize: Math.round(Theme.iconSize * 1.5)
	textColor: Theme.red
	onClicked: Recorder.stop()

	SequentialAnimation on opacity {
		running: root.visible
		loops: Animation.Infinite
		NumberAnimation { to: 0.4; duration: 800; easing.type: Easing.InOutQuad }
		NumberAnimation { to: 1; duration: 800; easing.type: Easing.InOutQuad }
	}

	HoverPopup {
		target: root
		show: root.hovered

		Label { text: "Recording — click to stop" }
	}
}
