local wezterm = require 'wezterm';

-- A helper function for my fallback fonts
local function font_with_fallback(name, params)
  local names = {name, "Noto Color Emoji", "Symbols Nerd Font"}
  return wezterm.font_with_fallback(names, params)
end

return {
  enable_tab_bar = true,
  window_background_opacity = 0.95,
  color_scheme = "Wombat",
  harfbuzz_features = {"liga=0"},
  font = font_with_fallback("MonoLisa", {weight="Medium"}),
  font_rules= {
    -- Select a fancy italic font for italic text
    {
      italic = true,
      font = font_with_fallback("MonoLisa", {weight="Medium", italic=true}),
    },

    -- Similarly, a fancy bold+italic font
    {
      italic = true,
      intensity = "Bold",
      font = font_with_fallback("MonoLisa", {weight="Black", italic=true}),
    },

    -- Make regular bold text a different color to make it stand out even more
    {
      intensity = "Bold",
      font = font_with_fallback("MonoLisa", {weight="Black", foreground="tomato"}),
    },

    -- For half-intensity text, use a lighter weight font
    {
      intensity = "Half",
      font = font_with_fallback("MonoLisa", {weight="Light"}),
    },
  },
}

