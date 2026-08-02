{ config, pkgs, username, ... }:

{
  fonts.packages = with pkgs; [
    jetbrains-mono
    nerd-fonts.iosevka-term-slab
  ];

  programs.niri = {
    enable = true;
    useNautilus = false;
  };
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

  console.keyMap = "de";

  environment.systemPackages = with pkgs; [
    inkscape
    quickshell
  ];
}
