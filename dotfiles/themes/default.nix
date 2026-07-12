{ lib, pkgs }:

let
  palettes = import ./palettes.nix;
  templates = {
    "eza.yml" = ./templates/eza.yml;
    "fuzzel.ini" = ./templates/fuzzel.ini;
    "jj.toml" = ./templates/jj.toml;
    "kitty.conf" = ./templates/kitty.conf;
    "mako.conf" = ./templates/mako.conf;
    "nvim.lua" = ./templates/nvim.lua;
    "quickshell.json" = ./templates/quickshell.json;
    "swaylock.conf" = ./templates/swaylock.conf;
    "tmux.conf" = ./templates/tmux.conf;
  };

  renderTheme = name: palette:
    let
      files = lib.mapAttrsToList (file: template: {
        name = file;
        path = pkgs.replaceVars template (
          lib.filterAttrs
            (variable: _: lib.hasInfix "@${variable}@" (builtins.readFile template))
            palette
        );
      }) templates;
    in
    pkgs.linkFarm "theme-${name}" (files ++ [
      {
        name = "color-scheme";
        path = pkgs.writeText "theme-${name}-color-scheme" "${palette.colorScheme}\n";
      }
    ]);
in
pkgs.linkFarm "themes" (lib.mapAttrsToList (name: palette: {
  inherit name;
  path = renderTheme name palette;
}) palettes)
