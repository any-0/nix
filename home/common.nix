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
  };

  programs.gpg.enable = true;

  programs.direnv.enable = true;
  programs.direnv.config = {
    hide_env_diff = true;
  };
  programs.direnv.nix-direnv.enable = true;

  xdg.configFile."zsh/.zshrc".source = dot ".config/zsh/.zshrc";
  xdg.configFile."zsh/prompt.zsh".source = dot ".config/zsh/prompt.zsh";
  xdg.configFile."zsh/eza-colors.zsh".source = dot ".config/zsh/eza-colors.zsh";
  xdg.configFile."eza/theme.yml".source = dot ".config/eza/theme.yml";

  xdg.configFile."nvim".source = dot ".config/nvim";
  home.file.".zshenv".source = dot ".zshenv";
  home.file.".codex/AGENTS.md".source = dot ".codex/AGENTS.md";

  home.sessionVariables = {
    DOCKER_CLI_PLUGIN_EXTRA_DIRS = "${pkgs.docker-compose}/libexec/docker/cli-plugins";
    PASSWORD_STORE_DIR = gopassStoreDir;
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
    pinentry.package = pkgs.pinentry-tty;
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
    python3
    gnupg
    # gcc
    gnumake
    gopass
    claude-code
    codex
    zoxide
    eza
    procps
    bc
    lazygit
    xclip
  ];

}
