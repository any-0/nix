import QtQuick
import Quickshell

Item {
    id: root

    required property var anchorWindow
    required property string providerName
    required property string providerIcon
    required property string usageLabel
    required property string usageReset
    required property bool ready
    required property bool loading
    required property string errorText
    required property string plan
    required property string updatedAt
    required property int weeklyPercentLeft
    required property string weeklyPace
    required property string weeklyReset
    required property int monthlyPercentLeft
    required property string monthlyReset
    required property bool footerVisible
    required property string footerLabel
    required property string footerValue
    required property var refreshAction
    property bool expanded: false

    implicitWidth: expanded ? 280 : usageButton.implicitWidth
    implicitHeight: expanded ? 94 : 30
    width: implicitWidth
    height: implicitHeight

    SystemClock {
        id: updateClock
        precision: SystemClock.Seconds
    }

    readonly property int updateAgeSeconds: updatedAt.length > 0
        ? Math.max(0, Math.floor((updateClock.date.getTime() - Date.parse(updatedAt)) / 1000))
        : 0

    function updatedAgoText(seconds) {
        if (seconds < 60) return seconds + "s ago";
        if (seconds < 3600) return Math.floor(seconds / 60) + "m ago";
        if (seconds < 86400) return Math.floor(seconds / 3600) + "h ago";
        return Math.floor(seconds / 86400) + "d ago";
    }

    BarButton {
        id: usageButton
        visible: !root.expanded

        anchors.centerIn: parent
        icon: root.providerIcon
        iconFontFamily: "IosevkaTermSlab Nerd Font Mono"
        iconFontWeight: Font.Normal
        centerIconInk: true
        label: root.usageLabel + (root.usageReset.length > 0
            ? '<br><font color="' + Theme.textSecondary + '">' + root.usageReset + '</font>' : "")
        labelTextFormat: Text.StyledText
        labelFontSize: root.usageReset.length > 0 ? 10 : Theme.fontSize
        labelLineHeight: 0.85
        iconColor: root.ready ? Theme.accent : root.loading ? Theme.textMuted : Theme.danger
        labelColor: root.ready ? Theme.text : root.loading ? Theme.textMuted : Theme.danger
        onClicked: button => {
            if (button === Qt.RightButton) root.refreshAction();
            else Popups.toggle(usagePopup);
        }
    }

    Item {
        id: expandedUsage
        visible: root.expanded
        anchors.fill: parent

        BarButton {
            y: 12
            icon: root.providerIcon
            iconFontFamily: "IosevkaTermSlab Nerd Font Mono"
            iconFontWeight: Font.Normal
            iconFontSize: 24
            centerIconInk: true
            iconColor: usageButton.iconColor
        }
        Text {
            x: 64
            text: root.usageLabel
            color: usageButton.labelColor
            font.family: Theme.barFontFamily
            font.pixelSize: 42
            font.features: { "tnum": 1 }
        }
        Text {
            x: 64
            y: 58
            text: root.usageReset.length > 0 ? "Resets in " + root.usageReset : root.loading ? "Updating…" : root.ready ? "No limit reported" : "Unavailable"
            color: Theme.textSecondary
            font.family: Theme.barFontFamily
            font.pixelSize: 14
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) root.refreshAction();
                else Popups.toggle(usagePopup);
            }
        }
    }

    MenuPopup {
        id: usagePopup

        anchorWindow: root.anchorWindow
        anchorItem: root.expanded ? expandedUsage : usageButton
        menuWidth: 360

        Row {
            width: parent.width
            height: 30
            spacing: 8

            Text {
                width: parent.width - refreshButton.width - parent.spacing
                height: parent.height
                text: root.plan.length > 0 ? root.providerName + " · " + root.plan : root.providerName
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 16
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
            visible: !root.ready || root.loading
            text: root.loading ? "Checking usage…" : root.errorText
            color: root.loading ? Theme.textMuted : Theme.danger
            font.family: Theme.fontFamily
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        UsageRow {
            title: "Weekly"
            visible: root.ready && root.weeklyPercentLeft >= 0
            percentLeft: root.weeklyPercentLeft
            pace: root.weeklyPace
            reset: root.weeklyReset
        }

        UsageRow {
            title: "Monthly"
            visible: root.ready && root.monthlyPercentLeft >= 0
            percentLeft: root.monthlyPercentLeft
            reset: root.monthlyReset
        }

        Text {
            width: parent.width
            visible: root.ready && root.weeklyPercentLeft < 0 && root.monthlyPercentLeft < 0
            text: "No usage limits reported"
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.track
        }

        Row {
            width: parent.width
            height: 24
            visible: root.ready && root.footerVisible

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

        Text {
            width: parent.width
            text: root.updatedAt.length > 0
                ? "Last updated " + root.updatedAgoText(root.updateAgeSeconds)
                : "No successful update yet"
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: 10
            topPadding: 4
            bottomPadding: 2
        }
    }

    component UsageRow: Item {
        required property string title
        required property int percentLeft
        property string reset: ""
        property string pace: ""

        width: parent.width
        height: details.implicitHeight + 16

        readonly property int remaining: percentLeft >= 0 ? percentLeft : 0

        Column {
            id: details
            y: 8
            width: parent.width
            spacing: 8

            Row {
                width: parent.width
                height: 24

                Text {
                    width: parent.width * 0.5
                    height: parent.height
                    text: title
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    width: parent.width * 0.5
                    height: parent.height
                    text: Status.usagePercentText(percentLeft)
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Rectangle {
                width: parent.width
                height: 5
                radius: 2.5
                color: Theme.track

                Rectangle {
                    width: parent.width * remaining / 100
                    height: parent.height
                    radius: 2.5
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
                visible: reset.length > 0
                text: "Resets in " + reset
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 11
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
