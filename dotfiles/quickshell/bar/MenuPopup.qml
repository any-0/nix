import QtQuick
import Quickshell
import Quickshell.Wayland._BackgroundEffect

PopupWindow {
    id: popup

    // Blur region shaped like the card: square top, straight edges exactly on
    // the card bounds (axis-aligned edges don't alias), and radius-14 bottom
    // corners as ellipse quarters inset 1px so their aliased curve hides under
    // the card's antialiased rim.
    readonly property int cornerRadius: 14
    readonly property int cornerInset: 1

    BackgroundEffect.blurRegion: Region {
        x: 0
        y: 0
        width: popup.width
        height: Math.max(0, popup.height - popup.cornerRadius)
        regions: [bottomBand, cornerLeft, cornerRight]
    }

    Region {
        id: bottomBand
        x: popup.cornerRadius
        y: 0
        width: Math.max(0, popup.width - popup.cornerRadius * 2)
        height: popup.height
    }

    Region {
        id: cornerLeft
        shape: RegionShape.Ellipse
        x: popup.cornerInset
        y: popup.height - popup.cornerRadius * 2 + popup.cornerInset
        width: (popup.cornerRadius - popup.cornerInset) * 2
        height: (popup.cornerRadius - popup.cornerInset) * 2
    }

    Region {
        id: cornerRight
        shape: RegionShape.Ellipse
        x: popup.width - popup.cornerRadius * 2 + popup.cornerInset
        y: popup.height - popup.cornerRadius * 2 + popup.cornerInset
        width: (popup.cornerRadius - popup.cornerInset) * 2
        height: (popup.cornerRadius - popup.cornerInset) * 2
    }

    required property var anchorWindow
    required property Item anchorItem
    property int menuWidth: 260
    default property alias content: contentColumn.data

    visible: false
    color: "transparent"
    implicitWidth: Math.max(260, menuWidth)
    implicitHeight: contentColumn.implicitHeight + 24
    // Map both corners when opening, including widgets scaled in the info panel.
    anchor.window: anchorWindow
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.Slide

    onVisibleChanged: {
        Popups.noteVisibleChange(popup);
        if (visible) {
            const topLeft = anchorItem.mapToItem(null, 0, 0);
            const bottomRight = anchorItem.mapToItem(null, anchorItem.width, anchorItem.height);
            anchor.rect.x = topLeft.x;
            anchor.rect.y = topLeft.y;
            anchor.rect.width = bottomRight.x - topLeft.x;
            anchor.rect.height = bottomRight.y - topLeft.y;
            anchor.updateAnchor();
            openAnimation.restart();
        }
    }

    ParallelAnimation {
        id: openAnimation

        NumberAnimation {
            target: cardRoot
            property: "opacity"
            from: 0
            to: 1
            duration: 150
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: slide
            property: "y"
            from: -6
            to: 0
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    Item {
        id: cardRoot

        anchors.fill: parent
        opacity: popup.visible ? 1 : 0

        transform: Translate {
            id: slide
            y: popup.visible ? 0 : -6
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.menuBg
            radius: popup.cornerRadius
            topLeftRadius: 0
            topRightRadius: 0

            Column {
                id: contentColumn

                anchors.fill: parent
                anchors.margins: 12
                spacing: 6
            }
        }
    }
}
