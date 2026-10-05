#!/usr/bin/env bash
set -euo pipefail

# Private compositor and D-Bus: never use the user's input or notification bus.
export XDG_RUNTIME_DIR=/tmp/notifications-runtime
export XDG_CONFIG_HOME=/tmp/notifications-config
export XDG_DATA_HOME=/tmp/notifications-data
export XDG_DATA_DIRS=/tmp/notifications-data
export NIRI_BACKEND=headless QT_QPA_PLATFORM=wayland QT_QUICK_BACKEND=software
mkdir -m 700 "$XDG_RUNTIME_DIR" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"
mkdir "$XDG_CONFIG_HOME/quickshell"
cp -r /repo/dotfiles/quickshell/bar "$XDG_CONFIG_HOME/quickshell/bar"
cp /repo/scripts/tests/notifications/shell.qml "$XDG_CONFIG_HOME/quickshell/bar/shell.qml"
niri --config /repo/scripts/tests/launcher/niri.kdl >/artifacts/niri.log 2>&1 &
compositor=$!
trap 'kill "$compositor"' EXIT
export WAYLAND_DISPLAY=wayland-1
export NIRI_SOCKET="$XDG_RUNTIME_DIR/niri.$WAYLAND_DISPLAY.$compositor.sock"
for _ in {1..50}; do
    [[ ! -S "$NIRI_SOCKET" ]] || break
    sleep 0.1
done
quickshell -c bar >/artifacts/quickshell.log 2>&1 &
ipc() { quickshell ipc -c bar call test "$@"; }
state() { ipc state; }
call() { busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.Notifications "$@"; }
send() {
    call Notify 'susssasa{sv}i' "$1" "$2" '' "$3" "$4" 2 default Open 0 "$5" | cut -d' ' -f2
}
for _ in {1..50}; do
    if state >/dev/null 2>&1; then break; fi
    sleep 0.1
done
sleep 0.3
call GetServerInformation | tee /artifacts/server.txt
call GetCapabilities | tee /artifacts/capabilities.txt
busctl --user monitor org.freedesktop.Notifications >/artifacts/signals.log 2>&1 &
monitor=$!

first=$(send Signal 0 'Alex · Pixel 8 Pro' 'Are we still on for dinner? I can be there around seven.' 10000)
second=$(send 'File manager' 0 'Transfer complete' 'Project archive copied to home2.' 10000)
sleep 0.2
state | jq -e '.history | length == 2'
grim -o TEST /artifacts/toasts.png
grim -o PORTRAIT /artifacts/history.png
ipc menu
state | jq -e '.menuOpen and (.popups | length == 0)'
sleep 0.2
grim -o TEST /artifacts/menu.png
ipc menu
state | jq -e '.menuOpen == false'

# Replacements update in place, with no duplicate history entries.
replaced=$(send Signal "$first" 'Alex · Pixel 8 Pro' 'Make that half past seven.' 10000)
test "$replaced" = "$first"
sleep 0.1
state | jq -e '.history | length == 2'
call CloseNotification u "$second"
state | jq -e '.history | length == 1'
ipc action "$first"
state | jq -e '.history | length == 0'

# Explicit millisecond timeout hides the toast, retaining actionable history.
short=$(send Desktop 0 Short 'Short-lived toast' 150)
sleep 0.3
state | jq -e '(.history | length == 1) and (.popups | length == 0)'
ipc dismiss "$short"
state | jq -e '.history | length == 0'

# Transient status messages must not accumulate in history.
call Notify 'susssasa{sv}i' Desktop 0 '' Transient Volume 0 1 transient b true 150
sleep 0.3
state | jq -e '(.history | length == 0) and (.popups | length == 0)'

# Quiet mode suppresses popups, not incoming history.
ipc quiet true
send Desktop 0 Quiet '<b>Shown as plain text</b>' 10000 >/dev/null
state | jq -e '.quiet and (.history | length == 1) and (.popups | length == 0)'
ipc quiet false
state | jq -e '.popups | length == 0'
ipc clear

# Critical notifications remain visible, even with a short timeout.
call Notify 'susssasa{sv}i' Desktop 0 '' Critical 'Battery low' 0 1 urgency y 2 100
sleep 0.3
state | jq -e '.popups | length == 1'
ipc clear

# Zero timeout is persistent; hide is not dismiss.
persistent=$(send Desktop 0 Persistent 'Remains until dismissed' 0)
sleep 0.2
state | jq -e '.popups | length == 1'
ipc hide
state | jq -e '(.history | length == 1) and (.popups | length == 0)'

# Reload retains notifications and original age, without replaying popups.
before=$(state | jq -r '.history[0].received')
ipc quiet true
ipc reload
sleep 0.6
state | jq -e --argjson before "$before" '.quiet and .history[0].received == $before and (.popups | length == 0)'
ipc dismiss "$persistent"
ipc clear
kill "$monitor"
rg -q ActionInvoked /artifacts/signals.log
rg -q NotificationClosed /artifacts/signals.log
if rg 'TypeError|ReferenceError|Error loading|Cannot assign|Binding loop' /artifacts/quickshell.log; then exit 1; fi
printf 'Notification integration tests passed\n'
