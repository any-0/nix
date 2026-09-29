{ ... }:

{
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.bluetooth.settings.General.Experimental = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    wireplumber.extraConfig."51-bluez" = {
      "monitor.bluez.properties" = {
        "bluez5.codecs" = [ "sbc" "sbc_xq" "aac" "aptx" "aptx_hd" "aptx_ll" "aptx_ll_duplex" ];
        # Headsets push their own AVRCP absolute volume shortly after connecting,
        # which overwrites the restored volume with 100%. Apply volume in
        # software instead so the saved level survives a reconnect.
        "bluez5.enable-hw-volume" = false;
      };
    };
  };

  security.rtkit.enable = true;
  services.upower.enable = true;
}
