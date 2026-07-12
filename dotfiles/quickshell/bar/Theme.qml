pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var palette: JSON.parse(paletteFile.text())

    readonly property string fontFamily: "JetBrains Mono"
    readonly property int fontSize: 12
    readonly property int clockFontSize: 13

    readonly property color bg: palette.bg
    readonly property color menuBg: bg
    readonly property color cardBg: palette.cardBg
    readonly property color text: palette.text
    readonly property color textMuted: palette.textMuted
    readonly property color accent: palette.accent
    readonly property color danger: palette.danger

    readonly property color hover: palette.hover
    readonly property color pressed: palette.pressed
    readonly property color dangerHover: palette.dangerHover
    readonly property color dangerPressed: palette.dangerPressed
    readonly property color transparent: Qt.rgba(0, 0, 0, 0)
    readonly property color track: palette.track
    readonly property color trackMuted: palette.trackMuted
    readonly property color white: palette.white

    function reload(): void {
        paletteFile.reload();
    }

    property FileView paletteFile: FileView {
        path: Quickshell.env("HOME") + "/.config/theme/current/quickshell.json"
        preload: true
        blockLoading: true
        blockAllReads: true

        onLoaded: root.palette = JSON.parse(text())
    }
}
