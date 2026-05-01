#!/usr/bin/env bash
set -euo pipefail

# 1) find any bluetooth battery device via UPower
mapfile -t devs < <(upower -e | grep -iE 'headset|bluez')
device="${devs[0]:-}"

# 2) read percentage
if [[ -n "$device" ]]; then
  pct=$(upower -i "$device" \
        | awk '/percentage:/ { gsub(/%/,""); print $2; exit }')
else
  pct="N/A"
fi

# 3) choose a CSS class if low
cls=""
if [[ "$pct" =~ ^[0-9]+$ ]] && (( pct < 20 )); then
  cls="low"
fi

# 4) emit *only* valid JSON to stdout
printf '{"text":"%s","class":"%s"}\n' "$pct" "$cls"
