import QtQuick
import Quickshell
import qs.components
import "../services/sun.js" as Sun

Item {
	id: root

	readonly property int day: clock.date.getDate()
	property var hourColors: computeHourColors()

	function computeHourColors() {
		return Sun.hourColors(Theme.surfaceHover.toString(), Theme.accent.toString());
	}

	// Sunrise/sunset shift daily.
	onDayChanged: hourColors = computeHourColors()

	implicitWidth: pill.implicitWidth
	implicitHeight: Theme.barHeight

	SystemClock {
		id: clock
		precision: SystemClock.Seconds
	}

	BarButton {
		id: pill
		anchors.verticalCenter: parent.verticalCenter
		text: Qt.formatDateTime(clock.date, "dddd yyyy-MM-dd  hh:mm:ss AP")
		fontSize: Theme.fontSize
		highlighted: calendar.visible
		onClicked: calendar.visible = !calendar.visible
	}

	// One segment per hour of the day, brightest around solar noon.
	Row {
		id: hours
		anchors {
			left: pill.left
			right: pill.right
			bottom: parent.bottom
			bottomMargin: 1
		}
		height: 2
		spacing: 1

		Repeater {
			model: 24

			Rectangle {
				required property int index
				width: (hours.width - 23) / 24
				height: hours.height
				radius: 1
				color: index === clock.hours ? Theme.text : root.hourColors[index]
			}
		}
	}

	CalendarPopup {
		id: calendar
		target: pill
	}
}
