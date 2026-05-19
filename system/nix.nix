{ pkgs, homeDirectory, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    warn-dirty = false;
  };

  programs.nh = {
    enable = true;
    flake = "${homeDirectory}/nix";
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep-since 7d --keep 3";
    };
  };

  environment.systemPackages = with pkgs; [
    home-manager
  ];
}
