pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Whether the focused monitor is currently showing a special workspace.
// Quickshell doesn't track `activespecial` itself, so re-read the monitors'
// IPC objects whenever Hyprland announces a change; `specialWorkspace.name` is
// empty while it is hidden.
//
// `active` is assigned from handlers rather than bound: as a binding it was
// re-evaluated while a reload tore down the previous config, logging
// "Unable to assign [undefined] to bool".
Singleton {
	id: root

	property bool active: false

	function refresh() {
		active = !!Hyprland.focusedMonitor?.lastIpcObject?.specialWorkspace?.name;
	}

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

		function onFocusedMonitorChanged() {
			root.refresh();
		}
	}

	Connections {
		target: Hyprland.focusedMonitor

		function onLastIpcObjectChanged() {
			root.refresh();
		}
	}

	Component.onCompleted: {
		Hyprland.refreshMonitors();
		refresh();
	}
}
