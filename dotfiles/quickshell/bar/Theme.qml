pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property string fontFamily: "JetBrains Mono"
    readonly property int fontSize: 12
    readonly property int clockFontSize: 13

    readonly property color bg: Qt.rgba(32 / 255, 32 / 255, 38 / 255, 0.62)
    readonly property color menuBg: bg
    // Desktop cards have no blur behind them, so slightly more opaque.
    readonly property color cardBg: Qt.rgba(32 / 255, 32 / 255, 38 / 255, 0.8)
    readonly property color text: "#f2f2f4"
    readonly property color textMuted: "#9a9aa2"
    readonly property color accent: "#7aa2f7"
    readonly property color danger: "#ff7a90"

    readonly property color hover: Qt.rgba(1, 1, 1, 0.09)
    readonly property color pressed: Qt.rgba(1, 1, 1, 0.14)
    readonly property color dangerHover: Qt.rgba(1, 122 / 255, 144 / 255, 0.13)
    readonly property color dangerPressed: Qt.rgba(1, 122 / 255, 144 / 255, 0.22)
    readonly property color transparent: Qt.rgba(0, 0, 0, 0)
    readonly property color track: Qt.rgba(1, 1, 1, 0.13)
    readonly property color trackMuted: Qt.rgba(1, 1, 1, 0.08)
    readonly property color white: "#ffffff"
}
