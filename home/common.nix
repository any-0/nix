{ config, pkgs, lib, ... }:

let
  dotfilesDir = "${config.home.homeDirectory}/nix/dotfiles";
  scriptsDir = "${config.home.homeDirectory}/nix/scripts";
  localBinDir = "${config.home.homeDirectory}/.local/bin";
  gopassStoreDir = "${config.home.homeDirectory}/nix/gopass/store";
  dot = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
  dotFile = path: {
    source = dot path;
    force = true;
  };
in
{
  imports = [
    ./npm-tools.nix
    ./neovim-tools.nix
    ./tmux.nix
  ];

  home.stateVersion = "25.11";

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
    };
  };

  # Avoid building Home Manager's manual/options docs on every switch.
  manual.manpages.enable = false;

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

  xdg.configFile."zsh/.zshrc" = dotFile "zsh/zshrc";
  xdg.configFile."zsh/.zshenv" = dotFile ".zshenv";
  xdg.configFile."zsh/prompt.zsh" = dotFile "zsh/prompt.zsh";
  xdg.configFile."zsh/eza-colors.zsh" = dotFile "zsh/eza-colors.zsh";
  xdg.configFile."eza/theme.yml" = dotFile "eza/theme.yml";
  xdg.configFile."kitty/kitty.conf" = dotFile "kitty/kitty.conf";
  xdg.configFile."jj/config.toml" = dotFile "jj/config.toml";

  xdg.configFile."nvim" = dotFile "nvim";
  home.file.".zshenv" = dotFile ".zshenv";
  home.file.".codex/AGENTS.md" = dotFile "codex/AGENTS.md";
  home.file.".pi/agent/keybindings.json" = dotFile "pi/keybindings.json";
  home.file.".pi/agent/extensions" = dotFile "pi/extensions";

  home.sessionVariables = {
    PASSWORD_STORE_DIR = gopassStoreDir;
    EZA_CONFIG_DIR = "${config.xdg.configHome}/eza";
    NH_FLAKE = "${config.home.homeDirectory}/nix";
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
    jjui
    nh
  ];

}
