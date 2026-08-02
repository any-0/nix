{ pkgs, dotFile, ... }:

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
  };

  xdg.configFile."quickshell/bar" = dotFile "quickshell/bar";
  xdg.configFile."niri" = dotFile "niri";
  xdg.configFile."zen/odpbn0jp.Default Profile/user.js".text = ''
    user_pref("zen.window-sync.enabled", false);
  '';

  services.polkit-gnome.enable = true;

  home.packages = with pkgs; [
    evince
    fuzzel
    swaybg
    mako
    libnotify
    grim
    slurp
    obs-studio
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
