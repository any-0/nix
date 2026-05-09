{ pkgs, ... }:

{
  home.packages = with pkgs; [
    wakeonlan
  ];

  services.gpg-agent = {
    pinentry.package = pkgs.pinentry_mac;
  };
}
