# Sunshine headless regression test

`integration.sh ORIGINAL_BINARY PATCHED_BINARY` runs inside Docker with a private
headless Niri and D-Bus session. Provide Niri, jq, curl, OpenSSL, and ripgrep on
`PATH`. Mount the repository read-only at `/repo`, the Nix store read-only at
`/nix/store`, graphics drivers at `/run/opengl-driver`, fonts at `/etc/fonts`, and
a writable artifact directory at `/artifacts`. Expose only `/dev/dri/renderD128`;
do not expose host runtime sockets or input devices. When using Nix's
`dbus-run-session`, pass its `share/dbus-1/session.conf` through `--config-file`.

The test starts with every output disabled. The original Sunshine build returns
503 from its authenticated launch endpoint because it permanently rejects the
Wayland capture backend at startup. The patched build accepts the launch after
its display lifecycle enables the virtual output, discovers the VA-API hardware
encoder, and accepts another launch at a different resolution after cancelling
the first one. Neither connection restarts Sunshine.

Logs and launch responses are saved in `/artifacts`. The client certificate and
Sunshine state are temporary and separate from the host's paired devices. This
tests capture and encoder initialization; it does not run an RTSP video stream.
