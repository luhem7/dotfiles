import QtQuick
import Quickshell
import Quickshell.Widgets

// Tooltip-style popup below `target`. A plain QtQuick ToolTip would be clipped
// to the bar's 32px surface, so this is its own xdg_popup.
PopupWindow {
	id: root

	required property Item target
	property bool show: false
	default property alias content: body.data

	anchor.item: target
	anchor.edges: Edges.Bottom
	anchor.gravity: Edges.Bottom
	anchor.margins.bottom: -6
	visible: show
	color: "transparent"
	implicitWidth: frame.implicitWidth
	implicitHeight: frame.implicitHeight

	WrapperRectangle {
		id: frame
		margin: Theme.pad
		color: Theme.surface
		border.color: Theme.border
		border.width: 1
		radius: Theme.radius

		Column {
			id: body
			spacing: 4
		}
	}
}
