pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property var records: []
    property alias quiet: session.quiet
    readonly property var received: JSON.parse(session.receivedJson)
    readonly property var history: records.filter(record => !record.notification.transient)
    readonly property var popups: records.filter(record => record.popup).slice(0, 3)

    // Memory only: private notification contents are never written to disk.
    PersistentProperties {
        id: session
        property bool quiet: false
        // Persist JSON, not a JS object tied to the previous QML engine.
        property string receivedJson: "{}"
    }

    onQuietChanged: if (quiet) hidePopups()

    Connections {
        target: Quickshell
        function onReloadCompleted() {
            root.records = root.records.slice().sort((a, b) => b.receivedAt - a.receivedAt);
        }
    }

    function hidePopups() {
        for (const record of records.slice()) record.hide();
    }

    function clear() {
        for (const record of records.slice()) record.notification.dismiss();
    }

    function refresh() { records = records.slice(); }

    function present(record) {
        const dates = Object.assign({}, received);
        dates[record.notification.id] = Date.now();
        session.receivedJson = JSON.stringify(dates);
        record.popup = !quiet;
        record.restartTimeout();
        records = [record].concat(records.filter(other => other !== record));
        while (records.length > 100) records[records.length - 1].notification.dismiss();
    }

    function remove(record) {
        records = records.filter(other => other !== record);
        const dates = Object.assign({}, received);
        delete dates[record.notification.id];
        session.receivedJson = JSON.stringify(dates);
        record.destroy();
    }

    NotificationServer {
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        actionsSupported: true
        actionIconsSupported: false
        imageSupported: true
        inlineReplySupported: false

        onNotification: notification => {
            if (notification.lastGeneration && notification.transient) return;
            notification.tracked = true;
            const record = entry.createObject(root, {notification});
            if (notification.lastGeneration) {
                root.records = root.records.concat([record]);
            } else {
                root.present(record);
            }
        }
    }

    Component {
        id: entry
        QtObject {
            id: record
            required property var notification
            property bool popup: false
            property bool hovered: false
            readonly property double receivedAt: root.received[notification.id] || Date.now()
            onPopupChanged: root.refresh()

            function hide() {
                popup = false;
                timeout.stop();
                if (notification.transient) notification.expire();
            }

            function restartTimeout() {
                timeout.stop();
                // Expiration controls the toast. Persistent notifications stay
                // actionable in history until dismissed by the user or app.
                if (notification.expireTimeout !== 0 && notification.urgency !== NotificationUrgency.Critical)
                    timeout.restart();
            }

            property Timer timeout: Timer {
                interval: record.notification.expireTimeout > 0 ? record.notification.expireTimeout : 7000
                onTriggered: record.hide()
            }
            onHoveredChanged: {
                if (hovered) timeout.stop();
                else if (popup) restartTimeout();
            }

            // Quickshell updates the existing object for a replacement; it
            // does not emit NotificationServer.notification a second time.
            property Timer replacement: Timer {
                interval: 0
                onTriggered: root.present(record)
            }
            property Connections changes: Connections {
                target: record.notification
                function onSummaryChanged() { replacement.restart(); }
                function onBodyChanged() { replacement.restart(); }
                function onAppNameChanged() { replacement.restart(); }
                function onAppIconChanged() { replacement.restart(); }
                function onImageChanged() { replacement.restart(); }
                function onActionsChanged() { replacement.restart(); }
                function onHintsChanged() { replacement.restart(); }
                function onExpireTimeoutChanged() { replacement.restart(); }
                function onUrgencyChanged() { replacement.restart(); }
                function onTransientChanged() { replacement.restart(); }
                function onClosed(reason) { root.remove(record); }
            }
        }
    }
}
