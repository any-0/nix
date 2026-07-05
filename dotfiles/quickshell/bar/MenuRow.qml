import QtQuick

Rectangle {
    id: row

    required property string label
    property string icon: ""
    property string trailing: ""
    property bool active: false
    property bool danger: false
    property bool muted: false
    property bool trailingMuted: false
    property bool hoverDanger: false
    property bool dangerTint: false
    property bool clickable: true
    signal clicked()

    width: parent.width
    height: 32
    radius: 8
    color: row.clickable && rowMouse.pressed ? (dangerTint ? Theme.dangerPressed : Theme.pressed) : row.clickable && dangerTint ? Theme.dangerHover : row.clickable && rowMouse.containsMouse ? Theme.hover : Theme.transparent

    Behavior on color {
        ColorAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.right: trailingLabel.visible ? trailingLabel.left : parent.right
        anchors.rightMargin: trailingLabel.visible ? 8 : 8
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        spacing: 8

        Rectangle {
            width: 6
            height: 6
            radius: 3
            anchors.verticalCenter: parent.verticalCenter
            visible: row.active
            color: Theme.accent
        }

        Text {
            visible: row.icon.length > 0
            width: 16
            height: parent.height
            text: row.icon
            color: row.hoverDanger && rowMouse.containsMouse ? Theme.danger : row.danger ? Theme.danger : row.muted ? Theme.textMuted : Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            Behavior on color {
                ColorAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
        }

        Text {
            width: parent.width - x
            height: parent.height
            text: row.label
            color: row.hoverDanger && rowMouse.containsMouse ? Theme.danger : row.danger ? Theme.danger : row.muted ? Theme.textMuted : Theme.text
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.weight: Font.DemiBold
            verticalAlignment: Text.AlignVCenter

            Behavior on color {
                ColorAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    Text {
        id: trailingLabel

        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        visible: row.trailing.length > 0
        height: parent.height
        text: row.trailing
        color: row.trailingMuted || row.muted ? Theme.textMuted : Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 12
        font.weight: Font.DemiBold
        verticalAlignment: Text.AlignVCenter
    }

    MouseArea {
        id: rowMouse

        anchors.fill: parent
        enabled: row.clickable
        hoverEnabled: row.clickable
        onClicked: row.clicked()
    }
}
