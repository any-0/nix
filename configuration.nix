{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./system/boot.nix
    ./system/networking.nix
    ./system/users.nix
    ./system/nix.nix
    ./system/desktop.nix
    ./system/audio.nix
    ./system/docker.nix
    ./system/smb.nix
    ./system/games.nix
  ];

  system.stateVersion = "25.11"; # never change
}
