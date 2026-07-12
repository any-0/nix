{ config, pkgs, lib, dot, scriptPackages, ... }:

let
  tmuxClipboardCommand = pkgs.writeShellScript "tmux-clipboard" ''
    exec "${lib.getExe scriptPackages.yank}"
  '';

  tmuxZoxideSessionCreate = pkgs.writeShellScript "tmux-zoxide-session-create" ''
    set -euo pipefail

    export PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.tmux ]}:$PATH"

    display_error() {
      if [[ -n "''${TMUX:-}" ]]; then
        tmux display-message "$1"
      else
        printf '%s\n' "$1" >&2
      fi
    }

    path="$(tmux show-option -gqv @tmux-zoxide-path || true)"
    tmux set-option -gu @tmux-zoxide-path 2>/dev/null || true

    name="''${1:-}"
    name="''${name//:/_}"

    if [[ -z "$path" ]]; then
      display_error 'zoxide session path was not set'
      exit 1
    fi

    if [[ -z "$name" ]]; then
      display_error 'session name must not be empty'
      exit 1
    fi

    if ! tmux has-session -t "=$name" 2>/dev/null; then
      tmux new-session -d -s "$name" -c "$path"
      tmux set-option -t "=$name" -q @root_path "$path"
    fi

    if [[ -n "''${TMUX:-}" ]]; then
      exec tmux switch-client -t "=$name"
    else
      exec tmux attach-session -t "=$name"
    fi
  '';

  tmuxZoxideSession = pkgs.writeShellScript "tmux-zoxide-session" ''
    set -euo pipefail

    export PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.gnused pkgs.tmux pkgs.zoxide ]}:$PATH"

    display_error() {
      if [[ -n "''${TMUX:-}" ]]; then
        tmux display-message "$1"
      else
        printf '%s\n' "$1" >&2
      fi
    }

    resolve_path() {
      local query="$1"
      local path=""
      local -a terms=()

      if [[ -z "$query" ]]; then
        display_error 'zoxide query must not be empty'
        return 1
      fi

      if [[ -d "$query" ]]; then
        (cd -- "$query" && pwd -P)
        return
      fi

      read -r -a terms <<< "$query"

      if ! path="$(zoxide query -- "''${terms[@]}" 2>/dev/null)"; then
        display_error "No zoxide match for: $query"
        return 1
      fi

      [[ -d "$path" ]] || {
        display_error "Resolved path is not a directory: $path"
        return 1
      }

      (cd -- "$path" && pwd -P)
    }

    default_session_name() {
      local base
      base="$(basename -- "$1")"
      [[ -n "$base" && "$base" != / ]] || base="root"
      base="''${base//:/_}"
      base="$(printf '%s' "$base" | sed -E 's/^([^[:alpha:]]*)([[:lower:]])/\1\U\2/')"
      printf '%s\n' "$base"
    }

    query="''${1:-}"
    path="$(resolve_path "$query")" || exit 1
    default_name="$(default_session_name "$path")"

    tmux set-option -gq @tmux-zoxide-path "$path"
    tmux command-prompt -I "$default_name" -p "session name:" \
      "run-shell -b \"exec '${tmuxZoxideSessionCreate}' \\\"%%%\\\"\""
  '';
  tmuxPersistence = pkgs.writeShellScript "tmux-persistence" ''
    set -euo pipefail

    export PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.tmux ]}:$PATH"

    server_pid="$(tmux display-message -p '#{pid}')"
    state_dir="''${XDG_RUNTIME_DIR:-/tmp}/tmux-persistence-''${UID:-$(id -u)}"
    pid_file="$state_dir/$server_pid.pid"

    mkdir -p "$state_dir"

    if [[ -f "$pid_file" ]]; then
      old_pid="$(cat "$pid_file" 2>/dev/null || true)"
      if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
        exit 0
      fi
    fi

    printf '%s\n' "$$" > "$pid_file"
    trap 'rm -f "$pid_file"' EXIT

    resurrect_dir="${config.home.homeDirectory}/.tmux/resurrect"
    restore_script="${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/restore.sh"
    save_script="${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/save.sh"

    sleep 1
    if [[ -e "$resurrect_dir/last" ]]; then
      "$restore_script" >/dev/null 2>&1 || true
    fi

    while tmux info >/dev/null 2>&1; do
      now="$(date +%s)"
      sleep_for="$((60 - (now % 60)))"
      [[ "$sleep_for" -gt 0 ]] || sleep_for=60
      sleep "$sleep_for"

      tmux info >/dev/null 2>&1 || exit 0
      "$save_script" quiet >/dev/null 2>&1 || true
    done
  '';

in
{
  programs.tmux = {
    enable = true;
    clock24 = true;

    # Plugins via Nix (no TPM)
    plugins = with pkgs.tmuxPlugins; [
      sensible
      resurrect
    ];

    extraConfig = ''
      set -g default-shell "${pkgs.zsh}/bin/zsh"
      set -g @tmux-clipboard-command "${tmuxClipboardCommand}"
      set -g @tmux-zoxide-session "${tmuxZoxideSession}"
      set -g @resurrect-dir "${config.home.homeDirectory}/.tmux/resurrect"
      set -g @resurrect-capture-pane-contents "on"
      run-shell -b "${tmuxPersistence}"
      source-file "${config.xdg.configHome}/tmux/dotfiles.conf"
    '';
  };

  xdg.configFile."tmux/dotfiles.conf".source = dot "tmux/tmux.conf";

  home.file.".tmux.conf".text = ''
    source-file "${config.xdg.configHome}/tmux/tmux.conf"
  '';
}
