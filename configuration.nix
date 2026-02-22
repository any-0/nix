# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let
  smbCredentials = "${config.users.users.julian.home}/nix/secrets/smb-nas.cred";
in

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda"; # or "nodev" for efi only

  networking.networkmanager.enable = true;

  system.stateVersion = "25.11"; # never change
  programs.zsh.enable = true;
  users.users.julian = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "seat" "video" "input" "docker" ];
    shell = pkgs.zsh;
  };
  environment.systemPackages = with  pkgs; [
    cifs-utils
    docker
    docker-compose
    home-manager
  ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.getty.autologinUser = "julian";
  fonts.packages = with pkgs; [
    jetbrains-mono
  ];

programs.bash.loginShellInit = ''
  if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = 1 ] && [ "$(tty)" = /dev/tty1 ]; then
    export XDG_CURRENT_DESKTOP=niri
    export XDG_SESSION_TYPE=wayland
    export XDG_SESSION_DESKTOP=niri
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
    wlr.enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    config.common.default = [ "wlr" "gtk" ];
    config.niri.default = lib.mkForce [ "wlr" "gtk" ];
  };

  console.keyMap = "de";
  services.xserver.videoDrivers = [ "virtio" ];
  services.spice-vdagentd.enable = true;
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;


nix.gc = {
  automatic = true;
  dates = "weekly";
  options = "--delete-older-than 7d";
};

  virtualisation.docker.enable = true;
  virtualisation.containerd.enable = true;

  #SMB
  boot.supportedFilesystems = [ "cifs" ];

  fileSystems."/mnt/home1" = {
    device = "//192.168.0.227/home";
    fsType = "cifs";
    options = [
      "credentials=${smbCredentials}"
      "uid=1000"
      "gid=100"
      "iocharset=utf8"
      "x-systemd.automount"
      "nofail"
      "x-systemd.idle-timeout=60"
    ];
  };

  fileSystems."/mnt/home2" = {
    device = "//192.168.0.227/home2";
    fsType = "cifs";
    options = [
      "credentials=${smbCredentials}"
      "uid=1000"
      "gid=100"
      "iocharset=utf8"
      "x-systemd.automount"
      "nofail"
      "x-systemd.idle-timeout=60"
    ];
  };
}
