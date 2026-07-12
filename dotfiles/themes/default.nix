{ lib, pkgs }:

let
  palettes = import ./palettes.nix;
  templates = {
    "eza.yml" = ./templates/eza.yml;
    "jj.toml" = ./templates/jj.toml;
    "kitty.conf" = ./templates/kitty.conf;
    "nvim.lua" = ./templates/nvim.lua;
    "tmux.conf" = ./templates/tmux.conf;
  };

  renderTheme = name: palette:
    let
      bright = "ffffff";
      onColor = if palette.variant == "dark" then palette.background else bright;
      roles = palette // {
        inherit bright onColor;
      };
      files = lib.mapAttrsToList (file: template: {
        name = file;
        path = pkgs.replaceVars template (
          lib.filterAttrs
            (variable: _: lib.hasInfix "@${variable}@" (builtins.readFile template))
            roles
        );
      }) templates;
    in
    pkgs.linkFarm "theme-${name}" files;
in
pkgs.linkFarm "themes" (lib.mapAttrsToList (name: palette: {
  inherit name;
  path = renderTheme name palette;
}) palettes)
