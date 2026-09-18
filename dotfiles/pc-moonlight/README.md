# PC launcher

`PC.app` launches Moonlight directly into the paired PC's Desktop stream.
Home Manager installs it in `~/Applications` on the Mac.

- Command reaches Linux as Super while the stream captures input.
- Control-Option-Shift-Z releases keyboard/mouse capture; then Command-Tab
  switches to Mac apps without ending the stream.
- Control-Option-Shift-D minimizes the stream without disconnecting.
- Control-Option-Shift-Q disconnects.
- The launcher uses borderless mode and remote desktop mouse input.
  Bitrate, resolution, and frame rate use Moonlight's saved settings.
- System shortcuts go to the PC while input is captured.

Moonlight must be installed at `/Applications/Moonlight.app` and paired with
`192.168.0.128`.
