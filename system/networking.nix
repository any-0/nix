{ ... }:

{
  networking.networkmanager.enable = true;
  networking.interfaces.enp5s0.wakeOnLan.enable = true;
  time.timeZone = "Europe/Berlin";

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;
}
