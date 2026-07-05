import QtQuick
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire

Item {
    id: root

    required property var anchorWindow

    implicitWidth: leftRow.implicitWidth
    implicitHeight: 30
    height: 30

    Row {
        id: leftRow

        anchors.centerIn: parent
        spacing: 4

        BarButton {
            id: networkButton

            property var connectedDevices: []
            property var connectedNetworks: []
            readonly property var connectedDevice: connectedDevices.length > 0 ? connectedDevices[0] : null
            readonly property var connectedNetwork: connectedNetworks.length > 0 ? connectedNetworks[0] : null
            readonly property bool offline: connectedDevice === null

            icon: offline ? "󰤭" : connectedDevice.type === DeviceType.Wifi ? wifiIcon(connectedNetwork ? connectedNetwork.signalStrength : 1) : "󰒍"
            iconColor: offline ? Theme.danger : Theme.text
            danger: offline

            function wifiIcon(strength) {
                if (strength >= 0.75) return "󰤨";
                if (strength >= 0.5) return "󰤥";
                if (strength >= 0.25) return "󰤢";
                return "󰤟";
            }

            function syncDevice(device, include) {
                const next = connectedDevices.filter(item => item !== device);
                if (include) next.push(device);
                connectedDevices = next;
            }

            function syncNetwork(network, include) {
                const next = connectedNetworks.filter(item => item !== network);
                if (include) next.push(network);
                connectedNetworks = next;
            }

            Repeater {
                model: Networking.devices

                Item {
                    required property var modelData

                    readonly property bool isConnected: modelData.connected
                        && modelData.state === ConnectionState.Connected
                        && (modelData.type === DeviceType.Wifi || (modelData.type === DeviceType.Wired && modelData.hasLink))

                    function updateDevice() {
                        networkButton.syncDevice(modelData, isConnected);
                    }

                    Component.onCompleted: updateDevice()
                    Component.onDestruction: networkButton.syncDevice(modelData, false)
                    onIsConnectedChanged: updateDevice()

                    Repeater {
                        model: modelData.networks

                        Item {
                            required property var modelData

                            readonly property bool activeWifi: modelData.connected && modelData.state === ConnectionState.Connected

                            function updateNetwork() {
                                networkButton.syncNetwork(modelData, activeWifi);
                            }

                            Component.onCompleted: updateNetwork()
                            Component.onDestruction: networkButton.syncNetwork(modelData, false)
                            onActiveWifiChanged: updateNetwork()
                        }
                    }
                }
            }
        }

        BarButton {
            id: volumeButton

            readonly property var sink: Pipewire.defaultAudioSink
            readonly property bool ready: sink && sink.audio
            readonly property int volumePercent: ready ? Math.max(0, Math.min(100, Math.round(sink.audio.volume * 100))) : 0
            readonly property bool volumeMuted: ready ? sink.audio.muted : false

            icon: volumeMuted ? "󰖁" : "󰕾"
            label: volumePercent + "%"
            muted: volumeMuted

            function setVolume(value) {
                if (!ready) return;
                const clamped = Math.max(0, Math.min(100, Math.round(value / 5) * 5));
                sink.audio.muted = false;
                sink.audio.volume = clamped / 100;
            }

            PwObjectTracker {
                objects: [Pipewire.defaultAudioSink]
            }

            onClicked: button => {
                if (button === Qt.RightButton && ready) sink.audio.muted = !sink.audio.muted;
                else Popups.toggle(volumePopup);
            }
            onWheel: delta => setVolume(volumePercent + (delta > 0 ? 5 : -5))
        }

        BarButton {
            id: bluetoothButton

            property var connectedDevices: []

            // Whatever is actually connected right now; prefer a device that
            // reports battery so the label stays informative.
            readonly property var device: connectedDevices.find(d => d.batteryAvailable) || (connectedDevices.length > 0 ? connectedDevices[0] : null)
            readonly property bool connected: device !== null
            readonly property bool lowBattery: connected && device.batteryAvailable && device.battery < 0.2
            readonly property string batteryText: connected && device.batteryAvailable ? String(Math.round(device.battery * 100)) + "%" : ""

            icon: "󰂯"
            label: batteryText
            iconColor: lowBattery ? Theme.danger : connected ? Theme.accent : Theme.textMuted
            labelColor: lowBattery ? Theme.danger : connected ? Theme.text : Theme.textMuted
            muted: !connected
            danger: lowBattery

            function syncDevice(dev, include) {
                const next = connectedDevices.filter(item => item !== dev);
                if (include) next.push(dev);
                connectedDevices = next;
            }

            Repeater {
                model: Bluetooth.devices

                Item {
                    required property var modelData

                    readonly property bool isConnected: modelData.connected

                    Component.onCompleted: bluetoothButton.syncDevice(modelData, isConnected)
                    Component.onDestruction: bluetoothButton.syncDevice(modelData, false)
                    onIsConnectedChanged: bluetoothButton.syncDevice(modelData, isConnected)
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

    MenuPopup {
        id: volumePopup

        readonly property var sink: Pipewire.defaultAudioSink
        readonly property bool ready: sink && sink.audio
        readonly property int volumePercent: ready ? Math.max(0, Math.min(100, Math.round(sink.audio.volume * 100))) : 0
        readonly property bool volumeMuted: ready ? sink.audio.muted : false

        anchorWindow: root.anchorWindow
        anchorItem: volumeButton
        menuWidth: 260

        function setVolume(value) {
            if (!ready) return;
            const clamped = Math.max(0, Math.min(100, Math.round(value / 5) * 5));
            sink.audio.muted = false;
            sink.audio.volume = clamped / 100;
        }

        PwObjectTracker {
            objects: [Pipewire.defaultAudioSink]
        }

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
                    text: volumePopup.volumeMuted ? "󰖁" : "󰕾"
                    color: volumePopup.volumeMuted ? Theme.textMuted : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: muteMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: if (volumePopup.ready) volumePopup.sink.audio.muted = !volumePopup.sink.audio.muted
                }
            }

            Item {
                id: slider

                width: parent.width - muteButton.width - valueLabel.width - parent.spacing * 2
                height: 32

                Rectangle {
                    id: sliderTrack

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 6
                    radius: 3
                    color: Theme.track

                    Rectangle {
                        width: parent.width * volumePopup.volumePercent / 100
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
                    x: Math.max(0, Math.min(slider.width - width, slider.width * volumePopup.volumePercent / 100 - width / 2))
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
                    onPressed: event => updateVolume(event.x)
                    onPositionChanged: event => {
                        if (pressed) updateVolume(event.x);
                    }
                    onWheel: wheel => {
                        volumePopup.setVolume(volumePopup.volumePercent + (wheel.angleDelta.y > 0 ? 5 : -5));
                        wheel.accepted = true;
                    }

                    function updateVolume(pointerX) {
                        volumePopup.setVolume(pointerX / width * 100);
                    }
                }
            }

            Text {
                id: valueLabel

                width: 36
                height: 32
                text: volumePopup.volumePercent + "%"
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
