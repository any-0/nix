system:
{ config, lib, pkgs, ... }:
let
  isDarwin = builtins.match ".*-darwin" system != null;
  keepArgs = "--keep-since 7d --keep 3";
in
if isDarwin then
  {
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  }
else
  {
    systemd.user.timers.nh-clean = {
      Unit.Description = "Run nh clean";
      Timer = {
        OnCalendar = "weekly";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };

    systemd.user.services.nh-clean = {
      Unit.Description = "Nh clean";
      Service = {
        Type = "oneshot";
        ExecStart = [
          "${lib.getExe pkgs.nh} clean profile ${config.home.homeDirectory}/.local/state/nix/profiles/home-manager ${keepArgs} --no-gc"
          "${lib.getExe pkgs.nh} clean profile ${config.home.homeDirectory}/.local/state/nix/profiles/profile ${keepArgs}"
        ];
      };
    };
  }
