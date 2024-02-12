local wezterm = require 'wezterm'
local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end

local launch_menu = {}

config.window_background_opacity = 0.95
config.color_scheme = "Wombat"

wezterm.log_info('triple = ' .. wezterm.target_triple)

if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
  local pwsh = wezterm.home_dir ..
      '\\AppData\\Local\\Microsoft\\WindowsApps\\Microsoft.PowerShell_8wekyb3d8bbwe\\pwsh.exe'
  wezterm.log_info('pwsh = ' .. pwsh)
  table.insert(launch_menu, {
    label = 'PowerShell',
    args = { pwsh }
  })

  config.default_prog = { pwsh }
end

config.launch_menu = launch_menu

-- A helper function for my fallback fonts
local function font_with_fallback(name, params)
  local names = { name, "Noto Color Emoji", "Symbols Nerd Font" }
  return wezterm.font_with_fallback(names, params)
end

config.harfbuzz_features = { "liga=0" }
config.font_size = 11.0
config.font = font_with_fallback("Berkeley Mono", { weight = "Medium" })
config.font_rules = {
  -- Select a fancy italic font for italic text
  {
    italic = true,
    font = font_with_fallback("Berkeley Mono", { weight = "Medium", italic = true }),
  },

  -- Similarly, a fancy bold+italic font
  {
    italic = true,
    intensity = "Bold",
    font = font_with_fallback("Berkeley Mono", { weight = "Black", italic = true }),
  },

  -- Make regular bold text a different color to make it stand out even more
  {
    intensity = "Bold",
    font = font_with_fallback("Berkeley Mono", { weight = "Black", foreground = "tomato" }),
  },

  -- For half-intensity text, use a lighter weight font
  {
    intensity = "Half",
    font = font_with_fallback("Berkeley Mono", { weight = "Light" }),
  },
}

return config
