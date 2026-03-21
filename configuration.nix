# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let
  smbCredentials = "${config.users.users.julian.home}/nix/secrets/smb-nas.cred";
  hasSmbCredentials = builtins.pathExists smbCredentials;
  smbMountOptions = [
    "credentials=${smbCredentials}"
    "uid=1000"
    "gid=100"
    "iocharset=utf8"
    "x-systemd.automount"
    "nofail"
    "x-systemd.idle-timeout=60"
  ];
in

{
  imports = [
    ./hardware-configuration.nix
    ./home/games.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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

  fonts.packages = with pkgs; [
    jetbrains-mono
    nerd-fonts.iosevka-term-slab
  ];

  programs.niri.enable = true;
  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings.default_session.command =
      "${lib.getExe pkgs.tuigreet} --time --remember --remember-user-session --asterisks --cmd ${config.programs.niri.package}/bin/niri-session";
  };
  services.dbus.enable = true;
  hardware.graphics.enable = true;
  hardware.enableRedistributableFirmware = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.seatd.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };
  security.rtkit.enable = true;
  services.upower.enable = true;
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    config.common.default = [ "wlr" "gtk" ];
    config.niri.default = lib.mkForce [ "wlr" "gtk" ];
  };

  console.keyMap = "de";
  services.xserver.videoDrivers = [ "amdgpu" ];
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
  warnings = lib.optional (!hasSmbCredentials)
    "SMB credentials not found at ${smbCredentials}; skipping /mnt/home1 and /mnt/home2 mounts.";

  fileSystems = lib.optionalAttrs hasSmbCredentials {
    "/mnt/home1" = {
      device = "//192.168.0.227/home";
      fsType = "cifs";
      options = smbMountOptions;
    };

    "/mnt/home2" = {
      device = "//192.168.0.227/home2";
      fsType = "cifs";
      options = smbMountOptions;
    };
  };
}
