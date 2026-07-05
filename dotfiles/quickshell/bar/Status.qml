pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire

// Shared live state for the three status widgets. Both the bar (StatusPill)
// and the desktop overlay (DesktopStatus) render from this, so the flying
// icons always agree with the bar about glyph, color and state.
Singleton {
    id: root

    function syncListMember(list, entry, include) {
        const next = list.filter(item => item !== entry);
        if (include) next.push(entry);
        return next;
    }

    // ---- Network ----

    property var networkDevices: []
    property var wifiNetworks: []

    readonly property var networkDevice: networkDevices.length > 0 ? networkDevices[0] : null
    readonly property var wifiNetwork: wifiNetworks.length > 0 ? wifiNetworks[0] : null
    readonly property bool networkOffline: networkDevice === null
    readonly property bool networkWifi: !networkOffline && networkDevice.type === DeviceType.Wifi
    readonly property string networkIcon: networkOffline ? "󰤭" : networkWifi ? wifiIcon(wifiNetwork ? wifiNetwork.signalStrength : 1) : "󰒍"
    readonly property string networkLabel: networkOffline ? "Disconnected" : networkWifi && wifiNetwork ? wifiNetwork.name : "Ethernet"
    readonly property string networkInterface: networkDevice ? networkDevice.name : ""

    function wifiIcon(strength) {
        if (strength >= 0.75) return "󰤨";
        if (strength >= 0.5) return "󰤥";
        if (strength >= 0.25) return "󰤢";
        return "󰤟";
    }

    Instantiator {
        model: Networking.devices

        delegate: QtObject {
            id: deviceWatcher

            readonly property var device: modelData
            readonly property bool isConnected: device.connected
                && device.state === ConnectionState.Connected
                && (device.type === DeviceType.Wifi || (device.type === DeviceType.Wired && device.hasLink))

            Component.onCompleted: root.networkDevices = root.syncListMember(root.networkDevices, device, isConnected)
            Component.onDestruction: root.networkDevices = root.syncListMember(root.networkDevices, device, false)
            onIsConnectedChanged: root.networkDevices = root.syncListMember(root.networkDevices, device, isConnected)

            property Instantiator networkWatchers: Instantiator {
                model: deviceWatcher.device.networks

                delegate: QtObject {
                    readonly property var network: modelData
                    readonly property bool activeWifi: network.connected && network.state === ConnectionState.Connected

                    Component.onCompleted: root.wifiNetworks = root.syncListMember(root.wifiNetworks, network, activeWifi)
                    Component.onDestruction: root.wifiNetworks = root.syncListMember(root.wifiNetworks, network, false)
                    onActiveWifiChanged: root.wifiNetworks = root.syncListMember(root.wifiNetworks, network, activeWifi)
                }
            }
        }
    }

    // ---- Volume ----

    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property bool audioReady: audioSink && audioSink.audio ? true : false
    readonly property int volumePercent: audioReady ? Math.max(0, Math.min(100, Math.round(audioSink.audio.volume * 100))) : 0
    readonly property bool volumeMuted: audioReady ? audioSink.audio.muted : false
    readonly property string volumeIcon: volumeMuted ? "󰖁" : "󰕾"

    function setVolume(value) {
        if (!audioReady) return;
        const clamped = Math.max(0, Math.min(100, Math.round(value / 5) * 5));
        audioSink.audio.muted = false;
        audioSink.audio.volume = clamped / 100;
    }

    function toggleMute() {
        if (audioReady) audioSink.audio.muted = !audioSink.audio.muted;
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    // ---- Bluetooth ----

    property var bluetoothConnectedDevices: []
    property var bluetoothPairedDevices: []

    // Prefer a device that reports battery so the label stays informative.
    readonly property var bluetoothDevice: bluetoothConnectedDevices.find(d => d.batteryAvailable) || (bluetoothConnectedDevices.length > 0 ? bluetoothConnectedDevices[0] : null)
    readonly property bool bluetoothConnected: bluetoothDevice !== null
    readonly property bool bluetoothLowBattery: bluetoothConnected && bluetoothDevice.batteryAvailable && bluetoothDevice.battery < 0.2
    readonly property string bluetoothBatteryText: bluetoothConnected && bluetoothDevice.batteryAvailable ? String(Math.round(bluetoothDevice.battery * 100)) + "%" : ""

    Instantiator {
        model: Bluetooth.devices

        delegate: QtObject {
            id: bluetoothWatcher

            readonly property var device: modelData
            readonly property bool isConnected: device.connected
            readonly property bool isPaired: device.paired

            function sync() {
                root.bluetoothConnectedDevices = root.syncListMember(root.bluetoothConnectedDevices, device, isConnected);
                root.bluetoothPairedDevices = root.syncListMember(root.bluetoothPairedDevices, device, isPaired);
            }

            Component.onCompleted: sync()
            Component.onDestruction: {
                root.bluetoothConnectedDevices = root.syncListMember(root.bluetoothConnectedDevices, device, false);
                root.bluetoothPairedDevices = root.syncListMember(root.bluetoothPairedDevices, device, false);
            }
            onIsConnectedChanged: sync()
            onIsPairedChanged: sync()
        }
    }
}
