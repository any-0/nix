{ config, pkgs, lib, ... }:

let
  npmGlobalDir = "${config.home.homeDirectory}/.local/share/npm-global";
  codexPlatform =
    {
      x86_64-linux = {
        package = "@openai/codex-linux-x64";
        target = "x86_64-unknown-linux-musl";
      };
      aarch64-darwin = {
        package = "@openai/codex-darwin-arm64";
        target = "aarch64-apple-darwin";
      };
    }.${pkgs.stdenv.hostPlatform.system};
  codexVendorDir = "${npmGlobalDir}/lib/node_modules/@openai/codex/node_modules/${codexPlatform.package}/vendor/${codexPlatform.target}";
in
{
  home.file.".npmrc".text = ''
    prefix=${npmGlobalDir}
  '';

  home.file.".local/bin/pi" = {
    executable = true;
    text = ''
      #!/bin/sh
      exec "${npmGlobalDir}/bin/pi" "$@"
    '';
  };

  home.file.".local/bin/codex" = {
    executable = true;
    text = ''
      #!/bin/sh
      export PATH="${codexVendorDir}/path:$PATH"
      exec "${codexVendorDir}/codex/codex" -c 'tui.keymap.editor.insert_newline=["ctrl-j","shift-enter","alt-enter"]' "$@"
    '';
  };

  home.activation.npmGlobalPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    npm_prefix="${npmGlobalDir}"
    npm_next="$npm_prefix.next"

    $DRY_RUN_CMD rm -rf "$npm_next"
    $DRY_RUN_CMD mkdir -p "$npm_next"
    $DRY_RUN_CMD env PATH="${pkgs.nodejs}/bin:$PATH" ${pkgs.nodejs}/bin/npm install --global --prefix "$npm_next" --no-audit --no-fund @earendil-works/pi-coding-agent@latest @openai/codex@latest
    $DRY_RUN_CMD rm -rf "$npm_prefix"
    $DRY_RUN_CMD mv "$npm_next" "$npm_prefix"
  '';

  home.packages = with pkgs; [
    nodejs
  ];
}
