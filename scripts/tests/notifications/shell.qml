import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    Connections {
        target: Quickshell
        function onReloadCompleted() { Quickshell.inhibitReloadPopup(); }
    }
    NotificationToasts {
        screenInfo: Quickshell.screens.find(screen => screen.name === "TEST")
    }
    PanelWindow {
        id: bar
        screen: Quickshell.screens.find(screen => screen.name === "TEST")
        anchors { top: true; left: true; right: true }
        implicitHeight: 30
        color: "#25272c"
        NotificationButton { id: bell; anchorWindow: bar }
    }
    PanelWindow {
        screen: Quickshell.screens.find(screen => screen.name === "PORTRAIT")
        anchors { top: true; left: true; right: true }
        implicitHeight: 853
        color: "#25272c"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        NotificationHistory {
            anchors.fill: parent
            anchors.margins: 48
        }
    }
    IpcHandler {
        target: "test"
        function state(): string {
            return JSON.stringify({
                quiet: Notifications.quiet,
                menuOpen: Popups.openPopup !== null,
                history: Notifications.history.map(record => ({id: record.notification.id, summary: record.notification.summary, received: record.receivedAt})),
                popups: Notifications.popups.map(record => record.notification.summary)
            });
        }
        function quiet(value: bool): void { Notifications.quiet = value; }
        function menu(): void { bell.clicked(Qt.LeftButton); }
        function clear(): void { Notifications.clear(); }
        function dismiss(id: int): void { Notifications.records.find(record => record.notification.id === id).notification.dismiss(); }
        function hide(): void { Notifications.hidePopups(); }
        function reload(): void { Quickshell.reload(false); }
        function action(id: int): void { Notifications.records.find(record => record.notification.id === id).notification.actions[0].invoke(); }
    }
}
