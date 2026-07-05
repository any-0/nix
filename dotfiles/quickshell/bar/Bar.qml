import QtQuick
import Quickshell
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Wayland._BackgroundEffect

PanelWindow {
    id: bar

    required property var screenInfo
    readonly property int barHeight: 30

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
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
