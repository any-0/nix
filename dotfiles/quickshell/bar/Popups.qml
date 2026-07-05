pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: popups

    property var openPopup: null
    property real openedAt: 0

    function toggle(popup) {
        if (openPopup === popup && popup.visible) {
            close(popup);
            return;
        }

        open(popup);
    }

    function open(popup) {
        if (openPopup && openPopup !== popup) openPopup.visible = false;
        openPopup = popup;
        openedAt = Date.now();
        popup.visible = true;
    }

    function close(popup) {
        popup.visible = false;
        if (openPopup === popup) openPopup = null;
    }

    function closeOpenPopup() {
        if (openPopup) close(openPopup);
    }

    function closeOpenPopupFromInteraction() {
        if (!openPopup || !openPopup.visible) return;
        if (Date.now() - openedAt < 150) return;
        closeOpenPopup();
    }

    function noteVisibleChange(popup) {
        if (popup.visible) {
            if (openPopup && openPopup !== popup) openPopup.visible = false;
            openPopup = popup;
            openedAt = Date.now();
        } else if (openPopup === popup) {
            openPopup = null;
        }
    }
}
