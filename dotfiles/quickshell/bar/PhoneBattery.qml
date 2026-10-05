pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var phones: []

    Process {
        id: poll
        command: ["bash", Quickshell.env("HOME") + "/nix/scripts/internal/phone-battery"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.phones = JSON.parse(text);
                } catch (error) {
                    root.phones = [];
                }
            }
        }
        onExited: (code, status) => {
            if (code !== 0) root.phones = [];
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!poll.running) poll.running = true
    }
}
