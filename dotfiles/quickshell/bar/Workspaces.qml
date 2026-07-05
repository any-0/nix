import QtQuick
import Quickshell.Widgets

Item {
    id: root

    required property string screenName
    property Item focusedItem: null

    implicitWidth: workspaceRow.implicitWidth
    implicitHeight: 30
    height: 30

    function updateFocusedItem() {
        for (let i = 0; i < repeater.count; i++) {
            const item = repeater.itemAt(i);
            if (item && item.focused) {
                focusedItem = item;
                return;
            }
        }
        focusedItem = null;
    }

    Row {
        id: workspaceRow

        anchors.centerIn: parent
        spacing: 4

        Repeater {
            id: repeater

            model: Niri.workspacesForScreen(root.screenName)

            delegate: Item {
                id: workspaceButton

                required property var modelData
                readonly property var workspace: modelData
                readonly property var iconView: Niri.workspaceIconViews(workspace)
                readonly property bool focused: workspace.is_focused

                width: highlight.width
                height: 30

                onFocusedChanged: if (focused) root.focusedItem = workspaceButton
                Component.onCompleted: if (focused) root.focusedItem = workspaceButton
                Component.onDestruction: if (root.focusedItem === workspaceButton) root.updateFocusedItem()

                Rectangle {
                    id: highlight

                    anchors.verticalCenter: parent.verticalCenter
                    width: content.implicitWidth + 16
                    height: 24
                    radius: 8
                    color: workspaceMouse.pressed ? Theme.pressed : workspaceMouse.containsMouse ? Theme.hover : Theme.transparent

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }

                    Row {
                        id: content

                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            height: 20
                            text: Niri.workspaceDisplayName(workspaceButton.workspace)
                            color: workspaceButton.workspace.is_urgent ? Theme.danger : workspaceButton.workspace.is_focused ? Theme.accent : Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            verticalAlignment: Text.AlignVCenter

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Row {
                            spacing: 3
                            anchors.verticalCenter: parent.verticalCenter

                            Repeater {
                                model: workspaceButton.iconView.icons

                                delegate: Item {
                                    required property var modelData

                                    width: 20
                                    height: 20

                                    IconImage {
                                        id: appIcon

                                        anchors.centerIn: parent
                                        width: 18
                                        height: 18
                                        source: modelData.source
                                        visible: modelData.source !== "" && status === Image.Ready
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.fallback
                                        visible: !appIcon.visible
                                        color: modelData.selected ? Theme.accent : Theme.textMuted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: Niri.focusWindow(modelData.windowId)
                                    }
                                }
                            }

                            Text {
                                height: 20
                                text: "+" + workspaceButton.iconView.hiddenCount
                                visible: workspaceButton.iconView.hiddenCount > 0
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                MouseArea {
                    id: workspaceMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (workspaceButton.workspace.active_window_id !== null) Niri.focusWindow(workspaceButton.workspace.active_window_id);
                        else Niri.focusWorkspace(workspaceButton.workspace);
                    }
                }
            }
        }
    }

    Rectangle {
        height: 2
        radius: 1
        y: 27
        x: root.focusedItem ? workspaceRow.x + root.focusedItem.x + 8 : 0
        width: root.focusedItem ? Math.max(10, root.focusedItem.width - 16) : 0
        color: Theme.accent
        visible: root.focusedItem !== null

        Behavior on x {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }
}
