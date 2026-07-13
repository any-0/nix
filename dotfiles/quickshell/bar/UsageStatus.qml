import QtQuick

Item {
    id: root

    required property var anchorWindow
    required property string providerName
    required property string providerIcon
    required property string usageLabel
    required property bool ready
    required property bool loading
    required property string errorText
    required property string plan
    required property int fiveHourPercentLeft
    required property string fiveHourPace
    required property string fiveHourReset
    required property int weeklyPercentLeft
    required property string weeklyPace
    required property string weeklyReset
    required property int monthlyPercentLeft
    required property string monthlyReset
    required property bool footerVisible
    required property string footerLabel
    required property string footerValue
    required property var refreshAction

    implicitWidth: usageButton.implicitWidth
    implicitHeight: 30
    width: implicitWidth
    height: 30

    BarButton {
        id: usageButton

        anchors.centerIn: parent
        icon: root.providerIcon
        label: root.usageLabel
        iconColor: root.ready ? Theme.accent : root.loading ? Theme.textMuted : Theme.danger
        labelColor: root.ready ? Theme.text : root.loading ? Theme.textMuted : Theme.danger
        onClicked: {
            if (button === Qt.RightButton) root.refreshAction();
            else Popups.toggle(usagePopup);
        }
    }

    MenuPopup {
        id: usagePopup

        anchorWindow: root.anchorWindow
        anchorItem: usageButton
        menuWidth: 360

        Row {
            width: parent.width
            height: 30
            spacing: 8

            Text {
                width: parent.width - refreshButton.width - parent.spacing
                height: parent.height
                text: root.plan.length > 0 ? root.providerName.toUpperCase() + " · " + root.plan.toUpperCase() : root.providerName.toUpperCase()
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
                    text: root.loading ? "…" : "󰑓"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: refreshMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.refreshAction()
                }
            }
        }

        Text {
            width: parent.width
            visible: !root.ready
            text: root.loading ? "Checking usage…" : root.errorText
            color: root.loading ? Theme.textMuted : Theme.danger
            font.family: Theme.fontFamily
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        UsageRow {
            title: "5H LIMIT"
            percentLeft: root.fiveHourPercentLeft
            pace: root.fiveHourPace
            reset: root.fiveHourReset
        }

        UsageRow {
            title: "WEEKLY"
            percentLeft: root.weeklyPercentLeft
            pace: root.weeklyPace
            reset: root.weeklyReset
        }

        UsageRow {
            title: "MONTHLY"
            visible: root.monthlyPercentLeft >= 0
            percentLeft: root.monthlyPercentLeft
            reset: root.monthlyReset
        }

        Rectangle {
            width: parent.width
            height: 1
            visible: root.footerVisible
            color: Theme.track
        }

        Row {
            width: parent.width
            height: 24
            visible: root.footerVisible

            Text {
                width: parent.width / 2
                height: parent.height
                text: root.footerLabel
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                width: parent.width / 2
                height: parent.height
                text: root.footerValue
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
                    text: Status.usagePercentText(percentLeft)
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
