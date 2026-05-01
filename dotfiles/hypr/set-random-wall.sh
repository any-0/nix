#!/usr/bin/env bash

WALLDIR="$HOME/Pictures/Wallpapers"

# pick a random image
IMG=$(find "$WALLDIR" -type f | shuf -n1)
echo "DEBUG: selected = $IMG" >&2
[ -z "$IMG" ] && { echo "ERROR: no images in $WALLDIR" >&2; exit 1; }

# make sure hyprpaper daemon is running
if ! pgrep -x hyprpaper >/dev/null; then
  echo "DEBUG: starting hyprpaper…" >&2
  hyprpaper &
  sleep 0.5
fi

# get all monitor names and set wallpaper for each
MONITORS=$(hyprctl monitors | awk '/^Monitor /{print $2}')
[ -z "$MONITORS" ] && { echo "ERROR: couldn't find any monitors" >&2; exit 1; }

for MON in $MONITORS; do
  echo "DEBUG: setting wallpaper on monitor = $MON" >&2
  hyprctl hyprpaper preload "$IMG"
  hyprctl hyprpaper wallpaper "${MON},${IMG}"
done
