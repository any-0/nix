pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var sample: null
    property real cpuUsage: -1
    property real cpuPower: -1

    function update(data) {
        if (sample !== null) {
            const total = data.cpuTotal - sample.cpuTotal;
            cpuUsage = total > 0 ? 100 * (1 - (data.cpuIdle - sample.cpuIdle) / total) : -1;
            if (data.energy !== null && sample.energy !== null && data.time > sample.time) {
                let delta = data.energy - sample.energy;
                if (delta < 0)
                    delta += data.energyRange;
                cpuPower = delta / 1000000 / (data.time - sample.time);
            } else {
                cpuPower = -1;
            }
        }
        sample = data;
    }

    Process {
        running: true
        command: ["bash", Quickshell.env("HOME") + "/nix/scripts/internal/hardware-status"]
        stdout: SplitParser {
            onRead: line => root.update(JSON.parse(line))
        }
        onExited: {
            root.sample = null;
            root.cpuUsage = -1;
            root.cpuPower = -1;
        }
    }
}
