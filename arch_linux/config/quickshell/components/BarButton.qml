import QtQuick

Rectangle {
	id: root

	property alias text: label.text
	property color textColor: Theme.text
	property int fontSize: Theme.iconSize
	property bool highlighted: false
	readonly property alias hovered: mouse.containsMouse

	signal clicked(int button)
	signal scrolled(int steps)

	implicitWidth: Math.max(Theme.itemHeight, label.implicitWidth + Theme.pad * 2)
	implicitHeight: Theme.itemHeight
	radius: Theme.radius
	color: highlighted ? Theme.accent : mouse.containsMouse ? Theme.surfaceHover : "transparent"

	Behavior on color {
		ColorAnimation { duration: 120 }
	}

	Text {
		id: label
		anchors.centerIn: parent
		color: root.highlighted ? Theme.bg : root.textColor
		font.family: Theme.font
		font.pixelSize: root.fontSize
	}

	MouseArea {
		id: mouse
		anchors.fill: parent
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor
		acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
		onClicked: event => root.clicked(event.button)
		onWheel: event => root.scrolled(event.angleDelta.y > 0 ? 1 : -1)
	}
}
