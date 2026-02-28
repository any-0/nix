{ config, lib, ... }:

let
  dotfilesDir = "${config.home.homeDirectory}/nix/dotfiles";
  links = {
    "/root/.zshenv" = ".zshenv";
    "/root/.inputrc" = ".inputrc";
    "/root/.config/zsh/.zshrc" = ".config/zsh/.zshrc";
    "/root/.config/zsh/prompt.zsh" = ".config/zsh/prompt.zsh";
    "/root/.config/zsh/eza-colors.zsh" = ".config/zsh/eza-colors.zsh";
    "/root/.config/eza/theme.yml" = ".config/eza/theme.yml";
    "/root/.config/nvim" = ".config/nvim";
  };

  linkCommands = lib.concatStringsSep "\n" (lib.mapAttrsToList (dest: src: ''
    /usr/bin/sudo mkdir -p "$(dirname '${dest}')"
    /usr/bin/sudo ln -sfn '${dotfilesDir}/${src}' '${dest}'
  '') links);
in
{
  home.activation.rootDotfiles = config.lib.dag.entryAfter [ "writeBoundary" ] linkCommands;
}
