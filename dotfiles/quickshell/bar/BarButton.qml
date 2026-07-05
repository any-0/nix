import QtQuick

Item {
    id: root

    property string icon: ""
    property string label: ""
    property color iconColor: danger ? Theme.danger : muted ? Theme.textMuted : Theme.text
    property color labelColor: danger ? Theme.danger : muted ? Theme.textMuted : Theme.text
    property bool danger: false
    property bool muted: false
    property bool hoverDanger: false
    property int fontSize: Theme.fontSize
    property int iconYOffset: 0
    property int labelYOffset: 0
    property string iconFontFamily: Theme.fontFamily
    property string labelFontFamily: Theme.fontFamily
    readonly property bool hovered: mouse.containsMouse
    signal clicked(int button)
    signal wheel(int delta)

    implicitWidth: Math.max(24, content.implicitWidth + 16)
    implicitHeight: 30
    height: 30

    Rectangle {
        id: highlight

        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 24
        radius: 8
        color: mouse.pressed ? Theme.pressed : mouse.containsMouse ? Theme.hover : Theme.transparent

        Behavior on color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        Row {
            id: content

            anchors.centerIn: parent
            spacing: root.icon.length > 0 && root.label.length > 0 ? 6 : 0

            Text {
                visible: root.icon.length > 0
                height: highlight.height
                text: root.icon
                color: root.hoverDanger && mouse.containsMouse ? Theme.danger : root.iconColor
                font.family: root.iconFontFamily
                font.pixelSize: root.fontSize
                font.weight: Font.DemiBold
                verticalAlignment: Text.AlignVCenter
                y: root.iconYOffset

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Text {
                visible: root.label.length > 0
                height: highlight.height
                text: root.label
                color: root.hoverDanger && mouse.containsMouse ? Theme.danger : root.labelColor
                font.family: root.labelFontFamily
                font.pixelSize: root.fontSize
                font.weight: Font.DemiBold
                verticalAlignment: Text.AlignVCenter
                y: root.labelYOffset

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        onClicked: mouse => root.clicked(mouse.button)
        onWheel: wheel => {
            root.wheel(wheel.angleDelta.y);
            wheel.accepted = true;
        }
    }
}
