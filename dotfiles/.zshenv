# Keep zsh startup files in XDG config.
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

# Load Home Manager session variables when available.
if [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi
