{ config, pkgs, ... }:

let
  dotfilesDir = "${config.home.homeDirectory}/nix/dotfiles";
  dot = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
in
{
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
  };

  home.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
    NIXOS_OZONE_WL = "1";
  };

  xdg.configFile."bar/bar.toml".source = dot ".config/bar/bar.toml";
  xdg.configFile."bar/style.css".source = dot ".config/bar/style.css";
  xdg.configFile."niri".source = dot ".config/niri";
  xdg.configFile."kitty".source = dot ".config/kitty";

  home.packages = with pkgs; [
    julian-bar
    fuzzel
    swaybg
    mako
    libnotify
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
    zen-browser
  ] ++ [
    pkgs.kdePackages.dolphin
  ];
}
