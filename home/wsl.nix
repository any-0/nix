{ ... }:

{
  # Intentionally no Wayland compositor/status bar services for WSL.

  # WSL opens bash by default on many distros; hand off to login zsh.
  programs.bash = {
    enable = true;
    initExtra = ''
      if [[ -n "''${WSL_DISTRO_NAME:-}" ]] && [[ $- == *i* ]] && command -v zsh >/dev/null 2>&1; then
        exec zsh -l
      fi
    '';
  };
}
