import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.components

BarButton {
	id: root

	required property PwNode node
	property bool isSink: true

	readonly property real volume: node?.audio?.volume ?? 0
	readonly property bool muted: node?.audio?.muted ?? false

	// Toggling mute directly on the Schiit Magni Unity leaves its anti-pop relay
	// engaged; this script bounces the device profile on unmute. See 1_userland.md.
	readonly property string muteScript: `${Quickshell.env("HOME")}/.local/bin/audio-mute-toggle.sh`

	visible: node !== null
	textColor: muted ? Theme.textMuted : Theme.text
	text: {
		if (!isSink) return muted ? Icons.micOff : Icons.mic;
		if (muted) return Icons.volumeOff;
		return volume > 0.66 ? Icons.volumeHigh : volume > 0.33 ? Icons.volumeMedium : Icons.volumeLow;
	}

	onClicked: {
		if (isSink) Quickshell.execDetached([muteScript]);
		else node.audio.muted = !muted;
	}
	onScrolled: steps => {
		if (node?.audio) node.audio.volume = Math.max(0, Math.min(1.5, volume + steps * 0.05));
	}

	// Audio properties are only live while the node is bound by a tracker.
	PwObjectTracker {
		objects: root.node ? [root.node] : []
	}

	HoverPopup {
		target: root
		show: root.hovered

		Label { text: root.node?.description || root.node?.nickname || "Unknown" }
		Label {
			text: root.muted ? "Muted" : `${Math.round(root.volume * 100)}%`
			color: Theme.textMuted
		}
	}
}
