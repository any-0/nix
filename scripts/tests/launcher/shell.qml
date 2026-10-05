import Quickshell
import Quickshell.Io

ShellRoot {
    property var workspaces: Niri.workspaces
    Launcher { id: launcher }
    IpcHandler {
        target: "test"
        function state(): string {
            return JSON.stringify({open: launcher.opened, results: launcher.results.map(entry => entry.id)});
        }
    }
}
