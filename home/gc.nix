system:
let
  isDarwin = builtins.match ".*-darwin" system != null;
in
if isDarwin then
  {
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  }
else
  {
    programs.nh.clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep-since 7d --keep 3";
    };
  }
