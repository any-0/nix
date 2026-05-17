{ pkgs, username, ... }:

{
  programs.zsh.enable = true;

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "seat" "video" "input" "docker" ];
    shell = pkgs.zsh;
  };
}
