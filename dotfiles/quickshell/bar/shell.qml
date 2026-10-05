import QtQuick
import Quickshell

ShellRoot {
    Launcher {}
    readonly property var physicalScreens: Quickshell.screens.filter(screen => !screen.name.startsWith("portrait-"))
    readonly property var primaryScreen: physicalScreens.find(screen => screen.name === "DP-1") || physicalScreens[0]

    NotificationToasts {
        screenInfo: primaryScreen
    }

    Connections {
        target: Quickshell

        function onReloadCompleted() {
            Quickshell.inhibitReloadPopup();
        }
    }

    Connections {
        target: Niri

        function onInteraction() {
            Popups.closeOpenPopupFromInteraction();
        }
    }

    Variants {
        // Region outputs are work areas inside DP-1, not additional panels.
        model: physicalScreens

        Scope {
            required property var modelData

            Bar {
                id: barWindow
                screenInfo: modelData
                showMetrics: modelData === primaryScreen
                desktopClockVisible: Niri.activeWorkspaceEmpty(modelData.name)
                desktopClockSlotWidth: desktopClock.parkedWidth
            }

            DesktopClock {
                id: desktopClock
                screenInfo: modelData
                barClockCenterX: barWindow.clockCenterX
                barClockCenterY: barWindow.clockCenterY
            }

            DesktopStatus {
                screenInfo: modelData
                barCenterY: barWindow.clockCenterY
                networkIconBarX: barWindow.networkIconCenterX
                volumeIconBarX: barWindow.volumeIconCenterX
                volumeLabelBarX: barWindow.volumeLabelCenterX
                bluetoothIconBarX: barWindow.bluetoothIconCenterX
            }
        }
    }
}
