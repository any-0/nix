# PC launcher

`PC.app` launches Moonlight directly into the paired PC's Desktop stream.
Home Manager installs it in `~/Applications` on the Mac.

- Command-Tab switches to Mac apps without ending the stream.
- Control-Option-Shift-Q disconnects.
- The launcher uses borderless mode and remote desktop mouse input.
  Bitrate, resolution, and frame rate use Moonlight's saved settings.
- macOS system shortcuts stay local; other input goes to the PC while focused.

Moonlight must be installed at `/Applications/Moonlight.app` and paired with
`192.168.0.128`.
