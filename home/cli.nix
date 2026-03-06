{ ... }:

{
  # Intentionally no Wayland compositor/status bar services for CLI profile.

  # CLI environments often open bash by default; hand off to login zsh.
  programs.bash = {
    enable = true;
    initExtra = ''
      if [[ $- == *i* ]] && command -v zsh >/dev/null 2>&1; then
        exec zsh -l
      fi
    '';
  };
}
