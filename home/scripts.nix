{ config, lib, pkgs }:

let
  scriptsDir = "${config.home.homeDirectory}/nix/scripts";
  mkBashScript = subdir: name: runtimeInputs:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text = ''
        exec ${lib.getExe pkgs.bash} "${scriptsDir}/${subdir}/${name}" "$@"
      '';
    };
  mkCli = mkBashScript "cli";
  mkInternal = mkBashScript "internal";
  scripts = rec {
    claude-usage = mkInternal "claude-usage" [ pkgs.coreutils pkgs.curl pkgs.jq ];
    cli-bootstrap = mkCli "cli-bootstrap" [ pkgs.coreutils pkgs.curl pkgs.nix ];
    codex-usage = mkInternal "codex-usage" [ pkgs.coreutils pkgs.curl pkgs.jq ];
    get = mkCli "get" [ pkgs.coreutils pkgs.fd pkgs.fzf pkgs.rsync ];
    hf = mkCli "hf" [ pkgs.coreutils pkgs.fzf pkgs.gnugrep pkgs.gnused yank ];
    run = mkCli "run" [ pkgs.bash ];
    switch = mkCli "switch" [ pkgs.coreutils pkgs.nh ];
    theme = mkCli "theme" (
      [ pkgs.coreutils pkgs.gnugrep pkgs.tmux ]
      ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.procps ]
    );
    template = mkCli "template" [ pkgs.coreutils pkgs.direnv pkgs.nix ];
    open = mkCli "open" (
      [ pkgs.coreutils ]
      ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.xdg-utils ]
    );
    yank = mkCli "yank" (
      [ pkgs.coreutils ]
      ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.wl-clipboard pkgs.xclip ]
    );
  };

in
scripts
