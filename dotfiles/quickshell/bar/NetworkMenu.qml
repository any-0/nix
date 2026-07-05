import QtQuick
import Quickshell.Io
import Quickshell.Networking

MenuPopup {
    id: menu

    property var wifiDevices: []
    property var connectedDevices: []
    property var connectedNetworks: []
    property var connectedWiredDevices: []
    property var rawWifiNetworks: []
    property var wifiNetworks: []
    property var lastTrafficSample: null
    property string throughputText: "󰁝 —  󰁅 —"

    readonly property var wifiDevice: wifiDevices.length > 0 ? wifiDevices[0] : null
    readonly property var currentDevice: connectedDevices.length > 0 ? connectedDevices[0] : null
    readonly property var currentNetwork: connectedNetworks.length > 0 ? connectedNetworks[0] : null
    readonly property string currentInterface: currentDevice ? currentDevice.name : ""
    readonly property bool disconnected: currentDevice === null
    readonly property string connectionLabel: disconnected ? "Disconnected" : currentDevice.type === DeviceType.Wifi && currentNetwork ? currentNetwork.name : "Ethernet"

    menuWidth: 260

    function wifiIcon(strength) {
        if (strength >= 0.75) return "󰤨";
        if (strength >= 0.5) return "󰤥";
        if (strength >= 0.25) return "󰤢";
        return "󰤟";
    }

    function isOpenNetwork(network) {
        return network.security === WifiSecurityType.Open;
    }

    function canConnect(network) {
        return network.connected || network.known || isOpenNetwork(network);
    }

    function compareNetworks(left, right) {
        if (left.connected !== right.connected) return left.connected ? -1 : 1;
        if (left.known !== right.known) return left.known ? -1 : 1;
        if (left.signalStrength !== right.signalStrength) return right.signalStrength - left.signalStrength;
        return left.name.localeCompare(right.name);
    }

    function sortedWifiNetworks(networks) {
        const seen = {};
        const sorted = networks.slice().sort(compareNetworks);
        const deduped = [];

        for (const network of sorted) {
            const ssid = String(network.name || "").trim();
            if (ssid.length === 0 || seen[ssid]) continue;
            seen[ssid] = true;
            deduped.push(network);
            if (deduped.length >= 8) break;
        }

        return deduped;
    }

    function refreshWifiNetworks() {
        wifiNetworks = sortedWifiNetworks(rawWifiNetworks);
    }

    function syncWifiDevice(device, include) {
        const next = wifiDevices.filter(item => item !== device);
        if (include) next.push(device);
        wifiDevices = next;
    }

    function syncConnectedDevice(device, include) {
        const next = connectedDevices.filter(item => item !== device);
        if (include) next.push(device);
        connectedDevices = next;
    }

    function syncConnectedWiredDevice(device, include) {
        const next = connectedWiredDevices.filter(item => item !== device);
        if (include) next.push(device);
        connectedWiredDevices = next;
    }

    function syncConnectedNetwork(network, include) {
        const next = connectedNetworks.filter(item => item !== network);
        if (include) next.push(network);
        connectedNetworks = next;
    }

    function syncWifiNetwork(network, include) {
        const next = rawWifiNetworks.filter(item => item !== network);
        if (include) next.push(network);
        rawWifiNetworks = next;
        refreshWifiNetworks();
    }

    function resetThroughput() {
        lastTrafficSample = null;
        throughputText = "󰁝 —  󰁅 —";
    }

    function humanRate(bytes) {
        if (bytes >= 1024 * 1024) return (bytes / 1024 / 1024).toFixed(1) + " MB/s";
        if (bytes >= 1024) return Math.round(bytes / 1024) + " KB/s";
        return Math.round(bytes) + " B/s";
    }

    function readTrafficSample(interfaceName) {
        const lines = netDevFile.text().split("\n");

        for (const line of lines) {
            const parts = line.split(":");
            if (parts.length !== 2 || parts[0].trim() !== interfaceName) continue;

            const fields = parts[1].trim().split(/\s+/);
            return {
                "time": Date.now(),
                "rx": Number(fields[0]),
                "tx": Number(fields[8])
            };
        }

        return null;
    }

    function updateThroughput() {
        if (currentInterface.length === 0) {
            resetThroughput();
            return;
        }

        netDevFile.reload();
        netDevFile.waitForJob();

        const sample = readTrafficSample(currentInterface);
        if (!sample) {
            resetThroughput();
            return;
        }

        if (!lastTrafficSample) {
            lastTrafficSample = sample;
            throughputText = "󰁝 —  󰁅 —";
            return;
        }

        const seconds = Math.max(0.001, (sample.time - lastTrafficSample.time) / 1000);
        const up = Math.max(0, (sample.tx - lastTrafficSample.tx) / seconds);
        const down = Math.max(0, (sample.rx - lastTrafficSample.rx) / seconds);
        lastTrafficSample = sample;
        throughputText = "󰁝 " + humanRate(up) + "  󰁅 " + humanRate(down);
    }

    onVisibleChanged: resetThroughput()
    onCurrentInterfaceChanged: resetThroughput()

    FileView {
        id: netDevFile

        path: "/proc/net/dev"
        preload: false
        blockLoading: true
        blockAllReads: true
        watchChanges: false
        printErrors: false
    }

    Timer {
        interval: 1000
        repeat: true
        running: menu.visible
        triggeredOnStart: true
        onTriggered: menu.updateThroughput()
    }

    Item {
        visible: false
        width: 0
        height: 0

        Repeater {
            model: Networking.devices

            Item {
                required property var modelData

                readonly property bool isWifi: modelData.type === DeviceType.Wifi
                readonly property bool isConnected: modelData.connected
                    && modelData.state === ConnectionState.Connected
                    && (modelData.type === DeviceType.Wifi || (modelData.type === DeviceType.Wired && modelData.hasLink))
                readonly property bool isConnectedWired: modelData.type === DeviceType.Wired
                    && modelData.connected
                    && modelData.state === ConnectionState.Connected
                    && modelData.hasLink

                function updateDevice() {
                    menu.syncWifiDevice(modelData, isWifi);
                    menu.syncConnectedDevice(modelData, isConnected);
                    menu.syncConnectedWiredDevice(modelData, isConnectedWired);
                }

                Component.onCompleted: updateDevice()
                Component.onDestruction: {
                    menu.syncWifiDevice(modelData, false);
                    menu.syncConnectedDevice(modelData, false);
                    menu.syncConnectedWiredDevice(modelData, false);
                }
                onIsWifiChanged: updateDevice()
                onIsConnectedChanged: updateDevice()
                onIsConnectedWiredChanged: updateDevice()
            }
        }

        Repeater {
            model: menu.wifiDevice ? menu.wifiDevice.networks : []

            Item {
                required property var modelData

                readonly property bool activeWifi: modelData.connected && modelData.state === ConnectionState.Connected
                readonly property string sortName: modelData.name
                readonly property bool known: modelData.known
                readonly property real signal: modelData.signalStrength
                readonly property int security: modelData.security
                readonly property int state: modelData.state

                function updateNetwork() {
                    menu.syncWifiNetwork(modelData, true);
                    menu.syncConnectedNetwork(modelData, activeWifi);
                }

                Component.onCompleted: updateNetwork()
                Component.onDestruction: {
                    menu.syncWifiNetwork(modelData, false);
                    menu.syncConnectedNetwork(modelData, false);
                }
                onActiveWifiChanged: updateNetwork()
                onSortNameChanged: menu.refreshWifiNetworks()
                onKnownChanged: menu.refreshWifiNetworks()
                onSignalChanged: menu.refreshWifiNetworks()
                onSecurityChanged: menu.refreshWifiNetworks()
                onStateChanged: menu.refreshWifiNetworks()
            }
        }
    }

    SectionLabel {
        width: parent.width
        height: 14
        text: "NETWORK"
    }

    Rectangle {
        width: parent.width
        height: 32
        radius: 8
        color: headerMouse.pressed ? Theme.pressed : headerMouse.containsMouse ? Theme.hover : Theme.transparent

        Behavior on color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.right: wifiSwitch.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            text: menu.connectionLabel
            color: menu.disconnected ? Theme.textMuted : Theme.text
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.weight: Font.DemiBold
            verticalAlignment: Text.AlignVCenter
        }

        ToggleSwitch {
            id: wifiSwitch

            checked: Networking.wifiEnabled
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
        }

        MouseArea {
            id: headerMouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
        }
    }

    MenuRow {
        label: menu.throughputText
        muted: true
        clickable: false
    }

    Repeater {
        model: Networking.wifiEnabled ? menu.wifiNetworks : []

        MenuRow {
            required property var modelData

            readonly property bool transitioning: modelData.state === ConnectionState.Connecting
                || modelData.state === ConnectionState.Disconnecting
            readonly property bool locked: !modelData.known && !menu.isOpenNetwork(modelData)

            icon: menu.wifiIcon(modelData.signalStrength)
            label: modelData.name
            active: modelData.connected
            muted: locked
            trailing: transitioning ? "connecting..." : locked ? "󰌾" : ""
            trailingMuted: transitioning || locked
            clickable: menu.canConnect(modelData)
            onClicked: modelData.connected ? modelData.requestDisconnect() : modelData.requestConnect()
        }
    }

    MenuRow {
        visible: menu.connectedWiredDevices.length > 0
        icon: "󰒍"
        label: "Ethernet"
        active: true
        clickable: false
    }
}
