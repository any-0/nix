system:
{ config, lib, pkgs, ... }:
let
  isDarwin = builtins.match ".*-darwin" system != null;
  keepArgs = "--keep-since 24h --keep 1";
in
if isDarwin then
  {
    nix.gc = {
      automatic = true;
      dates = "daily";
    };
    launchd.agents.nix-gc.config.StartCalendarInterval = lib.mkForce [
      { Hour = 5; Minute = 0; }
    ];
    launchd.agents.nix-gc.config.ProgramArguments = lib.mkForce [
      "${pkgs.nix}/bin/nix-collect-garbage"
      "--delete-older-than"
      "1d"
    ];
  }
else
  {
    systemd.user.timers.nh-clean = {
      Unit.Description = "Run nh clean";
      Timer = {
        OnCalendar = "*-*-* 05:00:00";
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
