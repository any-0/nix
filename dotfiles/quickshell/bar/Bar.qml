import QtQuick
import Quickshell
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Wayland._BackgroundEffect

PanelWindow {
    id: bar

    required property var screenInfo
    property bool showMetrics: false
    readonly property real deviceSpacing: 24
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
        color: Theme.barBg

        // Hairline edge so the bar stays defined over busy wallpapers.
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Qt.rgba(1, 1, 1, 0.07)
        }
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

        Row {
            id: hardwareGroup
            visible: bar.showMetrics
            x: leftGroup.x + leftGroup.width + 24
            anchors.verticalCenter: parent.verticalCenter
            spacing: bar.deviceSpacing

            Column {
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: ["CPU", "GPU"]
                    delegate: Text {
                        required property string modelData
                        text: modelData
                        height: 12
                        verticalAlignment: Text.AlignVCenter
                        font.family: Theme.barFontFamily
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: Theme.textMuted
                    }
                }
            }

            HardwareStatus {}

            Rectangle {
                width: 1
                height: 16
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.track
            }

            HardwareReadout {
                hostName: "SRV"
                sample: RemoteMetrics.proxmox.sample
                cpuUsage: sample ? sample.cpu : -1
                cpuPower: sample && sample.cpuPower !== null ? sample.cpuPower : -1
            }

            Rectangle {
                width: 1
                height: 16
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.track
            }

            HardwareReadout {
                hostName: "NEO"
                sample: RemoteMetrics.mac.sample
                cpuUsage: sample ? sample.cpu : -1
                cpuPower: sample && sample.cpuPower !== null ? sample.cpuPower : -1
            }
        }

        Workspaces {
            id: workspaceGroup

            screenName: bar.screenInfo.name
            x: bar.showMetrics
                ? Math.max((parent.width - width) / 2, hardwareGroup.x + hardwareGroup.width + 24)
                : (parent.width - width) / 2
            anchors.verticalCenter: parent.verticalCenter
        }

        StorageStatus {
            id: storageGroup
            anchorWindow: bar
            spacing: 14
            visible: bar.showMetrics
            anchors.right: rightGroup.left
            anchors.rightMargin: 28
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
