pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// gpu-screen-recorder state, polled so recordings started elsewhere show up.
Singleton {
	id: root

	// pgrep matches the process name, which the kernel truncates to 15 chars.
	readonly property string proc: "gpu-screen-rec"
	readonly property string home: Quickshell.env("HOME")
	property bool recording: false

	function start() {
		Quickshell.execDetached(["sh", "-c",
			`pgrep ${proc} >/dev/null || ${home}/.local/bin/record-window.sh -o ${home}/Videos`]);
	}

	// SIGINT so gpu-screen-recorder finalizes the file cleanly.
	function stop() {
		Quickshell.execDetached(["pkill", "-INT", proc]);
	}

	Process {
		id: probe
		command: ["pgrep", root.proc]
		onExited: code => root.recording = code === 0
	}

	Timer {
		interval: 1000
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: probe.running = true
	}
}
