{ pkgs, ... }:

{
  # nvim declares LSP clients; global tools here are for editor basics/ad-hoc files.
  # Toolchain-specific LSPs live in templates/*/.dev/flake.nix.
  home.packages = with pkgs; [
    tree-sitter
    stylua
    lua-language-server
    nil
    pyright
    ruff
    bash-language-server
    dockerfile-language-server
    docker-compose-language-service
  ];

  programs.neovim.plugins = [
    pkgs.vimPlugins.nvim-treesitter.withAllGrammars
  ];
}
