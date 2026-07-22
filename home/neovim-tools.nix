{ pkgs, ... }:

let
  nvimTreesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (grammars: with grammars; [
    arduino
    bash
    c
    cpp
    css
    diff
    dockerfile
    gitignore
    html
    javascript
    json
    kdl
    kitty
    latex
    lua
    make
    markdown
    markdown-inline
    nix
    python
    rust
    tmux
    toml
    tsx
    typescript
    yaml
  ]);
in
{
  # nvim declares LSP clients; global tools here are for editor basics/ad-hoc files.
  # Toolchain-specific LSPs live in templates/*/.nix/flake.nix.
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
    pkgs.vimPlugins.cmp-buffer
    pkgs.vimPlugins.cmp-nvim-lsp
    pkgs.vimPlugins.cmp-path
    pkgs.vimPlugins.gitsigns-nvim
    pkgs.vimPlugins.lualine-nvim
    pkgs.vimPlugins.nvim-autopairs
    pkgs.vimPlugins.nvim-cmp
    pkgs.vimPlugins.nvim-lspconfig
    pkgs.vimPlugins.nvim-web-devicons
    nvimTreesitter
    pkgs.vimPlugins.vim-easymotion
  ];
}
