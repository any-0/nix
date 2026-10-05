#!/usr/bin/env bash
set -euo pipefail

# Run in Docker with only a GPU render node, no host display or input devices.
export XDG_RUNTIME_DIR=/tmp/sunshine-runtime
export XDG_CONFIG_HOME=/tmp/sunshine-config
export NIRI_BACKEND=headless
mkdir -m 700 "$XDG_RUNTIME_DIR" "$XDG_CONFIG_HOME"

cat > /tmp/niri.kdl <<'EOF'
output "HEADLESS-1" { off; }
output "sunshine" {
    off
    create-virtual
    mode "1920x1080@60"
    scale 1
}
animations { off; }
hotkey-overlay { skip-at-startup; }
EOF

niri --config /tmp/niri.kdl > /artifacts/niri.log 2>&1 &
compositor=$!
server=
cleanup() {
    if [[ -n "$server" ]]; then kill "$server"; wait "$server" || true; fi
    kill "$compositor"
    wait "$compositor" || true
}
trap cleanup EXIT
export WAYLAND_DISPLAY=wayland-1
export NIRI_SOCKET="$XDG_RUNTIME_DIR/niri.$WAYLAND_DISPLAY.$compositor.sock"
for _ in {1..100}; do
    if [[ -S "$NIRI_SOCKET" ]]; then break; fi
    sleep 0.1
done

openssl req -x509 -newkey rsa:2048 -nodes -sha256 -days 1 \
    -subj /CN=sunshine-headless-test -keyout /tmp/client.key \
    -out /tmp/client.crt > /artifacts/certificate.log 2>&1
jq -n --rawfile cert /tmp/client.crt \
    '{root: {uniqueid: "headless-test", named_devices: [{name: "test", cert: $cert, uuid: "test", enabled: true}]}}' \
    > /tmp/state.json
printf '{"apps": []}\n' > /tmp/apps.json
cat > /tmp/sunshine.conf <<'EOF'
capture=wlr
output_name=sunshine
encoder=vaapi
file_state=/tmp/state.json
file_apps=/tmp/apps.json
pkey=/tmp/server.key
cert=/tmp/server.crt
log_path=/tmp/sunshine.log
EOF

request() {
    curl --silent --show-error --fail --insecure --max-time 20 \
        --cert /tmp/client.crt --key /tmp/client.key "$1"
}

run_case() {
    local binary=$1 label=$2 expected=$3
    niri msg output sunshine off
    niri msg -j outputs | jq -e 'all(.[]; .logical == null)'
    "$binary" /tmp/sunshine.conf > "/artifacts/$label.log" 2>&1 &
    server=$!
    for _ in {1..100}; do
        if curl --silent --fail http://127.0.0.1:47989/serverinfo > /dev/null; then break; fi
        sleep 0.1
    done
    request 'https://127.0.0.1:47984/launch?appid=0&rikey=00000000000000000000000000000000&rikeyid=1&localAudioPlayMode=0&mode=1920x1080x60&uniqueid=headless-test' \
        > "/artifacts/$label-launch.xml"
    rg -q "status_code=\"$expected\"" "/artifacts/$label-launch.xml"
    if [[ "$expected" == 200 ]]; then
        rg -q '<gamesession>1</gamesession>' "/artifacts/$label-launch.xml"
        rg -q 'Found H.264 encoder: h264_vaapi' "/artifacts/$label.log"
        if rg -q 'Platform failed to initialize|Unable to initialize capture method' "/artifacts/$label.log"; then
            return 1
        fi
        request https://127.0.0.1:47984/cancel > "/artifacts/$label-cancel.xml"
        # Connect again with all outputs off, without restarting Sunshine.
        niri msg -j outputs | jq -e 'all(.[]; .logical == null)'
        request 'https://127.0.0.1:47984/launch?appid=0&rikey=00000000000000000000000000000000&rikeyid=2&localAudioPlayMode=0&mode=2408x1506x30&uniqueid=headless-test' \
            > "/artifacts/$label-reconnect.xml"
        rg -q 'status_code="200"' "/artifacts/$label-reconnect.xml"
        rg -q '<gamesession>1</gamesession>' "/artifacts/$label-reconnect.xml"
        request https://127.0.0.1:47984/cancel > /dev/null
    else
        rg -q 'Unable to initialize capture method' "/artifacts/$label.log"
    fi
    kill "$server"
    wait "$server"
    server=
    printf '%s: launch returned %s\n' "$label" "$expected"
}

run_case "$1" original 503
run_case "$2" patched 200
printf 'Headless startup and reconnect tests passed\n'
