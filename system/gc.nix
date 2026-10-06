{ ... }:

{
  programs.nh.clean = {
    enable = true;
    dates = "*-*-* 05:00:00";
    # Project dev shells and manually rooted builds must survive daily cleanup.
    # Only expire profile generations; let Nix collect genuinely unrooted paths.
    extraArgs = "--keep-since 24h --keep 1 --no-gcroots --no-direnv";
  };

  nix.optimise.automatic = true;
}
