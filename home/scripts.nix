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
  mkPythonScript = name: runtimeInputs:
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text = ''
        exec ${lib.getExe pkgs.python3} "${scriptsDir}/${name}" "$@"
      '';
    };

  commonScripts = rec {
    claude-usage = mkBashScript "claude-usage" [ pkgs.coreutils pkgs.curl pkgs.jq ];
    cli-bootstrap = mkBashScript "cli-bootstrap" [ pkgs.coreutils pkgs.curl pkgs.nix ];
    codex-usage = mkBashScript "codex-usage" [ pkgs.coreutils pkgs.curl pkgs.jq ];
    envdiff = mkBashScript "envdiff" [ pkgs.coreutils pkgs.diffutils pkgs.git pkgs.gnused ];
    get = mkBashScript "get" [ pkgs.coreutils pkgs.fd pkgs.fzf pkgs.rsync ];
    hf = mkBashScript "hf" [ pkgs.coreutils pkgs.fzf pkgs.gnugrep pkgs.gnused yank ];
    run = mkBashScript "run" [ pkgs.bash ];
    sendToMe = mkBashScript "sendToMe" [ pkgs.coreutils pkgs.curl pkgs.zip ];
    sesh = mkBashScript "sesh" [ pkgs.coreutils pkgs.tmux ];
    switch = mkBashScript "switch" [ pkgs.coreutils pkgs.nh pkgs.nix ];
    template = mkBashScript "template" [ pkgs.coreutils pkgs.direnv pkgs.git pkgs.nix ];
    view = mkBashScript "view" (
      [ pkgs.coreutils ]
      ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.xdg-utils ]
    );
    yank = mkBashScript "yank" (
      [ pkgs.coreutils ]
      ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.wl-clipboard pkgs.xclip ]
    );
  };

  linuxScripts = lib.optionalAttrs pkgs.stdenv.isLinux {
    drives = mkPythonScript "drives" [
      pkgs.coreutils
      pkgs.python3
      pkgs.smartmontools
      pkgs.util-linux
    ];
    screenshot = mkBashScript "screenshot" [
      pkgs.coreutils
      pkgs.grim
      pkgs.libnotify
      pkgs.slurp
      pkgs.wl-clipboard
    ];
  };
in
commonScripts // linuxScripts
