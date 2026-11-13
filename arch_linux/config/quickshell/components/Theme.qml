pragma Singleton

import QtQuick
import Quickshell

Singleton {
	readonly property int barHeight: 32
	readonly property int itemHeight: 24
	readonly property int radius: 6
	readonly property int spacing: 6
	readonly property int pad: 8

	readonly property color bg: "#15171c"
	readonly property color surface: "#22252d"
	readonly property color surfaceHover: "#2f333d"
	readonly property color border: "#3a3f4b"
	readonly property color text: "#d6d9df"
	readonly property color textMuted: "#858b97"
	readonly property color accent: "#e5a54b"
	readonly property color red: "#e06c75"
	readonly property color green: "#8fbf7f"
	readonly property color blue: "#7aa2d6"
	readonly property color trayHalo: "#73ffffff" // white, 45% alpha

	readonly property string font: "JetBrainsMono Nerd Font"
	readonly property real fontScale: 1.2
	readonly property int fontSize: Math.round(12 * fontScale)
	readonly property int iconSize: Math.round(15 * fontScale)
}
