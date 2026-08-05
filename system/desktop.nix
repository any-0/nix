{ config, pkgs, username, ... }:

let
  iosevkaTermSlab = pkgs.callPackage ../dotfiles/fonts/iosevka-termslab-custom { };
in
{
  fonts.packages = [
    pkgs.jetbrains-mono
    iosevkaTermSlab
  ];

  # The rail glyphs only tile seamlessly when their outlines land on whole
  # pixels. Slight hinting, the fontconfig default, sends FreeType to the
  # autohinter, which rasterises at the fractional ppem the point size asks
  # for, so at every zoom level that is not a whole number of pixels per em
  # the bars end mid-pixel: rows join through a half-lit seam, and the cells
  # holding a connector sit a pixel to the side of the ones that do not.
  # Full hinting takes the TrueType interpreter instead, which rounds the
  # ppem, and the rails line up again.
  fonts.fontconfig.localConf = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <match target="font">
        <test name="family" compare="contains">
          <string>IosevkaTermSlab</string>
        </test>
        <edit name="hintstyle" mode="assign">
          <const>hintfull</const>
        </edit>
      </match>
    </fontconfig>
  '';

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
