import QtQuick

Item {
    id: root

    property string icon: ""
    property string label: ""
    // When true the icon/label still reserves its layout slot but is not
    // drawn — the desktop overlay renders it on top so it can fly away.
    property bool iconGhost: false
    property bool labelGhost: false
    // Glyph/label centers relative to this button, for the overlay.
    readonly property real iconCenterX: highlight.x + content.x + iconText.x + iconText.implicitWidth / 2
    readonly property real labelCenterX: highlight.x + content.x + labelText.x + labelText.implicitWidth / 2
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
                id: iconText

                visible: root.icon.length > 0
                opacity: root.iconGhost ? 0 : 1
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
                id: labelText

                visible: root.label.length > 0
                opacity: root.labelGhost ? 0 : 1
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
