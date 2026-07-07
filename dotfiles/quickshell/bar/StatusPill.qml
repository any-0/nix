import QtQuick

Item {
    id: root

    required property var anchorWindow
    property bool desktopMode: false
    property bool desktopModeActive: false

    // Icon glyph centers relative to this item, for the desktop overlay
    // (which renders the actual glyphs; see BarButton.iconGhost).
    readonly property real networkIconCenterX: leftRow.x + networkButton.x + networkButton.iconCenterX
    readonly property real volumeIconCenterX: leftRow.x + volumeButton.x + volumeButton.iconCenterX
    readonly property real volumeLabelCenterX: leftRow.x + volumeButton.x + volumeButton.labelCenterX
    readonly property real bluetoothIconCenterX: leftRow.x + bluetoothButton.x + bluetoothButton.iconCenterX

    implicitWidth: leftRow.implicitWidth
    implicitHeight: 30
    height: 30

    onDesktopModeChanged: {
        if (desktopMode) {
            Popups.close(networkPopup);
            Popups.close(volumePopup);
            Popups.close(bluetoothPopup);
            desktopModeDelay.restart();
        } else {
            desktopModeDelay.stop();
            desktopModeActive = false;
        }
    }

    Timer {
        id: desktopModeDelay

        interval: 5000
        onTriggered: root.desktopModeActive = root.desktopMode
    }

    Row {
        id: leftRow

        anchors.centerIn: parent
        spacing: 4

        BarButton {
            id: networkButton

            icon: Status.networkIcon
            iconGhost: true
            danger: Status.networkOffline
            enabled: !root.desktopModeActive
            opacity: root.desktopModeActive ? 0 : 1

            Behavior on opacity {
                NumberAnimation {
                    duration: root.desktopModeActive ? 600 : 300
                    easing.type: Easing.OutCubic
                }
            }

            onClicked: Popups.toggle(networkPopup)
        }

        BarButton {
            id: volumeButton

            icon: Status.volumeIcon
            iconGhost: true
            label: Status.volumePercent + "%"
            labelGhost: true
            muted: Status.volumeMuted
            enabled: !root.desktopModeActive
            opacity: root.desktopModeActive ? 0 : 1

            Behavior on opacity {
                NumberAnimation {
                    duration: root.desktopModeActive ? 600 : 300
                    easing.type: Easing.OutCubic
                }
            }

            onClicked: button => {
                if (button === Qt.RightButton) Status.toggleMute();
                else Popups.toggle(volumePopup);
            }
            onWheel: delta => Status.setVolume(Status.volumePercent + (delta > 0 ? 5 : -5))
        }

        BarButton {
            id: bluetoothButton

            icon: "󰂯"
            iconGhost: true
            label: Status.bluetoothBatteryText
            labelColor: Status.bluetoothLowBattery ? Theme.danger : Status.bluetoothConnected ? Theme.text : Theme.textMuted
            muted: !Status.bluetoothConnected
            danger: Status.bluetoothLowBattery
            enabled: !root.desktopModeActive
            opacity: root.desktopModeActive ? 0 : 1

            Behavior on opacity {
                NumberAnimation {
                    duration: root.desktopModeActive ? 600 : 300
                    easing.type: Easing.OutCubic
                }
            }

            onClicked: Popups.toggle(bluetoothPopup)
        }
    }

    BluetoothMenu {
        id: bluetoothPopup

        anchorWindow: root.anchorWindow
        anchorItem: bluetoothButton
    }

    NetworkMenu {
        id: networkPopup

        anchorWindow: root.anchorWindow
        anchorItem: networkButton
    }

    MenuPopup {
        id: volumePopup

        anchorWindow: root.anchorWindow
        anchorItem: volumeButton
        menuWidth: 260

        Row {
            width: parent.width
            height: 32
            spacing: 10

            Rectangle {
                id: muteButton

                width: 32
                height: 32
                radius: 8
                color: muteMouse.pressed ? Theme.pressed : muteMouse.containsMouse ? Theme.hover : Theme.transparent

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: Status.volumeIcon
                    color: Status.volumeMuted ? Theme.textMuted : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: muteMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Status.toggleMute()
                }
            }

            Item {
                id: slider

                width: parent.width - muteButton.width - valueLabel.width - parent.spacing * 2
                height: 32

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 6
                    radius: 3
                    color: Theme.track

                    Rectangle {
                        width: parent.width * Status.volumePercent / 100
                        height: parent.height
                        radius: 3
                        color: Theme.accent

                        Behavior on width {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                Rectangle {
                    width: 14
                    height: 14
                    radius: 7
                    color: Theme.white
                    x: Math.max(0, Math.min(slider.width - width, slider.width * Status.volumePercent / 100 - width / 2))
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on x {
                        NumberAnimation {
                            duration: 120
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: event => Status.setVolume(event.x / width * 100)
                    onPositionChanged: event => {
                        if (pressed) Status.setVolume(event.x / width * 100);
                    }
                    onWheel: wheel => {
                        Status.setVolume(Status.volumePercent + (wheel.angleDelta.y > 0 ? 5 : -5));
                        wheel.accepted = true;
                    }
                }
            }

            Text {
                id: valueLabel

                width: 36
                height: 32
                text: Status.volumePercent + "%"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
