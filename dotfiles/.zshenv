# Keep zsh startup files in XDG config.
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

# Load Home Manager session variables when available.
unset __HM_SESS_VARS_SOURCED
if [ -f "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh" ]; then
  . "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"
elif [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi
typeset -U path
