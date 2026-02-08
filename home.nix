{ ... }:

{
  # Backward-compatible desktop profile used by the NixOS host module.
  imports = [
    ./home/common.nix
    ./home/desktop.nix
  ];
}
