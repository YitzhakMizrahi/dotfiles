local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

-- Platform detection
local is_windows = wezterm.target_triple:find("windows") ~= nil
local is_macos = wezterm.target_triple:find("darwin") ~= nil
local is_linux = not is_windows and not is_macos

-- ── WSL Domain (Windows only) ──────────────────────────────────
if is_windows then
  config.default_domain = "WSL:Ubuntu-22.04"
end

-- ── Font & Rendering ───────────────────────────────────────────
config.font = wezterm.font_with_fallback({
  {
    family = is_windows and "JetBrainsMono NFM" or "JetBrainsMono Nerd Font",
    weight = "Medium",
  },
  "CaskaydiaCove Nerd Font",
  "FiraCode Nerd Font",
})
config.font_size = 12.5
config.line_height = 1.1

if is_linux then
  config.freetype_load_target = "Normal"
  config.freetype_render_target = "HorizontalLcd"
end

-- ── Color Scheme ───────────────────────────────────────────────
config.color_scheme = "Gruvbox dark, soft (base16)"

-- ── Cursor ─────────────────────────────────────────────────────
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 500
config.cursor_thickness = 2

-- ── UI / Chrome ────────────────────────────────────────────────
config.window_decorations = "RESIZE"
config.use_fancy_tab_bar = false
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_max_width = 25
config.hide_mouse_cursor_when_typing = true
config.window_background_opacity = 0.95

if is_macos then
  config.macos_window_background_blur = 20
end

-- ── Padding ────────────────────────────────────────────────────
config.window_padding = { left = 10, right = 10, top = 6, bottom = 6 }

-- ── Performance ────────────────────────────────────────────────
config.scrollback_lines = 10000
config.audible_bell = "Disabled"
config.animation_fps = 60
config.max_fps = 120
config.adjust_window_size_when_changing_font_size = false
config.bold_brightens_ansi_colors = "No"
config.check_for_updates = false

-- ── Inactive Pane Dimming ──────────────────────────────────────
config.inactive_pane_hsb = { saturation = 0.8, brightness = 0.7 }

-- ── Mouse Bindings ─────────────────────────────────────────────
config.mouse_bindings = {
  {
    event = { Drag = { streak = 1, button = "Left" } },
    mods = "CTRL|SHIFT",
    action = act.StartWindowDrag,
  },
}

-- ── Tab Title Formatting ───────────────────────────────────────
local tab_icons = {
  ["WSL:Ubuntu-22.04"] = " Ubuntu",
  ["pwsh.exe"] = " PS",
  ["powershell.exe"] = " PS",
}

wezterm.on("format-tab-title", function(tab)
  local title = tab.active_pane.title or "shell"
  local domain = tab.active_pane.domain_name or ""
  local icon = tab_icons[domain] or tab_icons[title]
  if not icon then
    if title:find("zsh") then
      icon = "❯"
    elseif title:find("bash") then
      icon = "$"
    else
      icon = "○"
    end
  end
  return { { Text = " " .. icon .. " " .. (tab.tab_index + 1) .. " " } }
end)

-- ── Launch Menu ────────────────────────────────────────────────
config.launch_menu = {}
if is_windows then
  table.insert(config.launch_menu, {
    label = " PowerShell",
    args = { "pwsh.exe" },
    domain = { DomainName = "local" },
  })
  table.insert(config.launch_menu, {
    label = " Ubuntu (WSL)",
    domain = { DomainName = "WSL:Ubuntu-22.04" },
  })
end
table.insert(config.launch_menu, { label = "❯ Zsh", args = { "zsh", "-l" } })
table.insert(config.launch_menu, { label = "$ Bash", args = { "bash", "-l" } })

-- ── Keybindings ────────────────────────────────────────────────
config.keys = {
  -- Splits (h = horizontal line → pane below, v = vertical line → pane right)
  { key = "h", mods = "CTRL|ALT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "v", mods = "CTRL|ALT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = true }) },

  -- Pane navigation
  { key = "LeftArrow",  mods = "ALT", action = act.ActivatePaneDirection("Left") },
  { key = "RightArrow", mods = "ALT", action = act.ActivatePaneDirection("Right") },
  { key = "UpArrow",    mods = "ALT", action = act.ActivatePaneDirection("Up") },
  { key = "DownArrow",  mods = "ALT", action = act.ActivatePaneDirection("Down") },

  -- Pane resize
  { key = "LeftArrow",  mods = "CTRL|ALT", action = act.AdjustPaneSize({ "Left", 5 }) },
  { key = "RightArrow", mods = "CTRL|ALT", action = act.AdjustPaneSize({ "Right", 5 }) },
  { key = "UpArrow",    mods = "CTRL|ALT", action = act.AdjustPaneSize({ "Up", 5 }) },
  { key = "DownArrow",  mods = "CTRL|ALT", action = act.AdjustPaneSize({ "Down", 5 }) },

  -- Launcher, quick select, copy mode, search
  { key = "L",     mods = "CTRL|SHIFT", action = act.ShowLauncher },
  { key = "Space", mods = "CTRL|SHIFT", action = act.QuickSelect },
  { key = "x",     mods = "CTRL|SHIFT", action = act.ActivateCopyMode },
  { key = "f",     mods = "CTRL|SHIFT", action = act.Search("CurrentSelectionOrEmptyString") },
}

return config
