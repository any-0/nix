import QtQuick
import Quickshell

Item {
    id: root

    required property var anchorWindow
    property bool showClock: true
    property bool showPower: true
    property bool expandedUsage: false
    property var calendarAnchor: clockButton
    property var powerAnchor: powerButton
    function toggleCalendar() { Popups.toggle(calendarPopup); }
    function togglePower() { Popups.toggle(powerPopup); }
    property bool desktopClockVisible: false
    property bool desktopClockActive: false
    // Width of the clock text block, provided by DesktopClock (which owns and
    // renders the actual text; the bar only reserves this slot).
    property real clockSlotWidth: 0
    // Distance from this item's right edge to the clock slot's resting center.
    readonly property real clockCenterOffsetFromRight: powerButton.width + clockRow.spacing + clockButton.implicitWidth / 2

    implicitWidth: clockRow.implicitWidth
    implicitHeight: clockRow.implicitHeight
    width: implicitWidth
    height: implicitHeight

    onDesktopClockVisibleChanged: {
        if (desktopClockVisible) {
            Popups.close(calendarPopup);
            desktopClockDelay.restart();
        } else {
            desktopClockDelay.stop();
            desktopClockActive = false;
        }
    }

    Timer {
        id: desktopClockDelay

        interval: 5000
        onTriggered: root.desktopClockActive = root.desktopClockVisible
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Row {
        id: clockRow

        anchors.centerIn: parent
        spacing: 10

        UsageStatus {
            expanded: root.expandedUsage
            anchorWindow: root.anchorWindow
            providerName: "Codex"
            providerIcon: "\uE015\uE016\uE017"
            usageLabel: Status.codexLabel
            usageReset: Status.codexLabelReset
            ready: Status.codexReady
            loading: Status.codexLoading
            errorText: Status.codexError
            plan: Status.codexPlan
            updatedAt: Status.codexUpdatedAt
            weeklyPercentLeft: Status.codexWeeklyPercentLeft
            weeklyPace: Status.usagePaceText(
                Status.codexWeeklyUsedPercent,
                Status.codexWeeklyResetAt,
                Status.codexWeeklyWindowSeconds)
            weeklyReset: Status.codexWeeklyReset
            monthlyPercentLeft: Status.codexMonthlyPercentLeft
            monthlyReset: Status.codexMonthlyReset
            footerVisible: Status.codexCredits >= 0 || Status.codexResetCredits >= 0
            footerLabel: Status.codexResetCredits >= 0 ? "Usage resets" : "Credits"
            footerValue: Status.codexResetCredits >= 0 ? String(Status.codexResetCredits) : Status.codexCreditsText()
            refreshAction: function() { Status.refreshCodexUsage(); }
        }

        Item {
            id: clockSlot
            visible: root.showClock

            width: root.desktopClockActive ? 0 : clockButton.implicitWidth
            height: 30
            clip: true

            Behavior on width {
                NumberAnimation {
                    duration: root.desktopClockActive ? 900 : 450
                    easing.type: Easing.OutCubic
                }
            }

            // Invisible placeholder: DesktopClock renders the text on its
            // overlay exactly over this slot; this only provides the hover
            // highlight and the click target for the calendar.
            BarButton {
                id: clockButton

                implicitWidth: root.clockSlotWidth + 16
                enabled: !root.desktopClockActive
                onClicked: Popups.toggle(calendarPopup)
            }
        }

        BarButton {
            id: powerButton
            visible: root.showPower

            icon: "⏻"
            iconColor: Theme.textMuted
            iconFontSize: 14
            iconYOffset: -1
            hoverDanger: true
            onClicked: Popups.toggle(powerPopup)
        }
    }

    MenuPopup {
        id: calendarPopup

        anchorWindow: root.anchorWindow
        anchorItem: root.calendarAnchor
        menuWidth: 260

        Item {
            id: calendar

            property date displayedMonth: new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)

            width: parent.width
            height: 230

            function shiftMonth(delta) {
                displayedMonth = new Date(displayedMonth.getFullYear(), displayedMonth.getMonth() + delta, 1);
            }

            function daysInMonth(year, month) {
                return new Date(year, month + 1, 0).getDate();
            }

            function leadingDays() {
                const day = new Date(displayedMonth.getFullYear(), displayedMonth.getMonth(), 1).getDay();
                return (day + 6) % 7;
            }

            function dayForCell(index) {
                const day = index - leadingDays() + 1;
                const count = daysInMonth(displayedMonth.getFullYear(), displayedMonth.getMonth());
                return day >= 1 && day <= count ? day : 0;
            }

            function isToday(day) {
                const today = new Date();
                return day > 0
                    && displayedMonth.getFullYear() === today.getFullYear()
                    && displayedMonth.getMonth() === today.getMonth()
                    && day === today.getDate();
            }

            Column {
                anchors.fill: parent
                spacing: 8

                Row {
                    width: parent.width
                    height: 28

                    CalendarNavButton {
                        text: "‹"
                        onClicked: calendar.shiftMonth(-1)
                    }

                    Text {
                        text: Qt.formatDate(calendar.displayedMonth, "MMMM yyyy")
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        width: parent.width - 56
                        height: 28
                    }

                    CalendarNavButton {
                        text: "›"
                        onClicked: calendar.shiftMonth(1)
                    }
                }

                Grid {
                    id: calendarGrid

                    width: parent.width
                    columns: 7
                    rowSpacing: 4
                    columnSpacing: 4

                    Repeater {
                        model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

                        delegate: Text {
                            required property string modelData

                            width: (calendarGrid.width - calendarGrid.columnSpacing * 6) / 7
                            height: 18
                            text: modelData
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Repeater {
                        model: 42

                        delegate: Rectangle {
                            required property int index
                            property int day: calendar.dayForCell(index)

                            width: (calendarGrid.width - calendarGrid.columnSpacing * 6) / 7
                            height: 24
                            radius: 12
                            color: calendar.isToday(day) ? Theme.accent : Theme.transparent

                            Text {
                                anchors.centerIn: parent
                                text: day > 0 ? String(day) : ""
                                color: calendar.isToday(day) ? Theme.white : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }
            }
        }
    }

    MenuPopup {
        id: powerPopup

        menuWidth: 260
        anchorWindow: root.anchorWindow
        anchorItem: root.powerAnchor

        property string pendingAction: ""

        function requestPowerAction(action) {
            if (pendingAction === action) {
                Popups.close(powerPopup);
                Quickshell.execDetached(["systemctl", action === "shutdown" ? "poweroff" : "reboot"]);
                return;
            }

            pendingAction = action;
            confirmTimer.restart();
        }

        onVisibleChanged: {
            pendingAction = "";
            confirmTimer.stop();
        }

        Timer {
            id: confirmTimer

            interval: 3000
            repeat: false
            onTriggered: powerPopup.pendingAction = ""
        }

        MenuRow {
            icon: "⏻"
            label: powerPopup.pendingAction === "shutdown" ? "Confirm shutdown?" : "Shut down"
            danger: powerPopup.pendingAction === "shutdown"
            dangerTint: powerPopup.pendingAction === "shutdown"
            hoverDanger: powerPopup.pendingAction !== "shutdown"
            onClicked: powerPopup.requestPowerAction("shutdown")
        }

        MenuRow {
            icon: "󰜉"
            label: powerPopup.pendingAction === "reboot" ? "Confirm reboot?" : "Reboot"
            danger: powerPopup.pendingAction === "reboot"
            dangerTint: powerPopup.pendingAction === "reboot"
            hoverDanger: powerPopup.pendingAction !== "reboot"
            onClicked: powerPopup.requestPowerAction("reboot")
        }

        MenuRow {
            icon: "󰤄"
            label: "Suspend"
            onClicked: {
                Popups.close(powerPopup);
                Quickshell.execDetached(["systemctl", "suspend"]);
            }
        }
    }

    component CalendarNavButton: Rectangle {
        signal clicked()
        property alias text: label.text

        width: 28
        height: 28
        radius: 8
        color: navMouse.pressed ? Theme.pressed : navMouse.containsMouse ? Theme.hover : Theme.transparent

        Behavior on color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Text {
            id: label

            anchors.centerIn: parent
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 16
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: navMouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.clicked()
        }
    }
}
