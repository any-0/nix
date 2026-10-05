import QtQuick

Grid {
    id: root
    required property var anchorWindow
    property bool expanded: false
    property real diskWidth: 104
    columns: expanded ? 2 : 5
    rowSpacing: expanded ? 30 : 0
    spacing: 14
    height: implicitHeight

    Disk { label: "PC"; description: "NixOS SSD"; location: "/ · /dev/nvme0n1p2"; sample: StorageMetrics.pc.sample }
    Disk { label: "MEDIA1"; description: "NAS · media1"; location: "//192.168.0.112/media1"; sample: StorageMetrics.media1.sample }
    Disk { label: "MEDIA2"; description: "NAS · media2"; location: "//192.168.0.112/media2"; sample: StorageMetrics.media2.sample }
    Disk { label: "BACKUPS"; description: "NAS · backups"; location: "//192.168.0.112/backups"; sample: StorageMetrics.backups.sample }
    Disk { label: "NEO"; description: "NEO SSD · APFS container"; location: "/System/Volumes/Data"; sample: RemoteMetrics.mac.sample ? RemoteMetrics.mac.sample.storage : null }

    function capacity(bytes) {
        return bytes >= 1099511627776
            ? (bytes / 1099511627776).toFixed(2) + " TiB"
            : (bytes / 1073741824).toFixed(1) + " GiB";
    }

    // Used out of total, sharing the unit of the total: "3.5/3.6T", "501/916G".
    function usage(sample) {
        const tib = 1099511627776, gib = 1073741824;
        return sample.total >= tib
            ? (sample.used / tib).toFixed(1) + "/" + (sample.total / tib).toFixed(1) + "T"
            : Math.round(sample.used / gib) + "/" + Math.round(sample.total / gib) + "G";
    }

    component Disk: Item {
        id: disk
        required property string label
        required property string description
        required property string location
        required property var sample
        readonly property real fraction: sample ? sample.used / sample.total : 0
        width: root.diskWidth
        height: root.expanded ? 94 : 30

        Rectangle {
            anchors.fill: parent
            anchors.margins: -5
            anchors.topMargin: 2
            anchors.bottomMargin: 2
            radius: 4
            color: mouse.pressed ? Theme.pressed : mouse.containsMouse || details.visible ? Theme.hover : Theme.transparent
        }

        Text {
            anchors.left: parent.left
            y: 5
            text: root.expanded ? disk.label + "  /  " + (disk.description.startsWith("NAS") ? "NAS" : "SSD") : disk.label
            color: root.expanded ? Theme.textSecondary : Theme.textMuted
            font.family: Theme.barFontFamily
            font.pixelSize: root.expanded ? 15 : 9
            font.weight: Font.Medium
        }

        Text {
            anchors.right: parent.right
            y: root.expanded ? 0 : 5
            text: disk.sample ? root.usage(disk.sample) : "—"
            color: Theme.textSecondary
            font.family: Theme.barFontFamily
            font.features: { "tnum": 1 }
            font.pixelSize: root.expanded ? 28 : 10
            font.weight: Font.Medium
        }

        Rectangle {
            y: root.expanded ? 41 : 21
            width: parent.width
            height: 3
            radius: 1.5
            color: Theme.track

            Rectangle {
                width: parent.width * Math.min(1, disk.fraction)
                height: parent.height
                radius: parent.radius
                color: Theme.accent
            }
        }

        Text {
            visible: root.expanded
            y: 58
            text: disk.sample ? root.capacity(disk.sample.free) + " free  /  " + root.capacity(disk.sample.total) : "Unavailable"
            color: Theme.textSecondary
            font.family: Theme.barFontFamily
            font.pixelSize: 14
            font.features: { "tnum": 1 }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Popups.toggle(details)
        }

        MenuPopup {
            id: details
            anchorWindow: root.anchorWindow
            anchorItem: disk
            menuWidth: 290

            Text {
                width: parent.width
                text: disk.description
                color: Theme.text
                font.family: Theme.barFontFamily
                font.pixelSize: 14
                font.weight: Font.Medium
            }

            Text {
                width: parent.width
                text: disk.location
                color: Theme.textMuted
                font.family: Theme.barFontFamily
                font.pixelSize: 11
                wrapMode: Text.WrapAnywhere
            }

            Item { width: 1; height: 4 }

            Repeater {
                model: [
                    { label: "Used", field: "used" },
                    { label: "Available", field: "free" },
                    { label: "Capacity", field: "total" }
                ]
                delegate: Item {
                    required property var modelData
                    width: parent.width
                    height: 25

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        color: Theme.textSecondary
                        font.family: Theme.barFontFamily
                        font.pixelSize: 12
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: disk.sample ? root.capacity(disk.sample[modelData.field]) : "Unavailable"
                        color: Theme.text
                        font.family: Theme.barFontFamily
                        font.features: { "tnum": 1 }
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
