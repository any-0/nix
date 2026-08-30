{ config, pkgs, lib, mux, cachix, ... }:

let
  dotfilesDir = "${config.home.homeDirectory}/nix/dotfiles";
  localBinDir = "${config.home.homeDirectory}/.local/bin";
  npmGlobalBinDir = "${config.home.homeDirectory}/.local/share/npm-global/bin";
  themeRoot = import ../dotfiles/themes { inherit lib pkgs; };
  dot = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
  dotFile = path: { source = dot path; force = true; };
  activeThemeFile = path: {
    source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/theme/current/${path}";
    force = true;
  };
  scriptPackages = import ./scripts.nix { inherit config lib mux pkgs; };
in
{
  _module.args = { inherit activeThemeFile dot dotFile scriptPackages; };
  imports = [
    ./npm-tools.nix
    ./neovim-tools.nix
    ./mux.nix
  ];

  home.stateVersion = "25.11"; # never change

  nix.package = lib.mkDefault pkgs.nix;
  programs.nh = {
    enable = true;
    flake = "${config.home.homeDirectory}/nix";
  };
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    warn-dirty = false;
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
    withPython3 = false;
    withRuby = false;
  };

  programs.gpg.enable = true;

  programs.direnv.enable = true;
  programs.direnv.config = {
    hide_env_diff = true;
  };
  programs.direnv.nix-direnv.enable = true;

  xdg.configFile."zsh/.zshrc" = dotFile "zsh/zshrc";
  xdg.configFile."zsh/.zshenv" = dotFile ".zshenv";
  xdg.configFile."zsh/completions" = dotFile "zsh/completions";
  xdg.configFile."zsh/prompt.zsh" = dotFile "zsh/prompt.zsh";
  xdg.configFile."zsh/eza-colors.zsh" = dotFile "zsh/eza-colors.zsh";
  xdg.configFile."eza/theme.yml" = activeThemeFile "eza.yml";
  xdg.configFile."kitty/kitty.conf" = dotFile "kitty/kitty.conf";
  xdg.configFile."jj/config.toml" = dotFile "jj/config.toml";
  xdg.configFile."jj/conf.d/theme.toml" = activeThemeFile "jj.toml";
  xdg.configFile."theme/themes".source = themeRoot;

  xdg.configFile."nvim" = dotFile "nvim";
  xdg.configFile."opencode/plugins/terminal-bell.js" = dotFile "opencode/plugins/terminal-bell.js";
  home.file.".zshenv" = dotFile ".zshenv";
  home.file.".codex/AGENTS.md" = dotFile "codex/AGENTS.md";

  home.sessionVariables = {
    EZA_CONFIG_DIR = "${config.xdg.configHome}/eza";
    DIRENV_LOG_FORMAT = "";
  };
  home.sessionPath = [
    localBinDir
    npmGlobalBinDir
  ];

  home.activation.initializeTheme = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    theme_dir="${config.xdg.configHome}/theme"
    codex_theme_dir="${config.home.homeDirectory}/.codex/themes"
    claude_theme_dir="${config.home.homeDirectory}/.claude/themes"
    ${lib.getExe' pkgs.coreutils "mkdir"} -p "$theme_dir" "$codex_theme_dir" "$claude_theme_dir"

    theme_name=light
    if [[ -L "$theme_dir/current" ]]; then
      theme_name="$(${lib.getExe' pkgs.coreutils "basename"} "$(${lib.getExe' pkgs.coreutils "readlink"} "$theme_dir/current")")"
    fi
    ${lib.getExe' pkgs.coreutils "ln"} -sfn "$theme_dir/themes/$theme_name" "$theme_dir/current"
    ${lib.getExe' pkgs.coreutils "cp"} "$theme_dir/current/codex.tmTheme" "$codex_theme_dir/.current.tmTheme"
    ${lib.getExe' pkgs.coreutils "cp"} "$theme_dir/current/claude.json" "$claude_theme_dir/.current.json"
    ${lib.getExe' pkgs.coreutils "mv"} -f "$codex_theme_dir/.current.tmTheme" "$codex_theme_dir/current.tmTheme"
    ${lib.getExe' pkgs.coreutils "mv"} -f "$claude_theme_dir/.current.json" "$claude_theme_dir/current.json"
  '';

  services.gpg-agent = {
    enable = true;
    enableZshIntegration = true;
  };

  home.packages = (with pkgs; [
    zsh
    ripgrep
    fd
    fzf
    wget
    curl
    ffmpeg
    jq
    unzip
    zip
    python3
    # gcc
    gnumake
    zoxide
    eza
    bc
    gh
    cachix
    jujutsu
    jjui
    nix-zsh-completions
  ]) ++ builtins.attrValues scriptPackages;

}
