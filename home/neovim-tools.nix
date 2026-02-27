{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nodejs
    tree-sitter
    stylua
    lua-language-server
    nil
    # clang-tools
    # rust-analyzer
    # cargo
    pyright
    ruff
    typescript
    typescript-language-server
    bash-language-server
    dockerfile-language-server
    docker-compose-language-service
  ];

  programs.neovim.plugins = [
    pkgs.vimPlugins.nvim-treesitter.withAllGrammars
  ];
}
