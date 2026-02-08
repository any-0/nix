# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda"; # or "nodev" for efi only

  networking.networkmanager.enable = true;

  system.stateVersion = "25.11"; # never change
  users.users.julian = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "seat" "video" "input"];
  };
  environment.systemPackages = with  pkgs; [
  ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.getty.autologinUser = "julian";
  fonts.packages = with pkgs; [
    jetbrains-mono
  ];

  programs.bash.loginShellInit = ''
    # Auto-start niri only on the real first VT login, not inside terminal emulators.
    if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = 1 ] && [ "$(tty)" = /dev/tty1 ]; then
      export WLR_BACKENDS=headless
      export WLR_RENDERER=pixman
      exec niri
    fi
    '';
  programs.niri.enable = true;
  services.dbus.enable = true;
  hardware.graphics.enable = true;
  services.seatd.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };
  security.rtkit.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
  };
  console.keyMap = "de";
  services.xserver.videoDrivers = [ "virtio" ];
  services.spice-vdagentd.enable = true;
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;
}
