import QtQuick
import Quickshell

Item {
    id: root

    required property var anchorWindow
    property bool desktopClockVisible: false
    // Width of the clock text block, provided by DesktopClock (which owns and
    // renders the actual text; the bar only reserves this slot).
    property real clockSlotWidth: 0
    // Distance from this item's right edge to the clock slot's resting center.
    readonly property real clockCenterOffsetFromRight: powerButton.width + clockRow.spacing + clockButton.implicitWidth / 2

    implicitWidth: clockRow.implicitWidth
    implicitHeight: 30
    width: implicitWidth
    height: 30

    onDesktopClockVisibleChanged: {
        if (desktopClockVisible) Popups.close(calendarPopup);
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Row {
        id: clockRow

        anchors.centerIn: parent
        spacing: 4

        Item {
            id: clockSlot

            width: root.desktopClockVisible ? 0 : clockButton.implicitWidth
            height: 30
            clip: true

            Behavior on width {
                NumberAnimation {
                    duration: 450
                    easing.type: Easing.OutCubic
                }
            }

            // Invisible placeholder: DesktopClock renders the text on its
            // overlay exactly over this slot; this only provides the hover
            // highlight and the click target for the calendar.
            BarButton {
                id: clockButton

                implicitWidth: root.clockSlotWidth + 16
                enabled: !root.desktopClockVisible
                onClicked: Popups.toggle(calendarPopup)
            }
        }

        BarButton {
            id: powerButton

            icon: "⏻"
            iconColor: Theme.textMuted
            fontSize: 16
            iconYOffset: -1
            hoverDanger: true
            onClicked: Popups.toggle(powerPopup)
        }
    }

    MenuPopup {
        id: calendarPopup

        anchorWindow: root.anchorWindow
        anchorItem: clockButton
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
        anchorItem: powerButton

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
