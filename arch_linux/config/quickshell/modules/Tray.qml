import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.components

Row {
	spacing: 2

	Repeater {
		model: SystemTray.items

		Rectangle {
			id: item

			required property SystemTrayItem modelData

			implicitWidth: Theme.itemHeight
			implicitHeight: Theme.itemHeight
			radius: Theme.radius
			color: mouse.containsMouse ? Theme.surfaceHover : "transparent"

			IconImage {
				id: icon
				anchors.centerIn: parent
				source: item.modelData.icon
				implicitSize: 16
				visible: false
			}

			// Soft light halo so dark icons stay legible on the dark bar.
			MultiEffect {
				anchors.fill: icon
				source: icon
				shadowEnabled: true
				shadowColor: Theme.trayHalo
				shadowBlur: 0.4
				shadowHorizontalOffset: 0
				shadowVerticalOffset: 0
			}

			MouseArea {
				id: mouse
				anchors.fill: parent
				hoverEnabled: true
				cursorShape: Qt.PointingHandCursor
				acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

				onClicked: event => {
					const tray = item.modelData;
					if (event.button === Qt.LeftButton && !tray.onlyMenu) {
						tray.activate();
					} else if (event.button === Qt.MiddleButton) {
						tray.secondaryActivate();
					} else if (tray.hasMenu) {
						trayMenu.open();
					}
				}
				onWheel: event => item.modelData.scroll(event.angleDelta.y, false)
			}

			TrayMenu {
				id: trayMenu
				target: item
				handle: item.modelData.menu
			}

			HoverPopup {
				target: item
				show: mouse.containsMouse && !trayMenu.visible

				Label { text: item.modelData.tooltipTitle || item.modelData.title || item.modelData.id }
			}
		}
	}
}
