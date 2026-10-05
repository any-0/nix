# Launcher tests

`tst_search.qml` runs with Qt's `qmltestrunner` in Docker using
`QT_QPA_PLATFORM=offscreen`, `QT_QUICK_BACKEND=software`, and the Qt QML import path.
Mount the repository read-only at `/repo` and the Nix store read-only at `/nix`.

`integration.sh` runs inside Docker under a private `dbus-run-session` with the
patched Niri, Quickshell, wtype, grim, Kitty, and jq on PATH. Mount an artifact
directory at `/artifacts`, the graphics drivers at `/run/opengl-driver`, and
fonts at `/etc/fonts`; expose only the GPU render node, never input devices or
host runtime sockets. It creates its own Wayland display and config in `/tmp`.

The integration tests exercise the shortcut's command, real text/arrow/Enter/
Escape input, app launching (including terminal entries), no-match behavior,
toggle/close, and portrait-region placement. Screenshots and logs are saved in
the artifact directory. Virtual keyboard events bypass Niri's global shortcut
handling, so the shortcut command is invoked through Niri's spawn action.
