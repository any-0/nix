{ config, pkgs, lib, ... }:

let
  dotfilesDir = "${config.home.homeDirectory}/nix/dotfiles";
  scriptsDir = "${config.home.homeDirectory}/nix/scripts";
  localBinDir = "${config.home.homeDirectory}/.local/bin";
  gopassStoreDir = "${config.home.homeDirectory}/nix/gopass/store";
  dot = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
in
{
  imports = [
    ./npm-tools.nix
    ./neovim-tools.nix
    ./tmux.nix
  ];

  home.stateVersion = "25.11";

  programs.git = {
    enable = true;
    settings.user.name = "Julian";
    settings.user.email = "julianorlich1@gmail.com";
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    sideloadInitLua = true;
    withPython3 = true;
    withRuby = true;
  };

  programs.gpg.enable = true;

  programs.direnv.enable = true;
  programs.direnv.config = {
    hide_env_diff = true;
  };
  programs.direnv.nix-direnv.enable = true;

  xdg.configFile."zsh/.zshrc".source = dot "zsh/zshrc";
  xdg.configFile."zsh/.zshenv".source = dot ".zshenv";
  xdg.configFile."zsh/prompt.zsh".source = dot "zsh/prompt.zsh";
  xdg.configFile."zsh/eza-colors.zsh".source = dot "zsh/eza-colors.zsh";
  xdg.configFile."eza/theme.yml".source = dot "eza/theme.yml";
  xdg.configFile."kitty/kitty.conf".source = dot "kitty/kitty.conf";
  xdg.configFile."jj/config.toml".source = dot "jj/config.toml";

  xdg.configFile."nvim".source = dot "nvim";
  home.file.".zshenv".source = dot ".zshenv";
  home.file.".codex/AGENTS.md".source = dot "codex/AGENTS.md";
  home.file.".pi/agent/settings.json".source = dot "pi/settings.json";
  home.file.".pi/agent/keybindings.json".source = dot "pi/keybindings.json";
  home.file.".pi/agent/extensions".source = dot "pi/extensions";

  home.sessionVariables = {
    PASSWORD_STORE_DIR = gopassStoreDir;
    EZA_CONFIG_DIR = "${config.xdg.configHome}/eza";
  };
  home.sessionPath = [
    scriptsDir
    localBinDir
  ];

  home.activation.gopassStoreSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    store_dir="${gopassStoreDir}"
    $DRY_RUN_CMD mkdir -p "$store_dir"
    $DRY_RUN_CMD ${pkgs.gopass}/bin/gopass config mounts.path "$store_dir"
  '';

  services.gpg-agent = {
    enable = true;
    enableZshIntegration = true;
  };

  home.packages = with pkgs; [
    zsh
    ripgrep
    fd
    fzf
    wget
    curl
    jq
    unzip
    zip
    python3
    gnupg
    # gcc
    gnumake
    gopass
    zoxide
    eza
    bc
    lazygit
    gh
    jujutsu
  ];

}
