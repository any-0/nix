import QtQuick

HardwareReadout {
    hostName: "PC"
    sample: LocalMetrics.sample
    cpuUsage: LocalMetrics.cpuUsage
    cpuPower: LocalMetrics.cpuPower
}
