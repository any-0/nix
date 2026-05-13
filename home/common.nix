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
  };

  programs.gpg.enable = true;

  programs.direnv.enable = true;
  programs.direnv.config = {
    hide_env_diff = true;
  };
  programs.direnv.nix-direnv.enable = true;
  programs.bash = {
    enable = true;
    initExtra = ''
      git_prompt_bash() {
        git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return

        local changes numstat line x y add del
        local staged=0 unstaged=0 untracked=0
        local added=0 removed=0
        local segments=()

        changes="$(git status --porcelain 2>/dev/null)"
        numstat="$(
          git diff --numstat 2>/dev/null
          git diff --cached --numstat 2>/dev/null
        )"

        while IFS=$'\t' read -r add del _; do
          [[ "$add" =~ ^[0-9]+$ ]] && ((added += add))
          [[ "$del" =~ ^[0-9]+$ ]] && ((removed += del))
        done <<< "$numstat"

        while IFS= read -r line; do
          [[ -z "$line" ]] && continue

          if [[ "$line" == '?? '* ]]; then
            ((untracked++))
            continue
          fi

          x="''${line:0:1}"
          y="''${line:1:1}"
          [[ "$x" != " " ]] && ((staged++))
          [[ "$y" != " " ]] && ((unstaged++))
        done <<< "$changes"

        segments=("+''${added} -''${removed}")
        ((staged > 0)) && segments+=("S:''${staged}")
        ((unstaged > 0)) && segments+=("M:''${unstaged}")
        ((untracked > 0)) && segments+=("U:''${untracked}")

        printf '  [%s]' "''${segments[*]}"
      }

      update_nix_shell_prompt() {
        local gray='\[\e[38;5;245m\]'
        local green='\[\e[38;5;46m\]'
        local reset='\[\e[0m\]'
        local bold='\[\e[1m\]'
        local nobold='\[\e[22m\]'
        local prefix=""

        if [[ -n "$__nix_shell_prompt_ready" ]]; then
          prefix='\n'
        else
          __nix_shell_prompt_ready=1
        fi

        PS1="''${prefix}''${gray}\u@\h  [\w]\$(git_prompt_bash)''${reset}\n''${bold}''${green}❯''${reset}''${nobold} "
      }

      if [[ -n "$IN_NIX_SHELL" ]]; then
        export NIX_SHELL_PRESERVE_PROMPT=1
        PS0=$'\n'
        PROMPT_COMMAND=update_nix_shell_prompt
      fi

      if [[ $- == *i* ]] && [[ -z "$IN_NIX_SHELL" ]] && command -v zsh >/dev/null 2>&1; then
        exec zsh -l
      fi
    '';
  };

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
