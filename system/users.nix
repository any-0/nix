{ pkgs, username, ... }:

{
  programs.zsh.enable = true;

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "seat" "video" "input" "uinput" "docker" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPD75TBVAP3IJF5Ky2aJxIUa8Ya/fcQV88ZKf9naKYly remote-control-deploy"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOTYpjvYZ3UU/pHLlleyrE/XnaAvMb6fyK6jGEicfRr+ hermes@proxmox-vm-20260708"
    ];
  };
}
