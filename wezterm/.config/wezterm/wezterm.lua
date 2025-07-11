local wezterm = require 'wezterm'
local config = {
  color_scheme = 'Wombat',
  front_end = 'WebGpu',
  webgpu_power_preference = 'HighPerformance',
  window_background_opacity = 0.8,
  win32_system_backdrop = 'Acrylic',
  -- freetype_load_target = 'HorizontalLcd',
  window_decorations = 'INTEGRATED_BUTTONS|RESIZE',
  max_fps = 240,
  window_padding = {
    top = 8, left = 8, bottom = 8, right = 8
  },
  command_palette_font_size = 12,
  command_palette_bg_color = '#394b70',
  command_palette_fg_color = '#828bb8',
  ui_key_cap_rendering = 'WindowsSymbols'
}
local launch_menu = {}

wezterm.log_info('triple = ' .. wezterm.target_triple)

if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
  local pwsh = 'C:\\Program Files\\PowerShell\\7\\pwsh.exe'
  table.insert(launch_menu, {
    label = 'PowerShell',
    args = { pwsh, '-NoLogo' }
  })

  config.default_prog = { pwsh, '-NoLogo' }
end

config.launch_menu = launch_menu

-- A helper function for my fallback fonts
local function font_with_fallback(name, params)
  local names = { name, 'Noto Color Emoji', 'Symbols Nerd Font' }
  return wezterm.font_with_fallback(names, params)
end

config.harfbuzz_features = { 'zero=1' }
config.font_size = 12.0
local font_family = 'GeistMono NF'
-- local font_family = 'Berkeley Mono'
-- local font_family = 'Ubuntu Mono'
-- config.font = font_with_fallback('Berkeley Mono', { weight = 'Medium' })
config.font = font_with_fallback(font_family, { weight = 'Medium' })
config.command_palette_font = config.font
config.font_rules = {
  -- Select a fancy italic font for italic text
  {
    italic = true,
    font = font_with_fallback(font_family, { weight = 'Medium', italic = true }),
  },

  -- Similarly, a fancy bold+italic font
  {
    italic = true,
    intensity = 'Bold',
    font = font_with_fallback(font_family, { weight = 'Black', italic = true }),
  },

  -- Make regular bold text a different color to make it stand out even more
  {
    intensity = 'Bold',
    font = font_with_fallback(font_family, { weight = 'Black', foreground = 'tomato' }),
  },

  -- For half-intensity text, use a lighter weight font
  {
    intensity = 'Half',
    font = font_with_fallback(font_family, { weight = 'Light' }),
  },
}

return config
