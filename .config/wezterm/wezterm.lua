-- ~/.dotfiles/.config/wezterm/wezterm.lua
local wezterm = require("wezterm")

return {
  -- ✨ Font & Rendering
  font = wezterm.font_with_fallback({
    "JetBrainsMono Nerd Font",
    "CaskaydiaCove Nerd Font",
    "FiraCode Nerd Font",
  }),
  font_size = 12.5,
  line_height = 1.1,
  freetype_load_target = "Normal",
  freetype_render_target = "HorizontalLcd",

  -- 🌒 Color Scheme
  color_scheme = "Gruvbox dark, soft (base16)", -- Try: "Ayu Mirage", "Kanagawa", "Tokyo Night Storm"

  -- 🧱 UI / Chrome
  enable_tab_bar = false,
  window_decorations = "RESIZE",
  use_fancy_tab_bar = false,
  hide_mouse_cursor_when_typing = true,
  window_background_opacity = 0.95,
  macos_window_background_blur = 20,

  -- 🧊 Padding & Borders
  window_padding = {
    left = 10,
    right = 10,
    top = 6,
    bottom = 6,
  },

  -- 🚀 Performance & Behavior
  scrollback_lines = 5000,
  animation_fps = 60,
  max_fps = 120,
  adjust_window_size_when_changing_font_size = false,

  -- ⌨️ Keybindings (Minimal Override Example)
  keys = {
    {
      key = "Enter",
      mods = "ALT",
      action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
    },
    {
      key = "Enter",
      mods = "CTRL",
      action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
    },
  },
}
