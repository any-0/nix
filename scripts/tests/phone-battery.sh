#!/usr/bin/env bash
set -euo pipefail
cd /repo

busctl() {
    case "$*" in
        *'devices bb'*)
            [[ $SCENARIO != unavailable ]] || return 1
            if [[ $SCENARIO == offline ]]; then
                printf '%s\n' '{"data":[[]]}'
            else
                printf '%s\n' '{"data":[["test-phone"]]}'
            fi ;;
        *device.battery)
            jq -cn --argjson charge "$CHARGE" --argjson charging "$CHARGING" \
                '{data:[{charge:{data:$charge},isCharging:{data:$charging}}]}' ;;
        *kdeconnect.device)
            jq -cn --arg type "$DEVICE_TYPE" '{data:[{type:{data:$type},name:{data:"Phone"}}]}' ;;
        *) return 1 ;;
    esac
}
export -f busctl
export SCENARIO=online CHARGE=73 CHARGING=false DEVICE_TYPE=phone
check() {
    local actual
    actual=$(bash scripts/internal/phone-battery)
    [[ $actual == "$1" ]] || { printf 'Unexpected result: %s\n' "$actual"; exit 1; }
}
check '[{"name":"Phone","charge":73,"charging":false}]'
CHARGE=0
check '[{"name":"Phone","charge":0,"charging":false}]'
CHARGE=100 CHARGING=true
check '[{"name":"Phone","charge":100,"charging":true}]'
CHARGE=-1
check '[]'
CHARGE=101
check '[]'
CHARGE=73 DEVICE_TYPE=desktop
check '[]'
DEVICE_TYPE=phone SCENARIO=offline
check '[]'
SCENARIO=unavailable
if bash scripts/internal/phone-battery; then
    printf 'Expected daemon failure\n'
    exit 1
fi
printf 'All phone battery tests passed\n'
