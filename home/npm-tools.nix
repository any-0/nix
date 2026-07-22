{ config, pkgs, lib, ... }:

let
  npmGlobalDir = "${config.home.homeDirectory}/.local/share/npm-global";
  npmPackages = [
    "@earendil-works/pi-coding-agent"
    "@openai/codex"
    "@anthropic-ai/claude-code"
  ];
  piRuntimePath = lib.makeBinPath (
    [ pkgs.nodejs ] ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.bubblewrap ]
  );
in
{
  home.file.".npmrc".text = ''
    prefix=${npmGlobalDir}
  '';

  home.file.".local/bin/pi" = {
    executable = true;
    text = ''
      #!/bin/sh
      export PATH="${piRuntimePath}:$PATH"
      exec "${npmGlobalDir}/bin/pi" "$@"
    '';
  };

  home.file.".local/bin/codex" = {
    executable = true;
    text = ''
      #!/bin/sh
      export PATH="${pkgs.nodejs}/bin:$PATH"
      exec "${npmGlobalDir}/bin/codex" \
        --sandbox danger-full-access \
        --ask-for-approval on-request \
        -c 'allow_login_shell=false' \
        -c 'tui.keymap.editor.insert_newline=["ctrl-j","shift-enter","alt-enter"]' \
        "$@"
    '';
  };

  home.file.".local/bin/claude" = {
    executable = true;
    text = ''
      #!/bin/sh
      export PATH="${pkgs.nodejs}/bin:$PATH"
      export CLAUDE_BASH_NO_LOGIN=1
      export DISABLE_AUTOUPDATER=1
      exec "${npmGlobalDir}/bin/claude" --dangerously-skip-permissions "$@"
    '';
  };

  home.activation.npmGlobalPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    npm_prefix="${npmGlobalDir}"
    npm_next="$npm_prefix.next"
    npm="${pkgs.nodejs}/bin/npm"
    node="${pkgs.nodejs}/bin/node"

    npm_packages=(${lib.escapeShellArgs npmPackages})

    npm_needs_install=0
    for pkg in "''${npm_packages[@]}"; do
      pkg_json="$npm_prefix/lib/node_modules/$pkg/package.json"
      if [[ ! -f "$pkg_json" ]]; then
        npm_needs_install=1
        break
      fi
      installed="$("$node" -p "require('$pkg_json').version" 2>/dev/null || true)"
      latest="$("$npm" view "$pkg" version 2>/dev/null || true)"
      # Registry unreachable: keep whatever is installed.
      [[ -n "$latest" ]] || continue
      if [[ "$installed" != "$latest" ]]; then
        npm_needs_install=1
        break
      fi
    done

    if [[ "$npm_needs_install" == 1 ]]; then
      $DRY_RUN_CMD rm -rf "$npm_next"
      $DRY_RUN_CMD mkdir -p "$npm_next"
      $DRY_RUN_CMD env PATH="${pkgs.nodejs}/bin:$PATH" "$npm" install --global --prefix "$npm_next" --no-audit --no-fund ${lib.escapeShellArgs (map (p: "${p}@latest") npmPackages)}
      $DRY_RUN_CMD rm -rf "$npm_prefix"
      $DRY_RUN_CMD mv "$npm_next" "$npm_prefix"
    else
      verboseEcho "npm global packages up to date; skipping install"
    fi

    completion_dir="$npm_prefix/share/zsh/site-functions"
    $DRY_RUN_CMD mkdir -p "$completion_dir"
    $DRY_RUN_CMD ${pkgs.runtimeShell} -c \
      'PATH="$1:$PATH" "$2" completion zsh > "$3"' \
      generate-codex-completion \
      "${pkgs.nodejs}/bin" \
      "$npm_prefix/bin/codex" \
      "$completion_dir/_codex"
  '';

  home.packages = with pkgs; [
    nodejs
  ];
}
