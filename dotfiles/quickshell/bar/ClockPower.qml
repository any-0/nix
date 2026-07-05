import QtQuick
import Quickshell

Rectangle {
    id: pill

    required property var anchorWindow

    height: 30
    radius: 15
    color: Theme.surface
    border.color: Theme.surfaceBorder
    border.width: 1
    width: clockRow.implicitWidth + 20

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Row {
        id: clockRow
        anchors.centerIn: parent
        spacing: 8

        Item {
            id: clockArea
            implicitWidth: clockTexts.implicitWidth
            implicitHeight: clockTexts.implicitHeight

            Row {
                id: clockTexts
                spacing: 8

                ModuleText {
                    text: Qt.formatDateTime(clock.date, "yyyy-MM-dd")
                }

                ModuleText {
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: calendarPopup.visible = !calendarPopup.visible
            }
        }

        ModuleText {
            id: powerButton

            width: 18
            horizontalAlignment: Text.AlignHCenter
            text: "⏻"
            font.family: "IosevkaTermSlab Nerd Font Mono"
            font.weight: Font.Normal
            muted: !powerMouse.containsMouse
            danger: powerMouse.containsMouse

            MouseArea {
                id: powerMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: powerPopup.visible = !powerPopup.visible
            }
        }
    }

    PopupWindow {
        id: calendarPopup

        visible: false
        color: "transparent"
        implicitWidth: 248
        implicitHeight: 252
        anchor.window: pill.anchorWindow
        anchor.rect.x: pill.anchorWindow.width - implicitWidth - 50
        anchor.rect.y: pill.y + pill.height + 5

        Rectangle {
            id: calendar

            property date displayedMonth: new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)

            anchors.fill: parent
            color: Theme.surface
            border.color: Theme.surfaceBorder
            border.width: 1
            radius: 12

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
                anchors.margins: 10
                spacing: 8

                Row {
                    width: parent.width
                    height: 24

                    CalendarNavButton {
                        text: "<"
                        onClicked: calendar.shiftMonth(-1)
                    }

                    Text {
                        text: Qt.formatDate(calendar.displayedMonth, "MMMM yyyy")
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        width: parent.width - 48
                        height: 24
                    }

                    CalendarNavButton {
                        text: ">"
                        onClicked: calendar.shiftMonth(1)
                    }
                }

                Grid {
                    columns: 7
                    rowSpacing: 4
                    columnSpacing: 4

                    Repeater {
                        model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                        delegate: Text {
                            required property string modelData

                            width: 28
                            height: 18
                            text: modelData
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Repeater {
                        model: 42
                        delegate: Rectangle {
                            required property int index
                            property int day: calendar.dayForCell(index)

                            width: 28
                            height: 28
                            radius: 10
                            color: calendar.isToday(day) ? "#24ffffff" : "transparent"
                            border.width: calendar.isToday(day) ? 1 : 0
                            border.color: "#38ffffff"

                            Text {
                                anchors.centerIn: parent
                                text: day > 0 ? String(day) : ""
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.weight: calendar.isToday(day) ? Font.Bold : Font.DemiBold
                            }
                        }
                    }
                }
            }
        }
    }

    PopupWindow {
        id: powerPopup

        visible: false
        color: "transparent"
        implicitWidth: 132
        implicitHeight: powerMenuColumn.implicitHeight + 12
        grabFocus: true
        anchor.window: pill.anchorWindow
        anchor.rect.x: pill.anchorWindow.width - implicitWidth - 13
        anchor.rect.y: pill.y + pill.height + 5

        Rectangle {
            anchors.fill: parent
            color: Theme.surface
            border.color: Theme.surfaceBorder
            border.width: 1
            radius: 12

            Column {
                id: powerMenuColumn
                anchors.fill: parent
                anchors.margins: 6
                spacing: 2

                PowerMenuRow {
                    label: "Shutdown"
                    command: ["systemctl", "poweroff"]
                }

                PowerMenuRow {
                    label: "Reboot"
                    command: ["systemctl", "reboot"]
                }

                PowerMenuRow {
                    label: "Suspend"
                    command: ["systemctl", "suspend"]
                }
            }
        }
    }

    component ModuleText: Text {
        property bool danger: false
        property bool muted: false

        color: danger ? Theme.danger : muted ? Theme.textMuted : Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 14
        font.weight: Font.DemiBold
        verticalAlignment: Text.AlignVCenter
        height: 20
    }

    component CalendarNavButton: Rectangle {
        signal clicked()
        property alias text: label.text

        width: 24
        height: 24
        radius: 10
        color: navMouse.containsMouse ? "#29ffffff" : "#14ffffff"

        Text {
            id: label
            anchors.centerIn: parent
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.Bold
        }

        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.clicked()
        }
    }

    component PowerMenuRow: Rectangle {
        required property string label
        required property var command

        width: parent.width
        height: 28
        radius: 8
        color: menuMouse.containsMouse ? Theme.surfaceHover : "transparent"

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 10
            text: label
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: menuMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                powerPopup.visible = false;
                Quickshell.execDetached(command);
            }
        }
    }
}
