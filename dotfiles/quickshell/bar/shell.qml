import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    IpcHandler {
        target: "theme"

        function reload(): void {
            Theme.reload();
        }
    }

    Connections {
        target: Niri

        function onInteraction() {
            Popups.closeOpenPopupFromInteraction();
        }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            required property var modelData

            Bar {
                id: barWindow
                screenInfo: modelData
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
