{ homeDirectory, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    warn-dirty = false;
  };

  programs.nh = {
    enable = true;
    flake = "${homeDirectory}/nix";
  };
}
