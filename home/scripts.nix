{ config, lib, pkgs }:

let
  scriptsDir = "${config.home.homeDirectory}/nix/scripts";
  mkBashScript = name: runtimeInputs:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text = ''
        exec ${lib.getExe pkgs.bash} "${scriptsDir}/${name}" "$@"
      '';
    };
  scripts = rec {
    claude-usage = mkBashScript "claude-usage" [ pkgs.coreutils pkgs.curl pkgs.jq ];
    cli-bootstrap = mkBashScript "cli-bootstrap" [ pkgs.coreutils pkgs.curl pkgs.nix ];
    codex-usage = mkBashScript "codex-usage" [ pkgs.coreutils pkgs.curl pkgs.jq ];
    envdiff = mkBashScript "envdiff" [ pkgs.coreutils pkgs.diffutils pkgs.git pkgs.gnused ];
    get = mkBashScript "get" [ pkgs.coreutils pkgs.fd pkgs.fzf pkgs.rsync ];
    hf = mkBashScript "hf" [ pkgs.coreutils pkgs.fzf pkgs.gnugrep pkgs.gnused yank ];
    run = mkBashScript "run" [ pkgs.bash ];
    switch = mkBashScript "switch" [ pkgs.coreutils pkgs.nh ];
    theme = mkBashScript "theme" (
      [ pkgs.coreutils pkgs.gnugrep pkgs.tmux ]
      ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.procps ]
    );
    template = mkBashScript "template" [ pkgs.coreutils pkgs.direnv pkgs.git pkgs.nix ];
    open = mkBashScript "open" (
      [ pkgs.coreutils ]
      ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.xdg-utils ]
    );
    yank = mkBashScript "yank" (
      [ pkgs.coreutils ]
      ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.wl-clipboard pkgs.xclip ]
    );
  };

in
scripts
