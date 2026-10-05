import QtQuick
import QtQuick.Controls

Item {
    id: root
    property bool compact: false
    onVisibleChanged: if (visible) Notifications.hidePopups()

    Text {
        text: "Notifications"
        font.family: Theme.barFontFamily
        font.pixelSize: root.compact ? 20 : 28
        font.weight: Font.Medium
        color: Theme.text
    }
    Text {
        y: root.compact ? 32 : 44
        text: Notifications.quiet ? "Quiet mode · saved here, no popups" : "Phone & desktop · this session"
        font.family: Theme.barFontFamily
        font.pixelSize: 12
        color: Theme.textMuted
    }
    Row {
        y: root.compact ? 59 : 76
        spacing: 12
        BarButton {
            label: Notifications.quiet ? "Resume popups" : "Quiet mode"
            labelColor: Notifications.quiet ? Theme.accent : Theme.textSecondary
            onClicked: Notifications.quiet = !Notifications.quiet
        }
        BarButton {
            label: "Clear all"
            enabled: Notifications.history.length > 0
            opacity: enabled ? 1 : 0.35
            onClicked: Notifications.clear()
        }
        Text {
            height: 30
            verticalAlignment: Text.AlignVCenter
            text: Notifications.history.length
            font.family: Theme.barFontFamily
            font.pixelSize: 12
            color: Theme.textMuted
        }
    }
    Rectangle {
        y: root.compact ? 99 : 116
        width: parent.width
        height: 1
        color: Theme.track
    }
    ListView {
        id: list
        y: root.compact ? 110 : 132
        width: parent.width
        height: parent.height - y
        clip: true
        model: Notifications.history
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}
        delegate: NotificationCard {
            required property var modelData
            width: list.width
            height: implicitHeight
            record: modelData
            compact: root.compact
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.trackMuted
            }
        }
        Text {
            anchors.centerIn: parent
            visible: list.count === 0
            text: "All caught up."
            font.family: Theme.barFontFamily
            font.pixelSize: root.compact ? 18 : 24
            color: Theme.textMuted
        }
    }
}
