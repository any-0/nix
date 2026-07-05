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

        Bar {
            required property var modelData
            screenInfo: modelData
        }
    }
}
