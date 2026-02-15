local wezterm = require 'wezterm'

return {
  font = wezterm.font("JetBrains Mono"),
  font_size = 14.0,

  colors = {
    cursor_bg = "#009393",
    foreground = "#1a1a1a",
    background = "#ffffff",
  },

  enable_tab_bar = false,
  window_background_opacity = 0.2,
  text_background_opacity = 1.0,
  enable_kitty_keyboard = true,
  debug_key_events = true
}
