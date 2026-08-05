{ config, pkgs, mux, ... }:

{
  home.packages = [ mux.packages.${pkgs.stdenv.hostPlatform.system}.default ];
  xdg.configFile."mux/config.toml" = {
    text = ''
      theme = "${config.xdg.configHome}/theme/current/mux.toml"
    '' + builtins.readFile ../dotfiles/mux/config.toml;
    force = true;
  };
}
