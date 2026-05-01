{ config, pkgs, lib, ... }:

let
  npmGlobalDir = "${config.home.homeDirectory}/.local/share/npm-global";
in
{
  home.sessionVariables = {
    NPM_CONFIG_PREFIX = npmGlobalDir;
  };

  home.sessionPath = [
    "${npmGlobalDir}/bin"
  ];

  home.activation.npmGlobalPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    npm_prefix="${npmGlobalDir}"
    npm_next="$npm_prefix.next"

    $DRY_RUN_CMD rm -rf "$npm_next"
    $DRY_RUN_CMD mkdir -p "$npm_next"
    $DRY_RUN_CMD env PATH="${pkgs.nodejs}/bin:$PATH" ${pkgs.nodejs}/bin/npm install --global --prefix "$npm_next" --no-audit --no-fund @mariozechner/pi-coding-agent@latest @openai/codex@latest
    $DRY_RUN_CMD rm -rf "$npm_prefix"
    $DRY_RUN_CMD mv "$npm_next" "$npm_prefix"
  '';

  home.packages = with pkgs; [
    nodejs
  ];
}
