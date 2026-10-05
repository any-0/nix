import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Item {
    id: root
    required property var record
    property bool compact: false
    readonly property var notification: record.notification
    readonly property bool critical: notification.urgency === NotificationUrgency.Critical
    implicitHeight: content.implicitHeight + 36

    SystemClock { id: clock; precision: SystemClock.Seconds }
    function age() {
        const seconds = Math.max(0, Math.floor((clock.date.getTime() - record.receivedAt) / 1000));
        if (seconds < 10) return "just now";
        return (seconds < 60 ? seconds + "s" : seconds < 3600 ? Math.floor(seconds / 60) + "m" : seconds < 86400 ? Math.floor(seconds / 3600) + "h" : Math.floor(seconds / 86400) + "d") + " ago";
    }

    HoverHandler { onHoveredChanged: root.record.hovered = hovered }

    Column {
        id: content
        x: 20
        y: 18
        width: parent.width - 40
        spacing: 10

        Item {
            width: parent.width
            height: 22
            Image {
                id: appIcon
                width: 20
                height: 20
                source: root.notification.appIcon ? Quickshell.iconPath(root.notification.appIcon, true) : ""
                visible: status === Image.Ready
                fillMode: Image.PreserveAspectFit
            }
            Text {
                x: appIcon.visible ? 30 : 0
                width: parent.width - x - ageText.width - 36
                text: root.notification.appName || "Notification"
                textFormat: Text.PlainText
                elide: Text.ElideRight
                font.family: Theme.barFontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                color: root.critical ? Theme.danger : Theme.accent
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                id: ageText
                anchors.right: dismiss.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: root.age()
                font.family: Theme.barFontFamily
                font.pixelSize: 11
                color: Theme.textMuted
            }
            Text {
                id: dismiss
                anchors.right: parent.right
                width: 20
                height: 22
                text: "×"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 20
                color: closeMouse.containsMouse ? Theme.text : Theme.textMuted
                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.notification.dismiss()
                }
            }
        }
        Text {
            width: parent.width
            text: root.notification.summary
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: root.compact ? 2 : 4
            elide: Text.ElideRight
            color: Theme.text
            font.family: Theme.barFontFamily
            font.pixelSize: root.compact ? 16 : 19
            font.weight: Font.Medium
        }
        Text {
            width: parent.width
            visible: text.length > 0
            text: root.notification.body
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: root.compact ? 4 : 12
            elide: Text.ElideRight
            color: Theme.textSecondary
            font.family: Theme.barFontFamily
            font.pixelSize: root.compact ? 13 : 14
            lineHeight: 1.3
        }
        Image {
            width: parent.width
            height: visible ? 120 : 0
            visible: status === Image.Ready
            // Do not fetch arbitrary remote URLs from notification content.
            source: /^(file:|image:|\/)/.test(root.notification.image) ? root.notification.image : ""
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignLeft
            asynchronous: true
        }
        Flow {
            width: parent.width
            spacing: 8
            visible: children.length > 1
            Repeater {
                model: root.notification.actions
                Rectangle {
                    required property var modelData
                    width: Math.min(actionText.implicitWidth + 24, content.width)
                    height: 30
                    radius: 5
                    color: actionMouse.containsMouse ? Theme.hover : Theme.trackMuted
                    Text {
                        id: actionText
                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, parent.width - 24)
                        text: modelData.identifier === "default" ? "Open" : modelData.text
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        color: Theme.text
                        font.family: Theme.barFontFamily
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.invoke()
                    }
                }
            }
        }
    }
}
