import QtQuick
import Quickshell
import Quickshell.Wayland._WlrLayerShell

PanelWindow {
    id: panel
    required property var screenInfo
    screen: screenInfo
    implicitHeight: Math.round(screenInfo.height / 3)
    anchors {
        top: true
        left: true
        right: true
    }
    exclusiveZone: implicitHeight
    color: "#25272c"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-info"

    readonly property int railWidth: 360
    property bool notificationsOpen: false
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    function metric(value, unit) {
        if (value === null || value === undefined || value < 0)
            return "—";
        return (unit === "W" && value > 0 && value < 10 ? value.toFixed(1) : Math.round(value)) + unit;
    }

    function updatedAgo() {
        if (!Status.codexUpdatedAt)
            return "Not updated yet";
        const seconds = Math.max(0, Math.floor((clock.date.getTime() - Date.parse(Status.codexUpdatedAt)) / 1000));
        const age = seconds < 60 ? seconds + "s" : seconds < 3600 ? Math.floor(seconds / 60) + "m" : seconds < 86400 ? Math.floor(seconds / 3600) + "h" : Math.floor(seconds / 86400) + "d";
        return "Updated " + age + " ago";
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: Popups.closeOpenPopup()
    }

    Rectangle {
        width: panel.railWidth
        height: parent.height
        color: "#303339"

        Item {
            id: heading
            x: 36
            y: 39
            width: parent.width - 72
            height: 171
            Label {
                text: Qt.formatDateTime(clock.date, "HH:mm")
                font.pixelSize: 92
                font.weight: Font.Light
                font.letterSpacing: -5
            }
            Label {
                y: 111
                text: Qt.formatDateTime(clock.date, "dddd")
                font.pixelSize: 24
            }
            Caption {
                y: 149
                text: Qt.formatDateTime(clock.date, "d MMMM yyyy")
                font.pixelSize: 14
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: controls.toggleCalendar()
            }
        }

        Rectangle {
            x: 28
            y: 254
            width: panel.railWidth - 56
            height: 42
            radius: 6
            color: notificationMouse.containsMouse ? Theme.hover : "transparent"
            Label {
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                text: panel.notificationsOpen ? "← Machines & storage" : "Notifications"
                font.pixelSize: 16
                color: panel.notificationsOpen ? Theme.accent : Theme.textSecondary
            }
            Caption {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: Notifications.history.length
                visible: !panel.notificationsOpen
                font.pixelSize: 14
                color: Notifications.history.length ? Theme.accent : Theme.textMuted
            }
            MouseArea {
                id: notificationMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    panel.notificationsOpen = !panel.notificationsOpen;
                    if (panel.notificationsOpen) Notifications.hidePopups();
                }
            }
        }

        Caption {
            x: 40
            y: Math.round(panel.height * 0.4)
            text: "CODEX  /  REMAINING"
            font.letterSpacing: 1.8
            font.pixelSize: 12
        }
        ClockPower {
            id: controls
            x: 40
            y: Math.round(panel.height * 0.4) + 40
            anchorWindow: panel
            showClock: false
            showPower: false
            expandedUsage: true
            calendarAnchor: heading
            powerAnchor: power
        }
        Caption {
            x: 40
            y: Math.round(panel.height * 0.4) + 150
            text: Status.codexLoading ? "Updating…" : panel.updatedAgo()
            font.pixelSize: 14
        }

        Column {
            x: 40
            anchors.bottom: systemControls.top
            anchors.bottomMargin: 35
            width: parent.width - 80
            spacing: 16
            Repeater {
                model: PhoneBattery.phones
                Item {
                    required property var modelData
                    width: parent.width
                    height: 59
                    Caption {
                        text: modelData.name
                        font.pixelSize: 14
                    }
                    Label {
                        y: 24
                        text: modelData.charge + "%"
                        font.pixelSize: 26
                    }
                    Caption {
                        anchors.right: parent.right
                        y: 34
                        text: modelData.charging ? "Charging" : "On battery"
                        color: modelData.charging ? Theme.accent : Theme.textMuted
                        font.pixelSize: 13
                    }
                }
            }
        }

        Item {
            id: systemControls
            x: 28
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 44
            width: parent.width - 56
            height: 80
            StatusPill {
                anchorWindow: panel
                ghostIcons: false
                showPhones: false
                showNotifications: false
                scale: 1.4
                transformOrigin: Item.TopLeft
            }
            BarButton {
                id: power
                anchors.right: parent.right
                y: 5
                icon: "⏻"
                iconFontSize: 18
                iconColor: Theme.textMuted
                hoverDanger: true
                onClicked: controls.togglePower()
            }
            Caption {
                x: 12
                y: 49
                text: Status.networkLabel + "   ↓ " + Status.networkDownRate + "   ↑ " + Status.networkUpRate
                font.pixelSize: 12
            }
        }
    }

    Item {
        id: main
        visible: !panel.notificationsOpen
        x: panel.railWidth + 44
        y: 48
        width: panel.width - x - 44
        height: panel.height - 96
        readonly property real nameWidth: 132
        readonly property real metricWidth: (width - nameWidth) / 3

        Caption {
            text: "MACHINES"
            font.pixelSize: 12
            font.letterSpacing: 1.8
        }
        Row {
            x: main.nameWidth
            Repeater {
                model: ["CPU", "GPU", "MEMORY"]
                Caption {
                    required property string modelData
                    text: modelData
                    width: main.metricWidth
                    font.pixelSize: 12
                    font.letterSpacing: 1.8
                }
            }
        }

        Column {
            y: 52
            spacing: 24
            Host {
                name: "PC"
                description: "NixOS"
                sample: LocalMetrics.sample
                cpu: LocalMetrics.cpuUsage
                power: LocalMetrics.cpuPower
            }
            Host {
                name: "SRV"
                description: "Proxmox"
                sample: RemoteMetrics.proxmox.sample
                cpu: sample ? sample.cpu : -1
                power: sample ? sample.cpuPower : -1
            }
            Host {
                name: "NEO"
                description: "macOS"
                sample: RemoteMetrics.mac.sample
                cpu: sample ? sample.cpu : -1
                power: sample ? sample.cpuPower : -1
            }
        }

        Rectangle {
            y: 441
            width: parent.width
            height: 1
            color: Theme.trackMuted
        }
        Caption {
            y: 473
            text: "STORAGE"
            font.pixelSize: 12
            font.letterSpacing: 1.8
        }
        StorageStatus {
            y: 521
            anchorWindow: panel
            expanded: true
            spacing: 44
            diskWidth: (main.width - spacing) / 2
        }
    }

    NotificationHistory {
        x: main.x
        y: main.y
        width: main.width
        height: main.height
        visible: panel.notificationsOpen
    }

    component Label: Text {
        color: "#f1eee7"
        font.family: Theme.barFontFamily
        font.features: {
            "tnum": 1
        }
        font.pixelSize: 20
        font.weight: Font.Medium
    }

    component Caption: Label {
        color: "#a2a6ae"
        font.pixelSize: 15
        font.weight: Font.Normal
    }

    component Host: Item {
        id: host
        required property string name
        required property string description
        required property var sample
        required property real cpu
        required property var power
        width: main.width
        height: 104

        Rectangle {
            y: 15
            width: 4
            height: 4
            radius: 2
            color: host.sample ? Theme.accent : Theme.textMuted
        }
        Label {
            x: 14
            text: host.name
            font.pixelSize: 26
            font.weight: Font.DemiBold
            font.letterSpacing: -0.6
        }
        Caption {
            x: 14
            y: 46
            text: host.sample ? host.description : "Offline"
        }
        Row {
            x: main.nameWidth
            Sensor {
                load: host.cpu
                temperature: host.sample ? host.sample.cpuTemp : null
                power: host.power
            }
            Sensor {
                load: host.sample ? host.sample.gpuUsage : null
                temperature: host.sample ? host.sample.gpuTemp : null
                power: host.sample ? host.sample.gpuPower : null
            }
            Item {
                width: main.metricWidth
                height: 104
                Label {
                    text: host.sample ? host.sample.ramUsed.toFixed(1) : "—"
                    font.pixelSize: 42
                    font.weight: Font.Normal
                }
                Caption {
                    y: 57
                    text: host.sample ? "/ " + host.sample.ramTotal.toFixed(1) + " GiB" : ""
                }
                Rectangle {
                    y: 86
                    width: parent.width - 36
                    height: 3
                    color: Theme.track
                    Rectangle {
                        height: parent.height
                        width: host.sample ? parent.width * Math.min(1, host.sample.ramUsed / host.sample.ramTotal) : 0
                        color: Theme.accent
                    }
                }
            }
        }
    }

    component Sensor: Item {
        required property var load
        required property var temperature
        required property var power
        width: main.metricWidth
        height: 104
        Label {
            text: panel.metric(parent.load, "%")
            font.pixelSize: 42
            font.weight: Font.Normal
        }
        Caption {
            y: 57
            text: panel.metric(parent.temperature, "°") + "   /   " + panel.metric(parent.power, "W")
        }
    }
}
