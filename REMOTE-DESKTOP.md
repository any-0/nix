# Remote desktop

This checkout follows the nix repository unstable branch. Nixpkgs remains on
nixos-26.05; this is separate from the repository branch.

Sunshine captures the niri virtual output named sunshine at the client resolution.
The pinned niri fork supplies create-virtual support. The virtual display uses
scale 2 for the Mac Retina desktop.

system/remote-display.nix patches Sunshine display preparation/restoration:

- Launch and resume: configure and enable sunshine, focus it, then disable DP-1
  and HDMI-A-1 before encoder probing.
- Last client disconnect: enable both physical displays, then disable sunshine.
- Service start/stop and a timed-out launch also restore the physical displays.
- Failed resume requests restore displays just like failed launch requests.

Application prep/undo commands alone do not implement this behavior: they do not
run for every resume/disconnect. The patch is tied to the pinned Sunshine version
and should be reviewed when Sunshine updates.

Apply with: sudo nixos-rebuild switch --flake ~/nix#pc

The Mac PC.app launcher connects directly and forwards Command as Linux Super.
Control-Option-Shift-Z releases keyboard/mouse capture; then Command-Tab switches
to Mac apps without disconnecting. Control-Option-Shift-D minimizes the stream,
and Control-Option-Shift-Q disconnects. The launcher uses the saved Moonlight
bitrate, resolution, and frame rate.

The black-screen incident was reproduced outside Moonlight: a 40 Mbps UDP burst
test lost 64% of packets. On retest, all 28,800 packets arrived and the native
2408x1506 desktop streamed successfully again with the normal 60 FPS / 39 Mbps
client settings. No encoder or bitrate diagnostic overrides remain.

The virtual display must be positioned at (0, 0). Leaving it at x=4480 after
turning off the physical displays misaligns absolute pointer coordinates between
Sunshine and niri. Physical displays retain their own configured positions.
