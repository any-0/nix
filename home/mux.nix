{ config, ... }:

# The mux binary is not built by Nix: the mux repository installs it to
# ~/.local/bin with `scripts/install`, and zsh skips mux when it is missing.
{
  xdg.configFile."mux/config.toml" = {
    text = ''
      theme = "${config.xdg.configHome}/theme/current/mux.toml"
    '' + builtins.readFile ../dotfiles/mux/config.toml;
    force = true;
  };
}
