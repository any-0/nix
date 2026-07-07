import QtQuick

Item {
    id: root

    required property var anchorWindow

    implicitWidth: codexButton.implicitWidth
    implicitHeight: 30
    width: implicitWidth
    height: 30

    BarButton {
        id: codexButton

        anchors.centerIn: parent
        icon: "✦"
        label: Status.codexLabel
        iconColor: Status.codexReady ? Theme.accent : Status.codexLoading ? Theme.textMuted : Theme.danger
        labelColor: Status.codexReady ? Theme.text : Status.codexLoading ? Theme.textMuted : Theme.danger
        onClicked: {
            if (button === Qt.RightButton) Status.refreshCodexUsage();
            else Popups.toggle(codexPopup);
        }
    }

    MenuPopup {
        id: codexPopup

        anchorWindow: root.anchorWindow
        anchorItem: codexButton
        menuWidth: 360

        Row {
            width: parent.width
            height: 30
            spacing: 8

            Text {
                width: parent.width - refreshButton.width - parent.spacing
                height: parent.height
                text: Status.codexPlan.length > 0 ? "CODEX · " + Status.codexPlan.toUpperCase() : "CODEX"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                id: refreshButton

                width: 30
                height: 30
                radius: 8
                color: refreshMouse.pressed ? Theme.pressed : refreshMouse.containsMouse ? Theme.hover : Theme.transparent

                Text {
                    anchors.centerIn: parent
                    text: Status.codexLoading ? "…" : "󰑓"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: refreshMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Status.refreshCodexUsage()
                }
            }
        }

        Text {
            width: parent.width
            visible: !Status.codexReady
            text: Status.codexLoading ? "Checking usage…" : Status.codexError
            color: Status.codexLoading ? Theme.textMuted : Theme.danger
            font.family: Theme.fontFamily
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        UsageRow {
            title: "5H LIMIT"
            percentLeft: Status.codexFiveHourPercentLeft
            pace: Status.codexPaceText(
                Status.codexFiveHourUsedPercent,
                Status.codexFiveHourResetAt,
                Status.codexFiveHourWindowSeconds,
                true)
            reset: Status.codexFiveHourReset
        }

        UsageRow {
            title: "WEEKLY"
            percentLeft: Status.codexWeeklyPercentLeft
            pace: Status.codexPaceText(
                Status.codexWeeklyUsedPercent,
                Status.codexWeeklyResetAt,
                Status.codexWeeklyWindowSeconds,
                false)
            reset: Status.codexWeeklyReset
        }

        UsageRow {
            title: "MONTHLY"
            visible: Status.codexMonthlyPercentLeft >= 0
            percentLeft: Status.codexMonthlyPercentLeft
            reset: Status.codexMonthlyReset
        }

        Rectangle {
            width: parent.width
            height: 1
            visible: Status.codexCredits >= 0 || Status.codexResetCredits >= 0
            color: Theme.track
        }

        Row {
            width: parent.width
            height: 24
            visible: Status.codexCredits >= 0 || Status.codexResetCredits >= 0

            Text {
                width: parent.width / 2
                height: parent.height
                text: Status.codexResetCredits >= 0 ? "Usage resets" : "Credits"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                width: parent.width / 2
                height: parent.height
                text: Status.codexResetCredits >= 0 ? String(Status.codexResetCredits) : Status.codexCreditsText()
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    component UsageRow: Item {
        required property string title
        required property int percentLeft
        property string reset: ""
        property string pace: ""

        width: parent.width
        height: pace.length > 0 ? 76 : 48

        readonly property int remaining: percentLeft >= 0 ? percentLeft : 0

        Column {
            anchors.fill: parent
            spacing: 5

            Row {
                width: parent.width
                height: 18

                Text {
                    width: parent.width * 0.38
                    height: parent.height
                    text: title
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    width: parent.width * 0.24
                    height: parent.height
                    text: Status.codexPercentText(percentLeft)
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    width: parent.width * 0.38
                    height: parent.height
                    text: reset.length > 0 ? "resets " + reset : ""
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideLeft
                }
            }

            Rectangle {
                width: parent.width
                height: 8
                radius: 4
                color: Theme.track

                Rectangle {
                    width: parent.width * remaining / 100
                    height: parent.height
                    radius: 4
                    color: remaining <= 10 ? Theme.danger : Theme.accent

                    Behavior on width {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            Text {
                width: parent.width
                visible: pace.length > 0
                text: pace
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 10
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }
    }
}
