{ config, lib, pkgs, username, ... }:

{
  fonts.packages = with pkgs; [
    jetbrains-mono
    nerd-fonts.iosevka-term-slab
  ];

  programs.niri.enable = true;
  services.greetd = {
    enable = true;
    restart = true;
    settings = {
      default_session = {
        user = username;
        command = "${config.programs.niri.package}/bin/niri-session";
      };
      initial_session = {
        user = username;
        command = "${config.programs.niri.package}/bin/niri-session";
      };
    };
  };

  services.dbus.enable = true;
  hardware.graphics.enable = true;
  hardware.enableRedistributableFirmware = true;
  services.seatd.enable = true;

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    config.common.default = [ "wlr" "gtk" ];
    config.niri.default = lib.mkForce [ "wlr" "gtk" ];
  };

  console.keyMap = "de";

  environment.systemPackages = with pkgs; [
    inkscape
    quickshell
  ];
}
