{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./boot.nix
    ./networking.nix
    ./users.nix
    ./nix.nix
    ./desktop.nix
    ./audio.nix
    ./docker.nix
    ./smb.nix
    ./games.nix
  ];

  system.stateVersion = "25.11"; # never change
}
