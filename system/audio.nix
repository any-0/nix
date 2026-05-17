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
    wireplumber.extraConfig."51-bluez-codecs" = {
      "monitor.bluez.properties" = {
        "bluez5.codecs" = [ "sbc" "sbc_xq" "aac" "aptx" "aptx_hd" "aptx_ll" "aptx_ll_duplex" ];
      };
    };
  };

  security.rtkit.enable = true;
  services.upower.enable = true;
}
