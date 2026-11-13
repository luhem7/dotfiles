import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components

PopupWindow {
	id: root

	required property Item target
	property int month: new Date().getMonth()
	property int year: new Date().getFullYear()

	function shift(delta) {
		const d = new Date(year, month + delta, 1);
		month = d.getMonth();
		year = d.getFullYear();
	}

	anchor.item: target
	anchor.edges: Edges.Bottom
	anchor.gravity: Edges.Bottom
	anchor.margins.bottom: -6
	grabFocus: true
	visible: false
	color: "transparent"
	implicitWidth: 260
	implicitHeight: frame.implicitHeight

	onVisibleChanged: {
		if (!visible) return;
		const now = new Date();
		month = now.getMonth();
		year = now.getFullYear();
	}

	WrapperRectangle {
		id: frame
		anchors.fill: parent
		margin: Theme.pad
		color: Theme.surface
		border.color: Theme.border
		border.width: 1
		radius: Theme.radius

		ColumnLayout {
			spacing: 4

			RowLayout {
				Layout.fillWidth: true

				BarButton {
					text: Icons.chevronLeft
					onClicked: root.shift(-1)
				}

				Label {
					Layout.fillWidth: true
					horizontalAlignment: Text.AlignHCenter
					font.bold: true
					text: Qt.locale().standaloneMonthName(root.month) + " " + root.year
				}

				BarButton {
					text: Icons.chevronRight
					onClicked: root.shift(1)
				}
			}

			QQC.DayOfWeekRow {
				Layout.fillWidth: true
				locale: grid.locale

				delegate: Label {
					required property string shortName
					text: shortName
					horizontalAlignment: Text.AlignHCenter
					color: Theme.textMuted
				}
			}

			QQC.MonthGrid {
				id: grid
				Layout.fillWidth: true
				month: root.month
				year: root.year

				delegate: Label {
					required property var model
					text: model.day
					horizontalAlignment: Text.AlignHCenter
					opacity: model.month === grid.month ? 1 : 0.35
					color: model.today ? Theme.accent : Theme.text
					font.bold: model.today
				}
			}
		}
	}
}
