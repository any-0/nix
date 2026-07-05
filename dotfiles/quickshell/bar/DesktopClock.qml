import QtQuick
import Quickshell
import Quickshell.Wayland._WlrLayerShell

// Always-on, click-through overlay that owns THE clock text. The bar never
// draws its own clock — it only reserves a hover/click slot. These two Text
// elements morph continuously (position + font size) between the bar slot and
// the desktop center, so it is literally one text moving, never a swap.
PanelWindow {
    id: window

    required property var screenInfo
    required property real barClockCenterX
    required property real barClockCenterY

    readonly property bool desktopEmpty: Niri.activeWorkspaceEmpty(screenInfo.name)
    // Width of the parked "yyyy-MM-dd  HH:mm" block; the bar sizes its
    // placeholder slot from this.
    readonly property real parkedWidth: barBlockMetrics.width

    // 0 = parked in the bar, 1 = centered on the desktop.
    property real progress: desktopEmpty ? 1 : 0

    Behavior on progress {
        NumberAnimation {
            duration: 450
            easing.type: Easing.OutCubic
        }
    }

    function lerp(a, b) {
        return a + (b - a) * progress;
    }

    // Outline fades in across the entire flight (0 parked, full on desktop).
    readonly property real effectProgress: progress

    screen: screenInfo
    visible: true
    color: "transparent"
    // -1: do not shift for other surfaces' exclusive zones (the bar's 30px
    // would otherwise push this window down, landing the parked clock one
    // bar-height too low).
    exclusiveZone: -1
    exclusionMode: ExclusionMode.Normal
    focusable: false
    // Top (not Overlay) so fullscreen windows cover the parked clock exactly
    // like they cover the bar; layer surfaces map after the bar, so this
    // still draws above it.
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-clock-" + screenInfo.name
    mask: Region {}
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    TextMetrics {
        id: barBlockMetrics
        font.family: Theme.fontFamily
        font.pixelSize: Theme.clockFontSize
        font.weight: Font.DemiBold
        text: dateText.text + "  " + timeText.text
    }

    TextMetrics {
        id: barDateMetrics
        font.family: Theme.fontFamily
        font.pixelSize: Theme.clockFontSize
        font.weight: Font.DemiBold
        text: dateText.text
    }

    TextMetrics {
        id: barTimeMetrics
        font.family: Theme.fontFamily
        font.pixelSize: Theme.clockFontSize
        font.weight: Font.DemiBold
        text: timeText.text
    }

    // Endpoint centers. Bar state lays the block out as [date  time] centered
    // on the slot; desktop state stacks time above date, slightly above the
    // screen's vertical center.
    readonly property real deskCx: width / 2
    readonly property real deskTimeCy: height * 0.35
    readonly property real barLeft: barClockCenterX - parkedWidth / 2
    readonly property real barDateCx: barLeft + barDateMetrics.width / 2
    readonly property real barTimeCx: barLeft + parkedWidth - barTimeMetrics.width / 2

    Text {
        id: timeText

        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(window.lerp(Theme.clockFontSize, 96))
        font.weight: Font.DemiBold
        // Soft black outline for legibility on bright wallpapers; desktop
        // mode only (fades in over the last half of the flight).
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.8 * window.effectProgress)
        x: window.lerp(window.barTimeCx, window.deskCx) - implicitWidth / 2
        y: window.lerp(window.barClockCenterY, window.deskTimeCy) - implicitHeight / 2
    }

    Text {
        id: dateText

        text: Qt.formatDateTime(clock.date, "yyyy-MM-dd")
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(window.lerp(Theme.clockFontSize, 29))
        font.weight: Font.DemiBold
        style: Text.Outline
        styleColor: Qt.rgba(0, 0, 0, 0.8 * window.effectProgress)
        x: window.lerp(window.barDateCx, window.deskCx) - implicitWidth / 2
        y: window.lerp(window.barClockCenterY, window.deskTimeCy + timeText.implicitHeight / 2 + 6 + implicitHeight / 2) - implicitHeight / 2
    }
}
