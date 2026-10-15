{ ... }:

{
  programs.nh.clean = {
    enable = true;
    dates = "*-*-* 05:00:00";
    # Age out profile generations, but preserve project and direnv GC roots.
    extraArgs = "--keep-since 24h --keep 1 --no-gcroots --no-direnv";
  };

  nix.optimise.automatic = true;
}
