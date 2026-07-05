import QtQuick
import Quickshell

ShellRoot {
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
        }
    }
}
