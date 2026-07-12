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

  argb = alpha: color: "#${alpha}${color}";

  renderTheme = name: palette:
    let
      overlay = if palette.variant == "dark" then palette.bright else palette.foreground;
      variables = palette // {
        onColor = if palette.variant == "dark" then palette.background else palette.bright;
        onSurface = if palette.variant == "dark" then palette.bright else palette.foreground;
        backgroundBare = palette.background;
        foregroundBare = palette.foreground;
        brightBare = palette.bright;
        mutedBare = palette.muted;
        accentBare = palette.accent;
        secondaryBare = palette.secondary;
        successBare = palette.success;
        dangerBare = palette.danger;
        selectionBare = palette.selection;
        backgroundA62 = argb "9e" palette.background;
        backgroundA80 = argb "cc" palette.background;
        overlayA08 = argb "14" overlay;
        overlayA09 = argb "17" overlay;
        overlayA13 = argb "21" overlay;
        overlayA14 = argb "24" overlay;
        dangerA13 = argb "21" palette.danger;
        dangerA22 = argb "38" palette.danger;
      };
      files = lib.mapAttrsToList (file: template: {
        name = file;
        path = pkgs.replaceVars template (
          lib.filterAttrs
            (variable: _: lib.hasInfix "@${variable}@" (builtins.readFile template))
            variables
        );
      }) templates;
    in
    pkgs.linkFarm "theme-${name}" (files ++ [
      {
        name = "color-scheme";
        path = pkgs.writeText "theme-${name}-color-scheme" palette.colorScheme;
      }
    ]);
in
pkgs.linkFarm "themes" (lib.mapAttrsToList (name: palette: {
  inherit name;
  path = renderTheme name palette;
}) palettes)
