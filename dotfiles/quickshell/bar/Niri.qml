pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: niri

    property var workspaces: []
    property var windows: []
    signal interaction()

    function workspaceDisplayName(workspace) {
        return workspace.name || String(workspace.idx);
    }

    function workspaceFocusReference(workspace) {
        const name = workspace.name || "";
        return name.trim() !== "" && isNaN(Number(name)) ? name : String(workspace.idx);
    }

    function shouldShowWorkspace(workspace) {
        return workspace.is_active || workspace.is_focused || workspace.is_urgent || workspace.active_window_id !== null;
    }

    function workspacesForScreen(screenName) {
        return niri.workspaces
            .filter(workspace => workspace.output === screenName && shouldShowWorkspace(workspace))
            .sort((a, b) => a.idx - b.idx);
    }

    function windowsForWorkspace(workspaceId) {
        return niri.windows
            .filter(window => window.workspace_id === workspaceId)
            .sort((a, b) => {
                const apos = windowPosition(a);
                const bpos = windowPosition(b);
                if (!!a.is_floating !== !!b.is_floating) return a.is_floating ? 1 : -1;
                if (apos[0] !== bpos[0]) return apos[0] - bpos[0];
                if (apos[1] !== bpos[1]) return apos[1] - bpos[1];
                return a.id - b.id;
            });
    }

    function windowPosition(window) {
        return window.layout && window.layout.pos_in_scrolling_layout ? window.layout.pos_in_scrolling_layout : [999999, 999999];
    }

    function workspaceIconViews(workspace) {
        const sourceWindows = windowsForWorkspace(workspace.id);
        const icons = sourceWindows.slice(0, 4).map(window => ({
            "windowId": window.id,
            "appId": window.app_id || "",
            "source": iconSource(window.app_id || ""),
            "fallback": iconFallback(window.app_id || ""),
            "selected": workspace.active_window_id === window.id
        }));
        return {
            "icons": icons,
            "hiddenCount": Math.max(0, sourceWindows.length - icons.length)
        };
    }

    function normalizeAppId(appId) {
        return appId.trim().replace(/\.desktop$/i, "").toLowerCase();
    }

    function iconSource(appId) {
        const icon = desktopIconName(appId);
        if (icon === "") return "";
        if (icon[0] === "/") return fileUrl(icon);
        return fileUrl(Quickshell.iconPath(icon));
    }

    function fileUrl(path) {
        return path[0] === "/" ? "file://" + path : path;
    }

    function desktopIconName(appId) {
        const key = normalizeAppId(appId);
        if (key.indexOf("steam_app_") === 0) return "steam";

        const candidates = [appId, key, key + ".desktop", appId + ".desktop"];
        for (const candidate of candidates) {
            const entry = DesktopEntries.byId(candidate);
            if (entry && entry.icon) return entry.icon;
        }

        const heuristicEntry = DesktopEntries.heuristicLookup(appId) || DesktopEntries.heuristicLookup(key);
        return heuristicEntry && heuristicEntry.icon ? heuristicEntry.icon : "";
    }

    function iconFallback(appId) {
        const key = normalizeAppId(appId);
        if (key.length === 0) return "?";
        if (key.indexOf("steam_app_") === 0) return "S";
        return key[0].toUpperCase();
    }

    function workspacePalette(index) {
        const colors = ["#c10100", "#ff6705", "#fdb00b", "#029b3b", "#0088cc", "#5a37bb"];
        return colors[((index - 1) % colors.length + colors.length) % colors.length];
    }

    function focusWorkspace(workspace) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", workspaceFocusReference(workspace)]);
    }

    function focusWindow(windowId) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", String(windowId)]);
    }

    function handleLine(line) {
        if (line.trim() === "") return;

        let event = {};
        try {
            event = JSON.parse(line);
        } catch (error) {
            console.warn("failed to parse niri event:", error);
            return;
        }

        if (event.WorkspacesChanged) replaceWorkspaces(event.WorkspacesChanged.workspaces);
        if (event.WindowsChanged) replaceWindows(event.WindowsChanged.windows);
        if (event.WindowOpenedOrChanged) upsertWindow(event.WindowOpenedOrChanged.window);
        if (event.WindowClosed) removeWindow(event.WindowClosed.id);
        if (event.WorkspaceActivated) activateWorkspace(event.WorkspaceActivated.id, event.WorkspaceActivated.focused);
        if (event.WorkspaceActiveWindowChanged) setWorkspaceActiveWindow(event.WorkspaceActiveWindowChanged.workspace_id, event.WorkspaceActiveWindowChanged.active_window_id);
        if (event.WindowFocusChanged) setFocusedWindow(event.WindowFocusChanged.id);
        if (event.WorkspaceUrgencyChanged) setWorkspaceUrgency(event.WorkspaceUrgencyChanged.id, event.WorkspaceUrgencyChanged.urgent);
        if (event.WindowUrgencyChanged) setWindowUrgency(event.WindowUrgencyChanged.id, event.WindowUrgencyChanged.urgent);
        if (event.WindowLayoutsChanged) setWindowLayouts(event.WindowLayoutsChanged.changes);

        if (event.WorkspaceActivated || event.WorkspaceActiveWindowChanged || event.WindowFocusChanged) interaction();
    }

    function replaceWorkspaces(next) {
        niri.workspaces = Array.isArray(next) ? next : [];
    }

    function replaceWindows(next) {
        niri.windows = Array.isArray(next) ? next : [];
    }

    function upsertWindow(window) {
        if (!window) return;
        const next = niri.windows.slice();
        const index = next.findIndex(item => item.id === window.id);
        if (index === -1) next.push(window);
        else next[index] = Object.assign({}, next[index], window);
        niri.windows = next;
    }

    function removeWindow(windowId) {
        niri.windows = niri.windows.filter(window => window.id !== windowId);
        niri.workspaces = niri.workspaces.map(workspace => {
            if (workspace.active_window_id !== windowId) return workspace;
            return Object.assign({}, workspace, {"active_window_id": null});
        });
    }

    function activateWorkspace(workspaceId, focused) {
        const activated = niri.workspaces.find(workspace => workspace.id === workspaceId);
        niri.workspaces = niri.workspaces.map(workspace => {
            const active = activated && workspace.output === activated.output ? workspace.id === workspaceId : workspace.is_active;
            return Object.assign({}, workspace, {
                "is_active": active,
                "is_focused": focused ? workspace.id === workspaceId : false
            });
        });
    }

    function setWorkspaceActiveWindow(workspaceId, windowId) {
        niri.workspaces = niri.workspaces.map(workspace => workspace.id === workspaceId
            ? Object.assign({}, workspace, {"active_window_id": windowId})
            : workspace);
    }

    function setFocusedWindow(windowId) {
        niri.windows = niri.windows.map(window => Object.assign({}, window, {"is_focused": window.id === windowId}));
    }

    function setWorkspaceUrgency(workspaceId, urgent) {
        niri.workspaces = niri.workspaces.map(workspace => workspace.id === workspaceId
            ? Object.assign({}, workspace, {"is_urgent": urgent})
            : workspace);
    }

    function setWindowUrgency(windowId, urgent) {
        niri.windows = niri.windows.map(window => window.id === windowId
            ? Object.assign({}, window, {"is_urgent": urgent})
            : window);
    }

    function setWindowLayouts(changes) {
        if (!Array.isArray(changes)) return;

        const byId = {};
        for (const change of changes) {
            if (Array.isArray(change) && change.length >= 2) byId[change[0]] = change[1];
        }

        niri.windows = niri.windows.map(window => Object.prototype.hasOwnProperty.call(byId, window.id)
            ? Object.assign({}, window, {"layout": byId[window.id]})
            : window);
    }

    Timer {
        id: restartTimer
        interval: 2000
        repeat: false
        onTriggered: niriEvents.running = true
    }

    Process {
        id: niriEvents
        running: true
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => niri.handleLine(line)
        }
        onExited: restartTimer.restart()
    }
}
