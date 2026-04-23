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
  xdg.configFile."kitty/kitty.conf".source = dot ".config/kitty/kitty.conf";
  xdg.configFile."zen/odpbn0jp.Default Profile/user.js".text = ''
    user_pref("zen.window-sync.enabled", false);
  '';

  home.packages = with pkgs; [
    evince
    fuzzel
    swaybg
    mako
    libnotify
    grim
    slurp
    obs-studio
    polkit_gnome
    spice-vdagent
    vlc
    wl-clipboard
    kitty
    playerctl
    swaylock
    xwayland-satellite
    zen-browser
  ] ++ [
    pkgs.kdePackages.dolphin
  ];
}
