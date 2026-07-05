import QtQuick
import Quickshell.Widgets

Row {
    id: root

    required property string screenName

    spacing: 4

    Repeater {
        model: Niri.workspacesForScreen(root.screenName)

        delegate: Item {
            required property var modelData

            width: workspaceButton.width
            height: workspaceButton.height

            Rectangle {
                id: workspaceButton

                readonly property var workspace: parent.modelData
                readonly property var iconView: Niri.workspaceIconViews(workspace)

                height: 24
                width: workspaceContent.implicitWidth
                color: "transparent"

                Row {
                    id: workspaceContent
                    z: 1
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 7

                    Text {
                        text: Niri.workspaceDisplayName(workspaceButton.workspace)
                        color: workspaceButton.workspace.is_urgent ? Theme.danger : Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        verticalAlignment: Text.AlignVCenter
                    }

                    Row {
                        spacing: 3
                        anchors.verticalCenter: parent.verticalCenter

                        Repeater {
                            model: workspaceButton.iconView.icons

                            delegate: Rectangle {
                                required property var modelData

                                width: 18
                                height: 18
                                radius: 6
                                color: "#14ffffff"
                                border.width: modelData.selected ? 1 : 0
                                border.color: workspaceButton.workspace.is_focused ? "#33ffffff" : "#47000000"

                                IconImage {
                                    id: appIcon
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    source: modelData.source
                                    visible: modelData.source !== "" && status === Image.Ready
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.fallback
                                    visible: !appIcon.visible
                                    color: Niri.workspacePalette(workspaceButton.workspace.idx)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: Niri.focusWindow(modelData.windowId)
                                }
                            }
                        }

                        Text {
                            text: "+" + workspaceButton.iconView.hiddenCount
                            visible: workspaceButton.iconView.hiddenCount > 0
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (workspaceButton.workspace.active_window_id !== null) Niri.focusWindow(workspaceButton.workspace.active_window_id);
                        else Niri.focusWorkspace(workspaceButton.workspace);
                    }
                }
            }
        }
    }
}
