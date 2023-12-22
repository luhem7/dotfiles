-- Pull in the wezterm API
local wezterm = require 'wezterm'
local act = wezterm.action

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

config.keys = {
  -- paste from the clipboard
  { key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard' },

  -- paste from the primary selection
  { key = 'v', mods = 'CTRL', action = act.PasteFrom 'PrimarySelection' },
}

-- LOOK AND FEEL

config.audible_bell = "Disabled"

-- Font Test 01 {} [] ~- +=> iIlL1 oO08 9ghij
-- Ensure that ligatures work, and the zero should have a dot in it!
config.font = wezterm.font_with_fallback { 'JetBrainsMono Nerd Font', 'CodeNewRoman Nerd Font'}
config.font_size = 10
config.font_rules = {
  {
    intensity = 'Normal',
    italic = true,
    font = wezterm.font_with_fallback {
      family = 'JetBrainsMono Nerd Font',
      italic = true,
    },
  },
}


config.color_scheme = 'Tinacious Design (Dark)'

config.default_cursor_style = 'BlinkingBar'
config.cursor_thickness = "0.07cell"
config.cursor_blink_rate = 500

-- and finally, return the configuration to wezterm
return config