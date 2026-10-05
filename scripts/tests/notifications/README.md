# Notification tests

Run `integration.sh` in Docker, not against the desktop session. Use the same
private headless Niri setup as `../launcher/README.md`, adding `busctl` and `rg`
to PATH. No host Wayland sockets, session bus, or input devices are mounted.

The fixture runs the real notification server, toast layout, bar bell/menu, and
history view. Tests cover replacement, actions, dismissal, application closure,
millisecond timeouts, transient messages, critical notifications, quiet mode,
and reload persistence without replaying popups. Screenshots and D-Bus signal
logs are saved in `/artifacts`.

Notifications remain actionable in memory after their toast disappears. Clearing
history dismisses them; transient messages expire without entering history.
The history is capped at 100, survives configuration reloads, and is not saved
to disk or retained after restarting Quickshell.
