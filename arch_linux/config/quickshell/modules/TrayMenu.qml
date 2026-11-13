import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components

// A tray item's menu drawn in QML so it follows the Theme. Submenus open in
// place, with a "Back" row to return to the parent menu.
PopupWindow {
	id: root

	required property Item target
	required property var handle

	property var stack: []
	readonly property var current: stack.length > 0 ? stack[stack.length - 1] : handle

	function open() {
		stack = [];
		visible = true;
	}

	anchor.item: target
	anchor.edges: Edges.Bottom
	anchor.gravity: Edges.Bottom
	anchor.margins.bottom: -6
	grabFocus: true
	visible: false
	color: "transparent"
	implicitWidth: frame.implicitWidth
	implicitHeight: frame.implicitHeight

	// Only hold the menu open over D-Bus while it's shown.
	QsMenuOpener {
		id: opener
		menu: root.visible ? root.current : null
	}

	WrapperRectangle {
		id: frame
		margin: 4
		color: Theme.surface
		border.color: Theme.border
		border.width: 1
		radius: Theme.radius

		ColumnLayout {
			spacing: 0

			MenuRow {
				visible: root.stack.length > 0
				leading: Icons.chevronLeft
				text: "Back"
				onActivated: root.stack = root.stack.slice(0, -1)
			}

			Repeater {
				model: opener.children

				MenuRow {
					required property QsMenuEntry modelData

					separator: modelData.isSeparator
					enabled: modelData.enabled
					// dbusmenu marks mnemonics with `_`; `__` is a literal underscore.
					text: modelData.text.replace(/_(.)/g, "$1")
					icon: modelData.icon
					leading: modelData.buttonType === QsMenuButtonType.None || modelData.checkState !== Qt.Checked ? ""
						: modelData.buttonType === QsMenuButtonType.RadioButton ? "●" : "✓"
					trailing: modelData.hasChildren ? Icons.chevronRight : ""

					onActivated: {
						if (modelData.hasChildren) {
							root.stack = root.stack.concat([modelData]);
						} else {
							modelData.triggered();
							root.visible = false;
						}
					}
				}
			}
		}
	}

	component MenuRow: Rectangle {
		id: row

		property bool separator: false
		property string text: ""
		property string icon: ""
		property string leading: ""
		property string trailing: ""

		signal activated

		Layout.fillWidth: true
		implicitWidth: content.implicitWidth + Theme.pad * 2
		implicitHeight: separator ? 9 : Theme.itemHeight + 2
		radius: Theme.radius - 2
		color: !separator && enabled && mouse.containsMouse ? Theme.surfaceHover : "transparent"

		Rectangle {
			visible: row.separator
			anchors.centerIn: parent
			width: parent.width - 8
			height: 1
			color: Theme.border
		}

		RowLayout {
			id: content
			visible: !row.separator
			anchors.fill: parent
			anchors.leftMargin: Theme.pad
			anchors.rightMargin: Theme.pad
			spacing: Theme.spacing
			opacity: row.enabled ? 1 : 0.4

			Label {
				visible: row.leading !== ""
				text: row.leading
			}

			IconImage {
				visible: row.icon !== ""
				source: row.icon
				implicitSize: Theme.iconSize
			}

			Label {
				Layout.fillWidth: true
				text: row.text
			}

			Label {
				visible: row.trailing !== ""
				text: row.trailing
				color: Theme.textMuted
			}
		}

		MouseArea {
			id: mouse
			anchors.fill: parent
			hoverEnabled: true
			enabled: !row.separator && row.enabled
			cursorShape: Qt.PointingHandCursor
			onClicked: row.activated()
		}
	}
}
