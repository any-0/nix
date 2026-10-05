import QtQuick

BarButton {
    id: root
    required property var anchorWindow
    icon: Notifications.quiet ? "󰂛" : "󰂚"
    iconFontSize: 16
    iconColor: Notifications.quiet ? Theme.textMuted : Theme.textSecondary
    label: Notifications.history.length ? String(Notifications.history.length) : ""
    labelFontSize: Theme.statusLabelSize
    onClicked: button => {
        if (button === Qt.RightButton) Notifications.quiet = !Notifications.quiet;
        else Popups.toggle(menu);
    }
    MenuPopup {
        id: menu
        anchorWindow: root.anchorWindow
        anchorItem: root
        menuWidth: 440
        onVisibleChanged: if (visible) Notifications.hidePopups()
        NotificationHistory {
            width: parent.width
            height: Math.min(560, root.anchorWindow.screen.height - 100)
            compact: true
        }
    }
}
