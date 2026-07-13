import QtQuick
import Quickshell
import Quickshell.Wayland._WlrLayerShell

// Always-on overlay that owns the three status icons (network / volume /
// bluetooth). Like DesktopClock, the bar never draws these glyphs — it only
// reserves hover/click slots. On an empty workspace each icon flies from its
// bar slot to a desktop card that unfolds around it, so it is literally one
// glyph moving, never a swap.
PanelWindow {
    id: window

    required property var screenInfo
    required property real barCenterY
    required property real networkIconBarX
    required property real volumeIconBarX
    required property real volumeLabelBarX
    required property real bluetoothIconBarX

    readonly property bool desktopEmpty: Niri.activeWorkspaceEmpty(screenInfo.name)
    readonly property bool cardsSettled: networkCard.progress === 1 && volumeCard.progress === 1 && bluetoothCard.progress === 1

    readonly property int toDesktopFlightMs: 900
    readonly property int toBarFlightMs: 450
    readonly property int staggerMs: 60

    readonly property real cardWidth: 260
    readonly property real cardHeight: 140
    readonly property real cardGap: 20
    // Left-aligned vertical stack at the screen's optical center (slightly
    // above true center), independent of the clock.
    readonly property real cardsLeft: 24
    readonly property real cardsTop: height * 0.47 - (cardHeight * 3 + cardGap * 2) / 2

    screen: screenInfo
    visible: true
    color: "transparent"
    // -1: do not shift for the bar's exclusive zone, coordinates must match
    // the screen exactly.
    exclusiveZone: -1
    exclusionMode: ExclusionMode.Normal
    focusable: false
    // Top (not Overlay) so fullscreen windows cover the parked icons exactly
    // like they cover the bar.
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-desktop-" + screenInfo.name
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Input goes only to the card rects, and only while the cards are out;
    // everything else clicks through to the desktop.
    mask: cardsSettled ? cardsRegion : emptyRegion

    Region {
        id: emptyRegion
    }

    // Exact card shapes (straight bands + ellipse-quarter corners inset 1px),
    // same technique as MenuPopup, shared by the input mask and the blur.
    Region {
        id: cardsRegion

        CardRegion {
            cardY: window.cardsTop
        }

        CardRegion {
            cardY: window.cardsTop + window.cardHeight + window.cardGap
        }

        CardRegion {
            cardY: window.cardsTop + (window.cardHeight + window.cardGap) * 2
        }
    }

    component CardRegion: Region {
        id: cardRegion

        required property real cardY
        readonly property real cardX: window.cardsLeft
        readonly property int r: 14
        readonly property int inset: 1

        x: cardX + r
        y: cardY
        width: window.cardWidth - r * 2
        height: window.cardHeight

        Region {
            x: cardRegion.cardX
            y: cardRegion.cardY + cardRegion.r
            width: window.cardWidth
            height: window.cardHeight - cardRegion.r * 2
        }

        Region {
            shape: RegionShape.Ellipse
            x: cardRegion.cardX + cardRegion.inset
            y: cardRegion.cardY + cardRegion.inset
            width: (cardRegion.r - cardRegion.inset) * 2
            height: (cardRegion.r - cardRegion.inset) * 2
        }

        Region {
            shape: RegionShape.Ellipse
            x: cardRegion.cardX + window.cardWidth - cardRegion.r * 2 + cardRegion.inset
            y: cardRegion.cardY + cardRegion.inset
            width: (cardRegion.r - cardRegion.inset) * 2
            height: (cardRegion.r - cardRegion.inset) * 2
        }

        Region {
            shape: RegionShape.Ellipse
            x: cardRegion.cardX + cardRegion.inset
            y: cardRegion.cardY + window.cardHeight - cardRegion.r * 2 + cardRegion.inset
            width: (cardRegion.r - cardRegion.inset) * 2
            height: (cardRegion.r - cardRegion.inset) * 2
        }

        Region {
            shape: RegionShape.Ellipse
            x: cardRegion.cardX + window.cardWidth - cardRegion.r * 2 + cardRegion.inset
            y: cardRegion.cardY + window.cardHeight - cardRegion.r * 2 + cardRegion.inset
            width: (cardRegion.r - cardRegion.inset) * 2
            height: (cardRegion.r - cardRegion.inset) * 2
        }
    }

    // ---- Cards ----

    StatusCard {
        id: networkCard

        index: 0
        barIconCx: window.networkIconBarX
        icon: Status.networkIcon
        iconColor: Status.networkOffline ? Theme.danger : Theme.text
        title: "NETWORK"
        headerTrailing: Status.networkLabel

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 36

            Column {
                spacing: 2

                Text {
                    text: "󰁅 DOWN"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                }

                Text {
                    text: Status.networkDownRate
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                }
            }

            Column {
                spacing: 2

                Text {
                    text: "󰁝 UP"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                }

                Text {
                    text: Status.networkUpRate
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                }
            }
        }
    }

    StatusCard {
        id: volumeCard

        index: 1
        barIconCx: window.volumeIconBarX
        icon: Status.volumeIcon
        iconColor: Status.volumeMuted ? Theme.textMuted : Theme.text
        title: "VOLUME"
        iconClickable: true
        onIconClicked: Status.toggleMute()

        Item {
            anchors.fill: parent

            Item {
                id: deskSlider

                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 30

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 8
                    radius: 4
                    color: Theme.track

                    Rectangle {
                        width: parent.width * Status.volumePercent / 100
                        height: parent.height
                        radius: 4
                        color: Status.volumeMuted ? Theme.textMuted : Theme.accent

                        Behavior on width {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    color: Theme.white
                    x: Math.max(0, Math.min(deskSlider.width - width, deskSlider.width * Status.volumePercent / 100 - width / 2))
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on x {
                        NumberAnimation {
                            duration: 120
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: event => Status.setVolume(event.x / width * 100)
                    onPositionChanged: event => {
                        if (pressed) Status.setVolume(event.x / width * 100);
                    }
                    onWheel: wheel => {
                        Status.setVolume(Status.volumePercent + (wheel.angleDelta.y > 0 ? 5 : -5));
                        wheel.accepted = true;
                    }
                }
            }
        }
    }

    StatusCard {
        id: bluetoothCard

        index: 2
        barIconCx: window.bluetoothIconBarX
        icon: "󰂯"
        iconColor: Status.bluetoothLowBattery ? Theme.danger : Status.bluetoothConnected ? Theme.accent : Theme.textMuted
        title: "BLUETOOTH"
        headerTrailing: Status.bluetoothBatteryText

        Item {
            anchors.fill: parent

            Text {
                visible: Status.bluetoothPairedDevices.length === 0
                height: 26
                text: "Nothing paired"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                verticalAlignment: Text.AlignVCenter
            }

            ListView {
                anchors.fill: parent
                clip: true
                model: Status.bluetoothPairedDevices
                spacing: 2

                delegate: Rectangle {
                    required property var modelData

                    readonly property bool deviceConnected: modelData.connected

                    width: parent.width
                    height: 26
                    radius: 8
                    color: rowMouse.pressed ? Theme.pressed : rowMouse.containsMouse ? Theme.hover : Theme.transparent

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.right: trailingText.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name
                        color: deviceConnected ? Theme.text : Theme.textMuted
                        elide: Text.ElideRight
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Text {
                        id: trailingText

                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: deviceConnected ? (modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : "󰂱") : ""
                        color: deviceConnected ? Theme.accent : Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: rowMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: deviceConnected ? modelData.disconnect() : modelData.connect()
                    }
                }
            }
        }
    }

    // The volume percent is owned here too (ghost slot in the bar) and flies
    // from its bar label position into the volume card's header, growing a
    // little on the way.
    Text {
        text: Status.volumePercent + "%"
        color: Status.volumeMuted ? Theme.textMuted : Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(volumeCard.lerp(12, 16))
        font.weight: Font.DemiBold
        x: volumeCard.lerp(window.volumeLabelBarX - implicitWidth / 2, volumeCard.finalX + window.cardWidth - 18 - implicitWidth)
        y: volumeCard.lerp(window.barCenterY, volumeCard.finalY + 14 + 17) - implicitHeight / 2
    }

    component StatusCard: Item {
        id: card

        required property int index
        required property real barIconCx
        property string icon
        property color iconColor: Theme.text
        property string title
        property string headerTrailing: ""
        property bool iconClickable: false
        signal iconClicked()
        default property alias body: bodySlot.data

        readonly property real finalX: window.cardsLeft
        readonly property real finalY: window.cardsTop + index * (window.cardHeight + window.cardGap)

        // 0 = folded into the bar behind its icon, 1 = unfolded on the desktop.
        property real progress: 0

        function transitionProgress() {
            if (window.desktopEmpty) {
                toBarAnimation.stop();
                desktopDelay.restart();
            } else {
                desktopDelay.stop();
                toDesktopAnimation.stop();
                toBarAnimation.restart();
            }
        }

        Component.onCompleted: transitionProgress()

        Connections {
            target: window

            function onDesktopEmptyChanged() {
                card.transitionProgress();
            }
        }

        Timer {
            id: desktopDelay

            interval: 5000 + card.index * window.staggerMs
            onTriggered: toDesktopAnimation.restart()
        }

        NumberAnimation {
            id: toDesktopAnimation

            target: card
            property: "progress"
            to: 1
            duration: window.toDesktopFlightMs
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            id: toBarAnimation

            target: card
            property: "progress"
            to: 0
            duration: window.toBarFlightMs
            easing.type: Easing.OutCubic
        }

        function lerp(a, b) {
            return a + (b - a) * progress;
        }

        // Live center of the flying icon.
        readonly property real iconCx: lerp(barIconCx, finalX + 18 + 15)
        readonly property real iconCy: lerp(window.barCenterY, finalY + 14 + 17)

        anchors.fill: parent

        Rectangle {
            id: bg

            x: card.lerp(card.barIconCx - 17, card.finalX)
            y: card.lerp(window.barCenterY - 13, card.finalY)
            width: card.lerp(34, window.cardWidth)
            height: card.lerp(26, window.cardHeight)
            radius: 14
            color: Theme.cardBg
            border.color: Qt.rgba(1, 1, 1, 0.06)
            border.width: 1
            clip: true
            // Materializes around the icon over the first third of the flight.
            opacity: Math.min(1, card.progress * 3)

            Item {
                id: contentBox

                // Fixed at the card's final content size (the unfolding bg
                // clips it) so layouts — the volume slider especially — never
                // compute against mid-flight geometry.
                x: 18
                y: 14
                width: window.cardWidth - 36
                height: window.cardHeight - 30
                // Content fades in once the card has mostly unfolded.
                opacity: Math.max(0, (card.progress - 0.65) / 0.35)

                Text {
                    x: 40
                    height: 34
                    text: card.title
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.5
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    anchors.right: parent.right
                    height: 34
                    text: card.headerTrailing
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    verticalAlignment: Text.AlignVCenter
                }

                Item {
                    id: bodySlot

                    anchors.fill: parent
                    anchors.topMargin: 42
                    clip: true
                }
            }

            MouseArea {
                visible: card.iconClickable
                x: 6
                y: 6
                width: 46
                height: 42
                onClicked: card.iconClicked()
            }
        }

        // THE icon: rendered here always (the bar only reserves a ghost slot),
        // so the parked and desktop states are literally the same glyph.
        Text {
            text: card.icon
            color: card.iconColor
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(card.lerp(Theme.fontSize, 26))
            font.weight: Font.DemiBold
            x: card.iconCx - implicitWidth / 2
            y: card.iconCy - implicitHeight / 2

            Behavior on color {
                ColorAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
