import QtQuick
import QtQuick.Effects
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
    // The bar reserves enough width for the wider of the two clock lines.
    readonly property real parkedWidth: Math.max(barDateMetrics.width, barTimeMetrics.width)

    // 0 = parked in the bar, 1 = centered on the desktop.
    property real progress: 0

    function transitionProgress() {
        if (desktopEmpty) {
            toBarAnimation.stop();
            desktopDelay.restart();
        } else {
            desktopDelay.stop();
            toDesktopAnimation.stop();
            toBarAnimation.restart();
        }
    }

    onDesktopEmptyChanged: transitionProgress()

    Component.onCompleted: transitionProgress()

    Timer {
        id: desktopDelay

        interval: 5000
        onTriggered: toDesktopAnimation.restart()
    }

    NumberAnimation {
        id: toDesktopAnimation

        target: window
        property: "progress"
        to: 1
        duration: 900
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: toBarAnimation

        target: window
        property: "progress"
        to: 0
        duration: 450
        easing.type: Easing.OutCubic
    }

    function lerp(a, b) {
        return a + (b - a) * progress;
    }

    // Shadow fades in across the entire flight (0 parked, full on desktop).
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
        id: barDateMetrics
        font.family: Theme.barFontFamily
            font.features: { "tnum": 1 }
        font.pixelSize: Theme.clockFontSize
        font.weight: Font.Medium
        text: dateText.text
    }

    TextMetrics {
        id: barTimeMetrics
        font.family: Theme.barFontFamily
            font.features: { "tnum": 1 }
        font.pixelSize: Theme.clockFontSize
        font.weight: Font.Medium
        text: timeText.text
    }

    // Bar state stacks date above time; desktop state keeps the large time
    // above the date, slightly above the screen's vertical center.
    readonly property real deskCx: width / 2
    readonly property real deskTimeCy: height * 0.35
    readonly property real barLineOffset: barDateMetrics.height * 0.85 / 2

    Text {
        id: timeText

        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: Theme.text
        font.family: Theme.barFontFamily
            font.features: { "tnum": 1 }
        font.pixelSize: Math.round(window.lerp(Theme.clockFontSize, 112))
        font.weight: Font.Medium
        font.letterSpacing: window.lerp(0, -2)
        // Soft shadow for legibility on bright wallpapers; desktop mode only.
        layer.enabled: window.effectProgress > 0
        layer.effect: ClockShadow {}
        x: window.lerp(window.barClockCenterX, window.deskCx) - implicitWidth / 2
        y: window.lerp(window.barClockCenterY + window.barLineOffset, window.deskTimeCy) - implicitHeight / 2
    }

    Text {
        id: dateText

        text: Qt.formatDateTime(clock.date, "yyyy-MM-dd")
        color: Qt.rgba(
            window.lerp(Theme.textSecondary.r, Theme.text.r),
            window.lerp(Theme.textSecondary.g, Theme.text.g),
            window.lerp(Theme.textSecondary.b, Theme.text.b), 1)
        font.family: Theme.barFontFamily
            font.features: { "tnum": 1 }
        font.pixelSize: Math.round(window.lerp(Theme.clockFontSize, 24))
        font.weight: Font.Medium
        font.letterSpacing: window.lerp(0, 1)
        layer.enabled: window.effectProgress > 0
        layer.effect: ClockShadow {}
        x: window.lerp(window.barClockCenterX, window.deskCx) - implicitWidth / 2
        y: window.lerp(window.barClockCenterY - window.barLineOffset, window.deskTimeCy + timeText.implicitHeight / 2 + 6 + implicitHeight / 2) - implicitHeight / 2
    }

    component ClockShadow: MultiEffect {
        shadowEnabled: true
        shadowColor: "black"
        shadowBlur: 1.0
        shadowOpacity: 0.95 * window.effectProgress
        shadowVerticalOffset: 1
        blurMax: 64
        shadowScale: 1.04
        autoPaddingEnabled: true
    }
}
