import QtQuick

Item {
    id: root

    required property var anchorWindow

    implicitWidth: claudeButton.implicitWidth
    implicitHeight: 30
    width: implicitWidth
    height: 30

    BarButton {
        id: claudeButton

        anchors.centerIn: parent
        icon: "✶"
        label: Status.claudeLabel
        iconColor: Status.claudeReady ? Theme.accent : Status.claudeLoading ? Theme.textMuted : Theme.danger
        labelColor: Status.claudeReady ? Theme.text : Status.claudeLoading ? Theme.textMuted : Theme.danger
        onClicked: {
            if (button === Qt.RightButton) Status.refreshClaudeUsage();
            else Popups.toggle(claudePopup);
        }
    }

    MenuPopup {
        id: claudePopup

        anchorWindow: root.anchorWindow
        anchorItem: claudeButton
        menuWidth: 360

        Row {
            width: parent.width
            height: 30
            spacing: 8

            Text {
                width: parent.width - refreshButton.width - parent.spacing
                height: parent.height
                text: Status.claudePlan.length > 0 ? "CLAUDE · " + Status.claudePlan.toUpperCase() : "CLAUDE"
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
                    text: Status.claudeLoading ? "…" : "󰑓"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: refreshMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Status.refreshClaudeUsage()
                }
            }
        }

        Text {
            width: parent.width
            visible: !Status.claudeReady
            text: Status.claudeLoading ? "Checking usage…" : Status.claudeError
            color: Status.claudeLoading ? Theme.textMuted : Theme.danger
            font.family: Theme.fontFamily
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        UsageRow {
            title: "5H LIMIT"
            percentLeft: Status.claudeFiveHourPercentLeft
            pace: Status.claudePaceText(
                Status.claudeFiveHourUsedPercent,
                Status.claudeFiveHourResetAt,
                Status.claudeFiveHourWindowSeconds,
                true)
            reset: Status.claudeFiveHourReset
        }

        UsageRow {
            title: "WEEKLY"
            percentLeft: Status.claudeWeeklyPercentLeft
            pace: Status.claudePaceText(
                Status.claudeWeeklyUsedPercent,
                Status.claudeWeeklyResetAt,
                Status.claudeWeeklyWindowSeconds,
                false)
            reset: Status.claudeWeeklyReset
        }

        UsageRow {
            title: "MONTHLY"
            visible: Status.claudeMonthlyPercentLeft >= 0
            percentLeft: Status.claudeMonthlyPercentLeft
            reset: Status.claudeMonthlyReset
        }

        Rectangle {
            width: parent.width
            height: 1
            visible: Status.claudeCredits >= 0
            color: Theme.track
        }

        Row {
            width: parent.width
            height: 24
            visible: Status.claudeCredits >= 0

            Text {
                width: parent.width / 2
                height: parent.height
                text: "Extra usage"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                width: parent.width / 2
                height: parent.height
                text: Status.claudeCredits < 0 ? "Unknown" : Status.claudeCredits.toFixed(2)
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
