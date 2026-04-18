{ ... }:

{
  # Intentionally no Wayland compositor/status bar services for CLI profile.

  # CLI environments often open bash by default; hand off to login zsh.
  programs.bash = {
    enable = true;
    initExtra = ''
      if [[ $- == *i* ]] && command -v zsh >/dev/null 2>&1; then
        if [[ -n "$IN_NIX_SHELL" ]]; then
          # Preserve nix-shell PATH when zsh starts and reads /etc/zshenv.
          export __NIXOS_SET_ENVIRONMENT_DONE=1
        fi
        exec zsh -l
      fi
    '';
  };
}
