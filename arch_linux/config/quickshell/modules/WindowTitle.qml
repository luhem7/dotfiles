import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.components

RowLayout {
	id: root

	// Wayland's foreign-toplevel state, rather than Hyprland IPC: it reports the
	// focused window at startup and clears when nothing is focused.
	readonly property var toplevel: ToplevelManager.activeToplevel
	readonly property string appId: toplevel?.appId ?? ""
	readonly property string iconSource: {
		if (appId === "") return "";
		// Desktop entries are scanned asynchronously; re-run once they load.
		DesktopEntries.applications.values;
		const entry = DesktopEntries.heuristicLookup(appId);
		return Quickshell.iconPath(entry?.icon || appId, true);
	}

	spacing: Theme.spacing

	IconImage {
		visible: root.iconSource !== ""
		source: root.iconSource
		implicitSize: Theme.iconSize
	}

	Label {
		Layout.fillWidth: true
		text: root.toplevel?.title || "Desktop"
		elide: Text.ElideRight
	}
}
