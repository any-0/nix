pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    property Disk pc: Disk { path: "/"; source: "/dev/nvme0n1p2" }
    property Disk media1: Disk { path: Quickshell.env("HOME") + "/storage/media1"; source: "//192.168.0.112/media1" }
    property Disk media2: Disk { path: Quickshell.env("HOME") + "/storage/media2"; source: "//192.168.0.112/media2" }
    property Disk backups: Disk { path: Quickshell.env("HOME") + "/storage/backups"; source: "//192.168.0.112/backups" }

    component Disk: QtObject {
        id: disk
        required property string path
        required property string source
        property var sample: null

        property Process poll: Process {
            command: ["timeout", "5", "bash", Quickshell.env("HOME") + "/nix/scripts/internal/storage-status", disk.path, disk.source]
            stdout: SplitParser {
                onRead: line => disk.sample = JSON.parse(line)
            }
            onExited: (code, status) => { if (code !== 0) disk.sample = null; }
        }

        property Timer refresh: Timer {
            interval: 60000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: { if (!disk.poll.running) disk.poll.running = true; }
        }
    }
}
