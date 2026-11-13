pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Whether the focused monitor is currently showing a special workspace.
// Quickshell doesn't track `activespecial` itself, so re-read the monitors'
// IPC objects whenever Hyprland announces a change; `specialWorkspace.name` is
// empty while it is hidden.
Singleton {
	readonly property bool active: !!Hyprland.focusedMonitor?.lastIpcObject?.specialWorkspace?.name

	function toggle(workspaceName: string) {
		const name = workspaceName.replace(/^special:/, "");
		Hyprland.dispatch(Hyprland.usingLua
			? `hl.dsp.workspace.toggle_special("${name}")`
			: `togglespecialworkspace ${name}`);
	}

	Connections {
		target: Hyprland

		function onRawEvent(event) {
			if (event.name.startsWith("activespecial")) Hyprland.refreshMonitors();
		}
	}

	Component.onCompleted: Hyprland.refreshMonitors()
}
