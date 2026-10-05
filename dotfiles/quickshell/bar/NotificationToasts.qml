import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    required property var screenInfo
    screen: screenInfo
    visible: Notifications.popups.length > 0
    implicitWidth: 420
    implicitHeight: stack.implicitHeight
    color: "transparent"
    anchors { top: true; right: true }
    margins { top: 44; right: 16 }
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-notifications"

    Column {
        id: stack
        width: parent.width
        spacing: 10
        Repeater {
            model: Notifications.popups
            Rectangle {
                required property var modelData
                width: stack.width
                height: card.implicitHeight
                color: "#303339"
                radius: 12
                border.width: 1
                border.color: Theme.track
                NotificationCard {
                    id: card
                    width: parent.width
                    height: implicitHeight
                    record: modelData
                    compact: true
                }
            }
        }
    }
}
