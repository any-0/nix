{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    discord
  ];

  programs.steam = {
    enable = true;
    protontricks.enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  programs.gamemode.enable = true;
}
