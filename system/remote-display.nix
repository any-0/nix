{ config, pkgs, ... }:

let
  displays = pkgs.writeShellApplication {
    name = "sunshine-displays";
    runtimeInputs = [ config.programs.niri.package ];
    text = ''
      case "$1" in
        connect)
          niri msg output sunshine custom-mode "''${2}x''${3}@''${4}"
          niri msg output sunshine on
          niri msg action focus-monitor sunshine
          niri msg output DP-1 off
          niri msg output HDMI-A-1 off
          ;;
        disconnect)
          niri msg output DP-1 on
          niri msg output HDMI-A-1 on
          niri msg output sunshine off
          ;;
        *) exit 2 ;;
      esac
    '';
  };
in
{
  # Sunshine's prep/undo commands run per application, not per connection.
  # Use its display lifecycle, which also runs before probing on resume.
  services.sunshine.package = pkgs.sunshine.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (pkgs.replaceVars ./patches/sunshine-niri-displays.patch {
        displayCommand = "${displays}/bin/sunshine-displays";
      })
    ];
  });
  services.sunshine.settings = {
    capture = "wlr";
    output_name = "sunshine";
    csrf_allowed_origins = "https://192.168.0.128:47990";
    dd_config_revert_on_disconnect = "enabled";
  };
  systemd.user.services.sunshine.serviceConfig = {
    ExecStartPre = "${displays}/bin/sunshine-displays disconnect";
    ExecStopPost = "${displays}/bin/sunshine-displays disconnect";
  };
}
