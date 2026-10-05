import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland._WlrLayerShell
import "LauncherSearch.js" as Search

Scope {
    id: root
    property bool opened: false
    readonly property var results: Search.rank(DesktopEntries.applications.values, query.text)

    function open(text) {
        const workspace = Niri.workspaces.find(workspace => workspace.is_focused);
        const output = workspace && Quickshell.screens.find(screen => screen.name === workspace.output);
        if (!output) return;
        Popups.closeOpenPopup();
        window.screen = output;
        query.text = text;
        list.currentIndex = 0;
        opened = true;
        Qt.callLater(() => query.forceActiveFocus());
    }

    function close() { opened = false; }

    function moveSelection(delta) {
        if (results.length === 0) return;
        list.currentIndex = Math.max(0, Math.min(results.length - 1, list.currentIndex + delta));
        list.positionViewAtIndex(list.currentIndex, ListView.Contain);
    }

    function launch(index) {
        if (index < 0 || index >= results.length) return;
        const options = Search.launchOptions(results[index]);
        close();
        Qt.callLater(() => Quickshell.execDetached(options));
    }

    onResultsChanged: {
        list.currentIndex = results.length > 0 ? 0 : -1;
        list.positionViewAtBeginning();
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { if (root.opened) root.close(); else root.open(""); }
        function open(query: string): void { root.open(query); }
        function close(): void { root.close(); }
    }

    PanelWindow {
        id: window
        visible: root.opened
        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: -1
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-launcher"
        onClosed: root.close()

        Rectangle {
            anchors.fill: parent
            color: "#50000000"
            MouseArea { anchors.fill: parent; onClicked: root.close() }
        }

        Rectangle {
            id: menu
            width: Math.min(660, window.width - 48)
            height: Math.min(576, window.height - 48, 149 + Math.max(1, root.results.length) * 61)
            x: Math.round((window.width - width) / 2)
            y: Math.round((window.height - Math.min(576, window.height - 48)) / 3)
            radius: 18
            color: "#292c35"
            border.width: 1
            border.color: "#505561"

            // Consume clicks on the panel's padding instead of dismissing it.
            MouseArea { anchors.fill: parent }

            Item {
                id: searchBox
                x: 24; y: 16
                width: parent.width - 48; height: 56
                Text {
                    text: "󰍉"
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: 24
                    color: Theme.accent
                }
                TextInput {
                    id: query
                    x: 42
                    width: parent.width - x - 48
                    height: parent.height
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: Theme.barFontFamily
                    font.pixelSize: 22
                    color: Theme.text
                    selectionColor: Theme.accent
                    selectedTextColor: "#202128"
                    clip: true
                    selectByMouse: true
                    focus: true
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) root.close();
                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.launch(list.currentIndex);
                        else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) root.moveSelection(event.modifiers & Qt.ShiftModifier ? -1 : 1);
                        else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) root.moveSelection(-1);
                        else if (event.key === Qt.Key_PageDown) root.moveSelection(7);
                        else if (event.key === Qt.Key_PageUp) root.moveSelection(-7);
                        else return;
                        event.accepted = true;
                    }
                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: query.text.length === 0
                        text: "Search applications…"
                        font: query.font
                        color: Theme.textMuted
                    }
                }
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "esc"
                    font.family: Theme.barFontFamily
                    font.pixelSize: 12
                    color: Theme.textMuted
                }
            }

            Rectangle { x: 24; y: 86; width: parent.width - 48; height: 1; color: Theme.track }

            ListView {
                id: list
                x: 12; y: 99
                width: parent.width - 24
                height: parent.height - y - 50
                model: root.results
                clip: true
                spacing: 3
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0

                delegate: Rectangle {
                    id: result
                    required property var modelData
                    required property int index
                    readonly property bool selected: ListView.isCurrentItem
                    width: list.width
                    height: 58
                    radius: 10
                    color: selected ? "#334568" : hover.containsMouse ? Theme.hover : "transparent"

                    Image {
                        id: icon
                        x: 15; y: 12; width: 34; height: 34
                        source: result.modelData.icon ? Quickshell.iconPath(result.modelData.icon, true) : ""
                        sourceSize.width: 34; sourceSize.height: 34
                        fillMode: Image.PreserveAspectFit
                    }
                    Text {
                        x: 15; y: 12; width: 34; height: 34
                        visible: icon.status !== Image.Ready
                        text: result.modelData.name.slice(0, 1).toUpperCase()
                        color: Theme.textSecondary
                        font.family: Theme.barFontFamily
                        font.pixelSize: 22
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    Text {
                        x: 64; y: 9; width: parent.width - 110
                        text: result.modelData.name
                        textFormat: Text.PlainText
                        color: Theme.text
                        font.family: Theme.barFontFamily
                        font.pixelSize: 16
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                    Text {
                        x: 64; y: 33; width: parent.width - 110
                        text: result.modelData.genericName || result.modelData.comment || result.modelData.id
                        textFormat: Text.PlainText
                        color: result.selected ? Theme.textSecondary : Theme.textMuted
                        font.family: Theme.barFontFamily
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                    Text {
                        visible: result.selected
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: "↵"
                        color: Theme.textSecondary
                        font.family: Theme.barFontFamily
                        font.pixelSize: 19
                    }
                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPositionChanged: if (containsMouse) list.currentIndex = result.index
                        onClicked: root.launch(result.index)
                    }
                }
            }

            Text {
                anchors.centerIn: list
                visible: root.results.length === 0
                text: "No matching applications"
                color: Theme.textMuted
                font.family: Theme.barFontFamily
                font.pixelSize: 16
            }

            Text {
                x: 26; anchors.bottom: parent.bottom; anchors.bottomMargin: 19
                text: root.results.length + (root.results.length === 1 ? " application" : " applications")
                color: Theme.textMuted
                font.family: Theme.barFontFamily
                font.pixelSize: 11
            }
            Text {
                anchors.right: parent.right; anchors.rightMargin: 26
                anchors.bottom: parent.bottom; anchors.bottomMargin: 19
                text: "↑ ↓  select      ↵  launch"
                color: Theme.textSecondary
                font.family: Theme.barFontFamily
                font.pixelSize: 11
            }
        }
    }
}
