{ ... }:

{
  programs.nh.clean = {
    enable = true;
    dates = "weekly";
    extraArgs = "--keep-since 7d --keep 3";
  };

  nix.optimise.automatic = true;
}
