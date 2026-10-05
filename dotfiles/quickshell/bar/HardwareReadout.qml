import QtQuick

Item {
    id: root

    required property string hostName
    property var sample: null
    property real cpuUsage: -1
    property real cpuPower: -1
    implicitWidth: content.implicitWidth
    implicitHeight: 30
    height: 30

    function value(number, suffix) {
        if (number === null || number < 0) return "—";
        if (suffix === "W" && number > 0 && number < 10)
            return number.toFixed(number < 1 ? 2 : 1) + suffix;
        return Math.round(number) + suffix;
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 9

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: 23
            text: root.hostName
            color: root.sample ? Theme.accent : Theme.textMuted
            font.family: Theme.barFontFamily
            font.pixelSize: 10
            font.weight: Font.Medium
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            SensorRow {
                usage: root.cpuUsage
                temperature: root.sample ? root.sample.cpuTemp : null
                power: root.cpuPower
            }
            SensorRow {
                usage: root.sample ? root.sample.gpuUsage : null
                temperature: root.sample ? root.sample.gpuTemp : null
                power: root.sample ? root.sample.gpuPower : null
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            MetricText {
                width: 39
                text: root.sample ? root.sample.ramUsed.toFixed(1) + "G" : "—"
            }
            MetricText {
                width: 39
                text: root.sample ? root.sample.ramTotal.toFixed(1) + "G" : "—"
                color: Theme.textMuted
            }
        }
    }

    component SensorRow: Row {
        required property var usage
        required property var temperature
        required property var power
        spacing: 7
        height: 12

        MetricText {
            width: 26
            text: root.value(usage, "%")
        }
        MetricText {
            width: 23
            text: root.value(temperature, "°")
            color: Theme.textSecondary
        }
        MetricText {
            width: 35
            text: root.value(power, "W")
            color: Theme.textSecondary
        }
    }

    component MetricText: Text {
        height: 12
        color: Theme.text
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        font.family: Theme.barFontFamily
        font.features: { "tnum": 1 }
        font.pixelSize: 10
        font.weight: Font.Medium
    }
}
