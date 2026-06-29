{ pkgs, ... }:

let
  zsh = "${pkgs.zsh}/bin/zsh";
  startZsh = ''
    if [ -z "''${ZSH_VERSION:-}" ] && [ -t 0 ] && [ -t 1 ]; then
      export SHELL="${zsh}"
      exec "${zsh}" -l
    fi
  '';
in
{
  home.file.".profile".text = startZsh;
  home.file.".bashrc".text = startZsh;
}
