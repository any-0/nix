import QtQuick
import Quickshell
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Wayland._BackgroundEffect

PanelWindow {
    id: bar

    required property var screenInfo
    property bool desktopClockVisible: false
    property real desktopClockSlotWidth: 0
    readonly property int barHeight: 30
    // Screen coords of the bar clock's resting center, for the desktop clock
    // handoff (bar spans the full screen width at y 0, so window == screen).
    readonly property real clockCenterX: width - 12 - rightGroup.clockCenterOffsetFromRight
    readonly property real clockCenterY: barHeight / 2
    // Screen coords of the status icon centers, for the desktop overlay.
    readonly property real networkIconCenterX: barRoot.x + leftGroup.x + leftGroup.networkIconCenterX
    readonly property real volumeIconCenterX: barRoot.x + leftGroup.x + leftGroup.volumeIconCenterX
    readonly property real volumeLabelCenterX: barRoot.x + leftGroup.x + leftGroup.volumeLabelCenterX
    readonly property real bluetoothIconCenterX: barRoot.x + leftGroup.x + leftGroup.bluetoothIconCenterX

    BackgroundEffect.blurRegion: Region {
        width: bar.width
        height: bar.height
    }

    screen: screenInfo
    visible: true
    color: "transparent"
    implicitHeight: barHeight
    anchors {
        top: true
        left: true
        right: true
    }
    exclusiveZone: barHeight
    exclusionMode: ExclusionMode.Normal
    aboveWindows: true
    focusable: false
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-bar-" + screenInfo.name

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: Popups.closeOpenPopup()
    }

    Item {
        id: barRoot

        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        StatusPill {
            id: leftGroup

            anchorWindow: bar
            desktopMode: bar.desktopClockVisible
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }

        Workspaces {
            id: workspaceGroup

            screenName: bar.screenInfo.name
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
        }

        ClockPower {
            id: rightGroup

            anchorWindow: bar
            desktopClockVisible: bar.desktopClockVisible
            clockSlotWidth: bar.desktopClockSlotWidth
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
