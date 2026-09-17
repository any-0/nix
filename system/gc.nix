{ ... }:

{
  programs.nh.clean = {
    enable = true;
    dates = "*-*-* 05:00:00";
    extraArgs = "--keep-since 24h --keep 1";
  };

  nix.optimise.automatic = true;
}
