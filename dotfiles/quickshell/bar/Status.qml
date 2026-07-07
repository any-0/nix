pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
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

    function syncBluetoothDevice(entry, include) {
        const next = syncListMember(bluetoothPairedDevices, entry, include);
        next.sort((left, right) => {
            if (left.connected !== right.connected) return left.connected ? -1 : 1;
            return left.name.localeCompare(right.name);
        });
        bluetoothPairedDevices = next;
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
            readonly property bool isSaved: device.paired || device.trusted || device.bonded
            readonly property string sortName: device.name

            function sync() {
                root.bluetoothConnectedDevices = root.syncListMember(root.bluetoothConnectedDevices, device, isConnected);
                root.syncBluetoothDevice(device, isSaved);
            }

            Component.onCompleted: sync()
            Component.onDestruction: {
                root.bluetoothConnectedDevices = root.syncListMember(root.bluetoothConnectedDevices, device, false);
                root.syncBluetoothDevice(device, false);
            }
            onIsConnectedChanged: sync()
            onIsSavedChanged: sync()
            onSortNameChanged: sync()
        }
    }

    // ---- Codex ----

    property bool codexLoading: false
    property bool codexReady: false
    property string codexError: ""
    property string codexPlan: ""
    property real codexCredits: -1
    property int codexResetCredits: -1
    property int codexFiveHourPercentLeft: -1
    property int codexWeeklyPercentLeft: -1
    property int codexMonthlyPercentLeft: -1
    property real codexFiveHourUsedPercent: -1
    property real codexWeeklyUsedPercent: -1
    property real codexFiveHourResetAt: -1
    property real codexWeeklyResetAt: -1
    property real codexFiveHourWindowSeconds: -1
    property real codexWeeklyWindowSeconds: -1
    property string codexFiveHourReset: ""
    property string codexWeeklyReset: ""
    property string codexMonthlyReset: ""
    property string codexRaw: ""
    readonly property int codexLowestPercentLeft: Math.min(
        codexFiveHourPercentLeft >= 0 ? codexFiveHourPercentLeft : 100,
        codexWeeklyPercentLeft >= 0 ? codexWeeklyPercentLeft : 100,
        codexMonthlyPercentLeft >= 0 ? codexMonthlyPercentLeft : 100)
    readonly property int codexPercentUsed: codexReady ? 100 - codexLowestPercentLeft : 0
    readonly property string codexLabel: codexReady ? String(codexPercentUsed) + "%" : codexLoading ? "..." : "!"

    property bool claudeLoading: false
    property bool claudeReady: false
    property string claudeError: ""
    property string claudePlan: ""
    property real claudeCredits: -1
    property int claudeFiveHourPercentLeft: -1
    property int claudeWeeklyPercentLeft: -1
    property int claudeMonthlyPercentLeft: -1
    property real claudeFiveHourUsedPercent: -1
    property real claudeWeeklyUsedPercent: -1
    property real claudeFiveHourResetAt: -1
    property real claudeWeeklyResetAt: -1
    property real claudeFiveHourWindowSeconds: -1
    property real claudeWeeklyWindowSeconds: -1
    property string claudeFiveHourReset: ""
    property string claudeWeeklyReset: ""
    property string claudeMonthlyReset: ""
    readonly property int claudeLowestPercentLeft: Math.min(
        claudeFiveHourPercentLeft >= 0 ? claudeFiveHourPercentLeft : 100,
        claudeWeeklyPercentLeft >= 0 ? claudeWeeklyPercentLeft : 100,
        claudeMonthlyPercentLeft >= 0 ? claudeMonthlyPercentLeft : 100)
    readonly property int claudePercentUsed: claudeReady ? 100 - claudeLowestPercentLeft : 0
    readonly property string claudeLabel: claudeReady ? String(claudePercentUsed) + "%" : claudeLoading ? "..." : "!"

    function codexPercentText(value) {
        return value >= 0 ? String(value) + "% left" : "Unknown";
    }

    function codexCreditsText() {
        if (codexCredits < 0) return "Unknown";
        if (Math.round(codexCredits) === codexCredits) return String(codexCredits);
        return codexCredits.toFixed(1);
    }

    function codexDurationText(seconds) {
        const rounded = Math.max(0, Math.round(seconds));
        if (rounded < 60) return String(rounded) + "s";
        if (rounded < 3600) return String(Math.floor(rounded / 60)) + "m";
        if (rounded < 86400) {
            const hours = Math.floor(rounded / 3600);
            const minutes = Math.floor((rounded % 3600) / 60);
            return minutes > 0 ? String(hours) + "h " + String(minutes) + "m" : String(hours) + "h";
        }
        const days = Math.floor(rounded / 86400);
        const hoursLeft = Math.floor((rounded % 86400) / 3600);
        return hoursLeft > 0 ? String(days) + "d " + String(hoursLeft) + "h" : String(days) + "d";
    }

    function codexPaceText(usedPercent, resetAtSeconds, windowSeconds, sessionWindow) {
        if (usedPercent < 0 || resetAtSeconds <= 0 || windowSeconds <= 0) return "";

        const nowSeconds = Date.now() / 1000;
        const timeUntilReset = resetAtSeconds - nowSeconds;
        if (timeUntilReset <= 0 || timeUntilReset > windowSeconds) return "";

        const elapsed = Math.max(0, Math.min(windowSeconds, windowSeconds - timeUntilReset));
        if (elapsed <= 0 || usedPercent <= 0) return "";

        const expected = Math.max(0, Math.min(100, elapsed / windowSeconds * 100));
        if (expected < 3) return "";

        const delta = usedPercent - expected;
        const deltaValue = Math.round(Math.abs(delta));
        const left = deltaValue === 0 ? "On pace" : delta > 0 ? String(deltaValue) + "% in deficit" : String(deltaValue) + "% in reserve";
        const rate = usedPercent / elapsed;
        const eta = (100 - usedPercent) / rate;
        const expectedText = "expected " + String(Math.round(expected)) + "% used";

        if (eta >= timeUntilReset) {
            if (delta < -15) return left + " · " + expectedText + " · lasts until reset · 1.5x headroom";
            return left + " · " + expectedText + " · lasts until reset";
        }

        const prefix = sessionWindow ? "projected empty in " : "runs out in ";
        return left + " · " + expectedText + " · " + prefix + codexDurationText(eta);
    }

    function claudePaceText(usedPercent, resetAtSeconds, windowSeconds, sessionWindow) {
        return codexPaceText(usedPercent, resetAtSeconds, windowSeconds, sessionWindow);
    }

    function refreshCodexUsage() {
        if (codexUsageProcess.running) return;
        codexLoading = true;
        codexUsageProcess.running = true;
    }

    function refreshClaudeUsage() {
        if (claudeUsageProcess.running) return;
        claudeLoading = true;
        claudeUsageProcess.running = true;
    }

    function applyCodexUsage(line) {
        let data = null;

        try {
            data = JSON.parse(line);
        } catch (error) {
            codexReady = false;
            codexError = "invalid codex usage output";
            return;
        }

        codexReady = data.ok === true;
        codexError = data.error || "";
        codexPlan = data.plan || "";
        codexCredits = data.credits === null ? -1 : data.credits;
        codexResetCredits = data.resetCredits === null ? -1 : data.resetCredits;
        codexFiveHourPercentLeft = data.fiveHourPercentLeft === null ? -1 : data.fiveHourPercentLeft;
        codexWeeklyPercentLeft = data.weeklyPercentLeft === null ? -1 : data.weeklyPercentLeft;
        codexMonthlyPercentLeft = data.monthlyPercentLeft === null ? -1 : data.monthlyPercentLeft;
        codexFiveHourUsedPercent = data.fiveHourUsedPercent === null ? -1 : data.fiveHourUsedPercent;
        codexWeeklyUsedPercent = data.weeklyUsedPercent === null ? -1 : data.weeklyUsedPercent;
        codexFiveHourResetAt = data.fiveHourResetAt === null ? -1 : data.fiveHourResetAt;
        codexWeeklyResetAt = data.weeklyResetAt === null ? -1 : data.weeklyResetAt;
        codexFiveHourWindowSeconds = data.fiveHourWindowSeconds === null ? -1 : data.fiveHourWindowSeconds;
        codexWeeklyWindowSeconds = data.weeklyWindowSeconds === null ? -1 : data.weeklyWindowSeconds;
        codexFiveHourReset = data.fiveHourReset || "";
        codexWeeklyReset = data.weeklyReset || "";
        codexMonthlyReset = data.monthlyReset || "";
        codexRaw = data.raw || "";
    }

    function applyClaudeUsage(line) {
        let data = null;

        try {
            data = JSON.parse(line);
        } catch (error) {
            claudeReady = false;
            claudeError = "invalid claude usage output";
            return;
        }

        claudeReady = data.ok === true;
        claudeError = data.error || "";
        claudePlan = data.plan || "";
        claudeCredits = data.credits === null ? -1 : data.credits;
        claudeFiveHourPercentLeft = data.fiveHourPercentLeft === null ? -1 : data.fiveHourPercentLeft;
        claudeWeeklyPercentLeft = data.weeklyPercentLeft === null ? -1 : data.weeklyPercentLeft;
        claudeMonthlyPercentLeft = data.monthlyPercentLeft === null ? -1 : data.monthlyPercentLeft;
        claudeFiveHourUsedPercent = data.fiveHourUsedPercent === null ? -1 : data.fiveHourUsedPercent;
        claudeWeeklyUsedPercent = data.weeklyUsedPercent === null ? -1 : data.weeklyUsedPercent;
        claudeFiveHourResetAt = data.fiveHourResetAt === null ? -1 : data.fiveHourResetAt;
        claudeWeeklyResetAt = data.weeklyResetAt === null ? -1 : data.weeklyResetAt;
        claudeFiveHourWindowSeconds = data.fiveHourWindowSeconds === null ? -1 : data.fiveHourWindowSeconds;
        claudeWeeklyWindowSeconds = data.weeklyWindowSeconds === null ? -1 : data.weeklyWindowSeconds;
        claudeFiveHourReset = data.fiveHourReset || "";
        claudeWeeklyReset = data.weeklyReset || "";
        claudeMonthlyReset = data.monthlyReset || "";
    }

    Process {
        id: codexUsageProcess

        command: ["codex-usage"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => root.applyCodexUsage(line)
        }
        onExited: codexLoading = false
    }

    Process {
        id: claudeUsageProcess

        command: ["claude-usage"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => root.applyClaudeUsage(line)
        }
        onExited: claudeLoading = false
    }

    Timer {
        interval: 120000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            refreshCodexUsage();
            refreshClaudeUsage();
        }
    }
}
