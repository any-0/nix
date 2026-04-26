# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let
  smbCredentials = "/home/julian/nix/secrets/smb-nas.cred";
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

  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    timeout = 0;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.plymouth.enable = true;
  boot.initrd.verbose = false;
  boot.consoleLogLevel = 3;
  boot.kernelParams = [
    "quiet"
    "splash"
    "loglevel=3"
    "udev.log_level=3"
    "rd.udev.log_level=3"
    "systemd.show_status=auto"
    "vt.global_cursor_default=0"
  ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.extraModprobeConfig = ''
    options btusb enable_autosuspend=n
  '';

  networking.networkmanager.enable = true;
  networking.interfaces.enp5s0.wakeOnLan.enable = true;
  time.timeZone = "Europe/Berlin";

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
    inkscape
  ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

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
        user = "julian";
        command = "${config.programs.niri.package}/bin/niri-session";
      };
      initial_session = {
        user = "julian";
        command = "${config.programs.niri.package}/bin/niri-session";
      };
    };
  };
  services.dbus.enable = true;
  hardware.graphics.enable = true;
  hardware.enableRedistributableFirmware = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.bluetooth.settings.General.Experimental = true;
  services.seatd.enable = true;
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
  fileSystems = {
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
