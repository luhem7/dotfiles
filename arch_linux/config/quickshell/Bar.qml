import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs.components
import qs.modules
import qs.services

PanelWindow {
	id: bar

	required property ShellScreen modelData
	property string hostname: ""

	screen: modelData
	anchors {
		top: true
		left: true
		right: true
	}
	implicitHeight: Theme.barHeight
	color: Theme.bg
	// Bottom layer so fullscreen windows cover the bar. Hyprland draws the
	// special workspace above Bottom, so rise to Top while it's shown.
	WlrLayershell.layer: SpecialWorkspace.active ? WlrLayer.Top : WlrLayer.Bottom
	WlrLayershell.namespace: "quickshell-bar"

	Process {
		running: true
		command: ["uname", "-n"]
		stdout: StdioCollector {
			id: hostOut
			onStreamFinished: bar.hostname = hostOut.text.trim()
		}
	}

	RowLayout {
		anchors {
			left: parent.left
			leftMargin: Theme.pad
			right: rightSide.left
			rightMargin: Theme.pad * 2
			verticalCenter: parent.verticalCenter
		}
		spacing: Theme.spacing * 2

		RowLayout {
			// Nested layouts fill by default, which would push the title right.
			Layout.fillWidth: false
			spacing: 2

			Label {
				text: `${Quickshell.env("USER")}@${bar.hostname}`
				color: Theme.textMuted
			}

			Workspaces {}
		}

		WindowTitle {
			// 50px total gap after the workspaces, including the row spacing.
			Layout.leftMargin: 50 - parent.spacing
			Layout.fillWidth: true
			Layout.maximumWidth: 480
		}

		// Absorbs leftover width so the title stays next to the workspaces.
		Item { Layout.fillWidth: true }
	}

	RowLayout {
		id: rightSide
		anchors {
			right: parent.right
			rightMargin: Theme.pad
			top: parent.top
			bottom: parent.bottom
		}
		spacing: Theme.spacing

		Media {
			Layout.fillHeight: true
			Layout.rightMargin: Theme.spacing
		}

		AudioButton { node: Pipewire.defaultAudioSink }

		AudioButton {
			node: Pipewire.defaultAudioSource
			isSink: false
		}

		Screenshot {}

		RecordingIndicator {}

		Containers {}

		Tray {}

		Clock {
			Layout.fillHeight: true
			Layout.leftMargin: Theme.spacing
		}

		Power {}
	}
}
