#!/usr/bin/env bash
set -euo pipefail

# Run only inside the test container: no host Wayland, D-Bus, or input devices.
export XDG_RUNTIME_DIR=/tmp/launcher-runtime
export XDG_CONFIG_HOME=/tmp/launcher-config
export XDG_DATA_HOME=/repo/scripts/tests/launcher/data
export XDG_DATA_DIRS=/tmp/launcher-data
export NIRI_BACKEND=headless
export QT_QPA_PLATFORM=wayland
export QT_QUICK_BACKEND=software
mkdir -m 700 "$XDG_RUNTIME_DIR" "$XDG_CONFIG_HOME" "$XDG_DATA_DIRS"
mkdir "$XDG_CONFIG_HOME/quickshell"
cp -r /repo/dotfiles/quickshell/bar "$XDG_CONFIG_HOME/quickshell/bar"
cp /repo/scripts/tests/launcher/shell.qml "$XDG_CONFIG_HOME/quickshell/bar/shell.qml"

niri --config /repo/scripts/tests/launcher/niri.kdl >/artifacts/niri.log 2>&1 &
compositor=$!
trap 'kill "$compositor"' EXIT
export WAYLAND_DISPLAY=wayland-1
export NIRI_SOCKET="$XDG_RUNTIME_DIR/niri.$WAYLAND_DISPLAY.$compositor.sock"
for _ in {1..50}; do
    [[ ! -S "$NIRI_SOCKET" ]] || break
    sleep 0.1
done
niri msg action focus-monitor TEST
quickshell -c bar >/artifacts/quickshell.log 2>&1 &

ipc() { quickshell ipc -c bar call "$@"; }
state() { ipc test state; }
for _ in {1..50}; do
    if state >/dev/null 2>&1; then break; fi
    sleep 0.1
done
sleep 0.3

# Invoke the binding's command. Niri's virtual-keyboard protocol sends keys
# directly to clients, bypassing compositor shortcuts.
niri msg action spawn -- quickshell ipc -c bar call launcher toggle
sleep 0.2
state | jq -e '.open and (.results | length == 3)'
grim -o TEST /artifacts/launcher.png
wtype alpha -s 100
state | jq -e '.results == ["alpha-one", "alpha-two"]'
wtype -k Down -k Return -s 200
state | jq -e '.open == false'
test -f /tmp/launcher-two
test ! -e /tmp/launcher-one
test ! -e /tmp/launcher-hidden

ipc launcher open nonexistent
wtype -s 100 -k Return -s 100
state | jq -e '.open and (.results | length == 0)'
grim -o TEST /artifacts/empty.png
wtype -k Escape -s 100
state | jq -e '.open == false'

ipc launcher open terminal
wtype -s 100 -k Return -s 400
for _ in {1..30}; do
    [[ ! -f /tmp/launcher-terminal ]] || break
    sleep 0.1
done
test -f /tmp/launcher-terminal

niri msg action focus-monitor portrait-center
ipc launcher open alpha
wtype -s 100
niri msg -j layers | jq -e 'any(.[]; .namespace == "quickshell-launcher" and .output == "portrait-center")'
grim -o PORTRAIT /artifacts/portrait.png
ipc launcher toggle
state | jq -e '.open == false'
ipc launcher toggle
state | jq -e '.open'
ipc launcher close
state | jq -e '.open == false'
printf 'Launcher integration tests passed\n'
