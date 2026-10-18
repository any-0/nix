{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    discord
    prismlauncher
  ];

programs.steam = {
  enable = true;
  protontricks.enable = true;
  extest.enable = true;

  extraCompatPackages = with pkgs; [
    proton-ge-bin
  ];
};  programs.gamemode.enable = true;
}
