import QtQuick

Rectangle {
    id: root

    property bool checked: false
    signal toggled()

    width: 34
    height: 18
    radius: 9
    color: checked ? Theme.accent : Theme.trackMuted

    Behavior on color {
        ColorAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        width: 14
        height: 14
        radius: 7
        x: root.checked ? root.width - width - 2 : 2
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.white

        Behavior on x {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.toggled()
    }
}
