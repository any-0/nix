import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire

Rectangle {
    id: pill

    required property var anchorWindow
    property int anchorOffsetX: 0

    height: 30
    radius: 15
    color: Theme.surface
    border.color: Theme.surfaceBorder
    border.width: 1
    width: leftRow.implicitWidth + 20

    Row {
        id: leftRow
        anchors.centerIn: parent
        spacing: 8

        ModuleText {
            id: networkText

            property var connectedDevices: []
            readonly property var connectedDevice: connectedDevices.length > 0 ? connectedDevices[0] : null

            text: connectedDevice === null ? "󰤭" : connectedDevice.type === DeviceType.Wifi ? "󰤨 Wifi" : "󰒍 Eth"
            danger: connectedDevice === null

            Repeater {
                model: Networking.devices

                Item {
                    required property var modelData

                    readonly property bool isConnected: modelData.connected
                        && modelData.state === ConnectionState.Connected
                        && (modelData.type === DeviceType.Wifi || (modelData.type === DeviceType.Wired && modelData.hasLink))

                    function updateDevice() {
                        const next = networkText.connectedDevices.filter(device => device !== modelData);
                        if (isConnected) next.push(modelData);
                        networkText.connectedDevices = next;
                    }

                    Component.onCompleted: updateDevice()
                    Component.onDestruction: networkText.connectedDevices = networkText.connectedDevices.filter(device => device !== modelData)
                    onIsConnectedChanged: updateDevice()
                }
            }
        }

        ModuleText {
            id: volumeText

            readonly property var sink: Pipewire.defaultAudioSink
            readonly property bool ready: sink && sink.audio
            readonly property int volumePercent: ready ? Math.max(0, Math.min(100, Math.round(sink.audio.volume * 100))) : 0
            readonly property bool volumeMuted: ready ? sink.audio.muted : false

            text: (volumeMuted ? "󰖁 " : "󰕾 ") + volumePercent + "%"
            danger: volumeMuted

            function setVolume(value) {
                if (!ready) return;
                const clamped = Math.max(0, Math.min(100, Math.round(value / 5) * 5));
                sink.audio.muted = false;
                sink.audio.volume = clamped / 100;
            }

            PwObjectTracker {
                objects: [Pipewire.defaultAudioSink]
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton && volumeText.ready) volumeText.sink.audio.muted = !volumeText.sink.audio.muted;
                    else volumePopup.visible = !volumePopup.visible;
                }
                onWheel: wheel => {
                    volumeText.setVolume(volumeText.volumePercent + (wheel.angleDelta.y > 0 ? 5 : -5));
                    wheel.accepted = true;
                }
            }
        }

        ModuleText {
            id: bluetoothText

            readonly property string targetAddress: "9C:0D:AC:14:8D:42"
            property var device: null

            readonly property bool connected: device && device.connected
            readonly property bool connecting: device && device.state === BluetoothDeviceState.Connecting
            readonly property bool lowBattery: connected && device.batteryAvailable && device.battery < 0.2
            readonly property string batteryText: connected && device.batteryAvailable ? String(Math.round(device.battery * 100)) + "%" : "-"

            text: "󰂯 " + batteryText
            danger: lowBattery
            muted: connecting || !connected

            Repeater {
                model: Bluetooth.devices

                Item {
                    required property var modelData

                    readonly property bool isTarget: modelData.address.toLowerCase() === bluetoothText.targetAddress.toLowerCase()

                    Component.onCompleted: if (isTarget) bluetoothText.device = modelData
                    Component.onDestruction: if (bluetoothText.device === modelData) bluetoothText.device = null
                    onIsTargetChanged: if (isTarget) bluetoothText.device = modelData
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: {
                    if (!bluetoothText.device) return;
                    if (bluetoothText.device.connected) bluetoothText.device.disconnect();
                    else bluetoothText.device.connect();
                }
            }
        }
    }

    PopupWindow {
        id: volumePopup

        readonly property var sink: Pipewire.defaultAudioSink
        readonly property bool ready: sink && sink.audio
        readonly property int volumePercent: ready ? Math.max(0, Math.min(100, Math.round(sink.audio.volume * 100))) : 0

        visible: false
        color: "transparent"
        implicitWidth: 43
        implicitHeight: 140
        anchor.window: pill.anchorWindow
        anchor.rect.x: pill.anchorOffsetX + pill.x + volumeText.x + volumeText.width / 2 - implicitWidth / 2
        anchor.rect.y: pill.y + pill.height + 6

        function setVolume(value) {
            if (!ready) return;
            const clamped = Math.max(0, Math.min(100, Math.round(value / 5) * 5));
            sink.audio.muted = false;
            sink.audio.volume = clamped / 100;
        }

        PwObjectTracker {
            objects: [Pipewire.defaultAudioSink]
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.surface
            border.color: Theme.surfaceBorder
            border.width: 1
            radius: 14

            Rectangle {
                id: volumeTrack
                width: 14
                height: 124
                radius: 7
                color: Theme.volumeTrack
                anchors.centerIn: parent

                Rectangle {
                    width: parent.width
                    radius: 7
                    color: Theme.white
                    anchors.bottom: parent.bottom
                    height: parent.height * volumePopup.volumePercent / 100
                }

                Rectangle {
                    width: 19
                    height: 19
                    radius: 9.5
                    color: Theme.white
                    border.color: Theme.handleBorder
                    border.width: 1
                    x: (parent.width - width) / 2
                    y: Math.max(-height / 2, Math.min(parent.height - height / 2, (1 - volumePopup.volumePercent / 100) * parent.height - height / 2))
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: updateVolume(mouse.y)
                    onPositionChanged: if (pressed) updateVolume(mouse.y)

                    function updateVolume(pointerY) {
                        volumePopup.setVolume((1 - pointerY / height) * 100);
                    }
                }
            }
        }
    }

    component ModuleText: Text {
        property bool danger: false
        property bool muted: false

        color: danger ? Theme.danger : muted ? Theme.textMuted : Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 14
        font.weight: Font.DemiBold
        verticalAlignment: Text.AlignVCenter
        height: 20
    }
}
