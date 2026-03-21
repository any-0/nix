{ config, pkgs, ... }:

let
  dotfilesDir = "${config.home.homeDirectory}/nix/dotfiles";
  dot = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
in
{
  xdg.configFile."bar/bar.toml".source = dot ".config/bar/bar.toml";
  xdg.configFile."bar/style.css".source = dot ".config/bar/style.css";
  xdg.configFile."niri".source = dot ".config/niri";
  xdg.configFile."kitty".source = dot ".config/kitty";

  home.packages = with pkgs; [
    julian-bar
    fuzzel
    swaybg
    mako
    grim
    slurp
    polkit_gnome
    spice-vdagent
    wl-clipboard
    kitty
    playerctl
    rofi
    swaylock
    xwayland-satellite
  ] ++ [
    pkgs.kdePackages.dolphin
  ];
}
