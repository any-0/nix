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

  channel = color: index: lib.fromHexString (builtins.substring (index * 2) 2 color);
  hexByte = value:
    let rendered = lib.toLower (lib.toHexString value);
    in if builtins.stringLength rendered < 2 then "0${rendered}" else rendered;
  mix = amount: color: other: lib.concatMapStrings (index:
    hexByte (builtins.floor ((1.0 - amount) * channel color index + amount * channel other index + 0.5))
  ) [ 0 1 2 ];
  tabShades = role: color: {
    "${role}Dim" = mix 0.14 color "000000";
    "${role}Dark" = mix 0.46 color "000000";
  };

  renderTheme = name: palette:
    let
      bright = "ffffff";
      onColor = if palette.variant == "dark" then palette.background else bright;
      roles = palette // {
        inherit bright onColor;
        onColorMuted = mix 0.2 onColor (mix 0.14 palette.secondary "000000");
      }
      // tabShades "accent" palette.accent
      // tabShades "success" palette.success
      // tabShades "secondary" palette.secondary;
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
