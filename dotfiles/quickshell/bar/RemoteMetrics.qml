pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    property Host proxmox: Host {
        address: "root@192.168.0.111"
    }
    property Host mac: Host { address: "julian@192.168.0.204" }

    component Host: QtObject {
        id: host
        required property string address
        property bool enabled: true
        property var sample: null
        property string status: enabled ? "Connecting…" : "SSH setup needed"
        property double updatedAt: 0
        property string failure: ""

        property Process poll: Process {
            command: ["bash", Quickshell.env("HOME") + "/nix/scripts/internal/remote-hardware-status", host.address]
            stdout: SplitParser {
                onRead: line => {
                    host.sample = JSON.parse(line);
                    host.updatedAt = Date.now();
                    host.status = "";
                }
            }
            stderr: StdioCollector {
                onStreamFinished: host.failure = text
            }
            onExited: (code, status) => {
                if (code !== 0) {
                    host.sample = null;
                    host.status = host.failure.includes("Permission denied") ? "SSH access needed" : "Offline";
                }
            }
        }

        property Timer refresh: Timer {
            interval: 10000
            running: host.enabled
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                if (!host.poll.running) {
                    host.failure = "";
                    host.poll.running = true;
                }
                if (host.updatedAt > 0 && Date.now() - host.updatedAt > 30000) {
                    host.sample = null;
                    host.status = "Offline";
                }
            }
        }
    }
}
