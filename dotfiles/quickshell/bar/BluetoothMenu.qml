import QtQuick
import Quickshell.Bluetooth

MenuPopup {
    id: menu

    property var adapter: Bluetooth.defaultAdapter
    property bool adapterEnabled: adapter && adapter.enabled
    property bool discovering: adapter && adapter.discovering
    property var pairedDevices: []
    property var discoveredDevices: []
    property var pairRequests: []

    menuWidth: 260

    function compareDevices(left, right) {
        if (left.connected !== right.connected) return left.connected ? -1 : 1;
        return left.name.localeCompare(right.name);
    }

    function syncDevice(device, include) {
        const next = pairedDevices.filter(item => item !== device);
        if (include) next.push(device);
        next.sort(compareDevices);
        pairedDevices = next;
    }

    function syncDiscoveredDevice(device, include) {
        const next = discoveredDevices.filter(item => item !== device);
        if (include) next.push(device);
        next.sort((left, right) => left.name.localeCompare(right.name));
        discoveredDevices = next;
    }

    function normalizedAddress(value) {
        return String(value || "").replace(/[^0-9a-f]/gi, "").toUpperCase();
    }

    function hasHumanName(device) {
        const name = String(device.name || "").trim();
        if (name.length === 0) return false;

        const normalizedName = normalizedAddress(name);
        if (normalizedName.length === 12 && /^[0-9A-F]{12}$/.test(normalizedName)) return false;
        return normalizedName !== normalizedAddress(device.address);
    }

    function hasPairRequest(device) {
        return pairRequests.indexOf(device) !== -1;
    }

    function requestPair(device) {
        if (!hasPairRequest(device)) pairRequests = pairRequests.concat([device]);
        if (!device.pairing) device.pair();
    }

    function completePair(device) {
        device.trusted = true;
        pairRequests = pairRequests.filter(item => item !== device);
        if (!device.connected) device.connect();
    }

    function stopDiscovery() {
        if (adapter && adapter.discovering) adapter.discovering = false;
    }

    Connections {
        target: menu
        function onVisibleChanged() {
            if (!menu.visible) menu.stopDiscovery();
        }
    }

    Item {
        visible: false
        width: 0
        height: 0

        Repeater {
            model: Bluetooth.devices

            Item {
                required property var modelData

                readonly property bool included: modelData.paired || modelData.trusted || modelData.bonded
                readonly property bool connected: modelData.connected
                readonly property string sortName: modelData.name
                readonly property bool discovered: menu.discovering && !included && menu.hasHumanName(modelData)
                readonly property bool isPaired: modelData.paired

                Component.onCompleted: {
                    menu.syncDevice(modelData, included);
                    menu.syncDiscoveredDevice(modelData, discovered);
                }
                Component.onDestruction: {
                    menu.syncDevice(modelData, false);
                    menu.syncDiscoveredDevice(modelData, false);
                }
                onIncludedChanged: menu.syncDevice(modelData, included)
                onConnectedChanged: if (included) menu.syncDevice(modelData, true)
                onSortNameChanged: if (included) menu.syncDevice(modelData, true)
                onDiscoveredChanged: menu.syncDiscoveredDevice(modelData, discovered)
                onIsPairedChanged: if (isPaired && menu.hasPairRequest(modelData)) menu.completePair(modelData)
            }
        }
    }

    SectionLabel {
        width: parent.width
        height: 14
        text: "BLUETOOTH"
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
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            text: "Adapter"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.weight: Font.DemiBold
            verticalAlignment: Text.AlignVCenter
        }

        ToggleSwitch {
            id: adapterSwitch

            checked: menu.adapterEnabled
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            onToggled: if (menu.adapter) menu.adapter.enabled = !menu.adapter.enabled
        }

        MouseArea {
            id: headerMouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: if (menu.adapter) menu.adapter.enabled = !menu.adapter.enabled
        }
    }

    Repeater {
        model: menu.adapterEnabled ? menu.pairedDevices : []

        MenuRow {
            required property var modelData

            readonly property bool transitioning: modelData.state === BluetoothDeviceState.Connecting
                || modelData.state === BluetoothDeviceState.Disconnecting

            icon: "󰂯"
            label: modelData.name
            active: modelData.connected
            muted: !modelData.connected
            trailing: transitioning ? "connecting..." : modelData.connected && modelData.batteryAvailable ? String(Math.round(modelData.battery * 100)) + "%" : ""
            trailingMuted: transitioning
            onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
        }
    }

    MenuRow {
        visible: menu.adapterEnabled
        icon: "󰐕"
        label: menu.discovering ? "Searching..." : "Search for devices"
        muted: true
        onClicked: if (menu.adapter) menu.adapter.discovering = !menu.adapter.discovering
    }

    Repeater {
        model: menu.adapterEnabled && menu.discovering ? menu.discoveredDevices : []

        MenuRow {
            required property var modelData

            icon: "󰂯"
            label: modelData.name
            muted: true
            trailing: modelData.pairing ? "pairing..." : ""
            trailingMuted: true
            onClicked: menu.requestPair(modelData)
        }
    }
}
