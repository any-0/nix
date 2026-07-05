import QtQuick
import Quickshell
import Quickshell.Wayland._WlrLayerShell

PanelWindow {
    id: bar

    required property var screenInfo
    readonly property int barHeight: 42

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
    exclusionMode: ExclusionMode.Auto
    aboveWindows: true
    focusable: false
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-bar-" + screenInfo.name

    Item {
        id: barRoot
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.topMargin: 6
        anchors.bottomMargin: 6

        StatusPill {
            id: leftPill
            anchorWindow: bar
            anchorOffsetX: barRoot.x
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            id: workspacePill
            height: 30
            radius: 15
            color: Theme.surface
            border.color: Theme.surfaceBorder
            border.width: 1
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: workspaceRow.implicitWidth + 20

            Workspaces {
                id: workspaceRow
                screenName: bar.screenInfo.name
                anchors.centerIn: parent
            }
        }

        ClockPower {
            id: rightPill
            anchorWindow: bar
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
