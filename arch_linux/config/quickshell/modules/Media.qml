import QtQuick
import Quickshell.Services.Mpris
import qs.components

Item {
	id: root

	readonly property MprisPlayer player: {
		const players = Array.from(Mpris.players.values);
		return players.find(p => p.playbackState === MprisPlaybackState.Playing)
			?? players.find(p => p.playbackState === MprisPlaybackState.Paused)
			?? null;
	}
	// -1 when the player doesn't report a usable length (browser MPRIS bridges).
	readonly property real progress: player && player.lengthSupported && player.length > 0
		? Math.max(0, Math.min(1, player.position / player.length))
		: -1

	visible: player !== null
	implicitWidth: row.implicitWidth
	implicitHeight: Theme.barHeight

	Row {
		id: row
		anchors.verticalCenter: parent.verticalCenter
		spacing: 2

		BarButton {
			visible: root.player?.canGoPrevious ?? false
			text: Icons.prev
			onClicked: root.player.previous()
		}

		BarButton {
			text: root.player?.isPlaying ? Icons.pause : Icons.play
			onClicked: root.player.togglePlaying()
		}

		BarButton {
			visible: root.player?.canGoNext ?? false
			text: Icons.next
			onClicked: root.player.next()
		}

		Label {
			anchors.verticalCenter: parent.verticalCenter
			leftPadding: 4
			width: Math.min(implicitWidth, 360)
			elide: Text.ElideRight
			text: root.player ? `${root.player.trackArtist} — ${root.player.trackTitle}` : ""
		}
	}

	Rectangle {
		id: track
		anchors {
			left: parent.left
			right: parent.right
			bottom: parent.bottom
			bottomMargin: 1
		}
		height: 2
		radius: 1
		color: Theme.surface
		visible: root.progress >= 0 || (root.player?.isPlaying ?? false)

		// Solid full bar when the length is unknown.
		Rectangle {
			width: root.progress >= 0 ? track.width * root.progress : track.width
			height: track.height
			color: Theme.accent
		}
	}

	// MPRIS doesn't push position updates; poke the property while playing.
	Timer {
		running: root.player?.isPlaying ?? false
		interval: 500
		repeat: true
		onTriggered: root.player.positionChanged()
	}
}
