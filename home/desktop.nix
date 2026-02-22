{ config, pkgs, ... }:

let
  dotfilesDir = "${config.home.homeDirectory}/nix/dotfiles";
  dot = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
in
{
  xdg.configFile."niri".source = dot ".config/niri";
  xdg.configFile."waybar".source = dot ".config/waybar";

  systemd.user.services.waybar = {
    Unit = {
      Description = "Waybar";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Environment = [
        "XDG_RUNTIME_DIR=%t"
        "WAYLAND_DISPLAY=wayland-1"
        "XDG_CURRENT_DESKTOP=niri"
        "GTK_USE_PORTAL=0"
        "GDK_BACKEND=wayland"
      ];
      ExecStartPre = "${pkgs.bash}/bin/bash -lc 'for i in $(seq 1 50); do [ -S \"$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY\" ] && exit 0; sleep 0.2; done; exit 1'";
      ExecStart = "${pkgs.waybar}/bin/waybar";
      Restart = "on-failure";
      RestartSec = "2s";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  home.packages = with pkgs; [
    fuzzel
    waybar
    swaybg
    mako
    grim
    slurp
    polkit_gnome
    spice-vdagent
    wl-clipboard
    wezterm
  ];
}
