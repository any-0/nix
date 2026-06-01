{ config, pkgs, lib, ... }:

let
  npmGlobalDir = "${config.home.homeDirectory}/.local/share/npm-global";
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
      exec "${npmGlobalDir}/bin/codex" -c 'tui.keymap.editor.insert_newline=["ctrl-j","shift-enter","alt-enter"]' "$@"
    '';
  };

  home.file.".local/bin/claude" = {
    executable = true;
    text = ''
      #!/bin/sh
      export PATH="${pkgs.nodejs}/bin:$PATH"
      exec "${npmGlobalDir}/bin/claude" "$@"
    '';
  };

  home.activation.npmGlobalPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    npm_prefix="${npmGlobalDir}"
    npm_next="$npm_prefix.next"

    $DRY_RUN_CMD rm -rf "$npm_next"
    $DRY_RUN_CMD mkdir -p "$npm_next"
    $DRY_RUN_CMD env PATH="${pkgs.nodejs}/bin:$PATH" ${pkgs.nodejs}/bin/npm install --global --prefix "$npm_next" --no-audit --no-fund @earendil-works/pi-coding-agent@latest @openai/codex@latest @anthropic-ai/claude-code@latest
    $DRY_RUN_CMD rm -rf "$npm_prefix"
    $DRY_RUN_CMD mv "$npm_next" "$npm_prefix"
  '';

  home.packages = with pkgs; [
    nodejs
  ];
}
