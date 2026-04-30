{ config, pkgs, ... }:

let
  scriptsDir = "${config.home.homeDirectory}/nix/scripts";
  tmuxClipboardCommand = pkgs.writeShellScript "tmux-clipboard" ''
    exec "${scriptsDir}/yank"
  '';
  tmuxEasyMotion = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "easy-motion";
    version = "unstable-2025-07-11";
    src = pkgs.fetchFromGitHub {
      owner = "IngoMeyer441";
      repo = "tmux-easy-motion";
      rev = "8dfe8aee14c938ec170b3f98ca341055cc960d06";
      hash = "sha256-Nxo8fWwgX79CrhUrHhfv8+mz3aUvPAbGmQkY34PQzKo=";
    };
    postInstall = ''
      patchShebangs "$target"
      sed -i 's|/bin/nop|${pkgs.coreutils}/bin/true|g' "$target/scripts/helpers.sh"
    '';
  };
in
{
  programs.tmux = {
    enable = true;
    clock24 = true;

    # Plugins via Nix (no TPM)
    plugins = with pkgs.tmuxPlugins; [
      sensible
      tmuxEasyMotion
      {
        plugin = dracula;
        extraConfig = ''
          set -g @dracula-colors "custom_bg #AFCCAF"
          set -g @dracula-show-flags true
          set -g @dracula-plugins "cpu-usage ram-usage"
          set -g @dracula-cpu-usage-colors "custom_bg"
          set -g @dracula-ram-usage-colors "custom_bg"
        '';
      }
    ];

    extraConfig = ''
      set -g @tmux-clipboard-command "${tmuxClipboardCommand}"
      set -g clock-mode-style 24
      set -g @easy-motion-dim-style "fg=#888888"
      set -g @easy-motion-highlight-style "fg=#0074b1,bold"
      set -g @easy-motion-highlight-2-first-style "fg=#009393,bold"
      set -g @easy-motion-highlight-2-second-style "fg=#008080,bold"
    '' + builtins.readFile ../dotfiles/.config/tmux/tmux.conf;
  };

  home.file.".tmux.conf".text = ''
    source-file "${config.xdg.configHome}/tmux/tmux.conf"
  '';
}
