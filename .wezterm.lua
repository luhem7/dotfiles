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

config.audible_bell = "Disabled"

-- Font Test 01 {} [] ~- +=> iIlL1 oO08 9ghij
-- Huh, turns out that it uses JetBrains mono and nerd fonts by default!
config.font_size = 10

-- config.color_scheme = 'PaperColor Dark (base16)'
-- config.color_scheme = 'tokyonight'
-- config.color_scheme = 'Tinacious Design (Dark)'
-- config.color_scheme = 'tokyonight_night'
-- config.color_scheme = 'synthwave'
-- config.color_scheme = 'JetBrains Darcula'
-- config.color_scheme = 'atom'
-- config.color_scheme = 'ayu'
-- config.color_scheme = 'Ayu Dark (Gogh)'
-- config.color_scheme = 'Atom (Gogh)'
config.color_scheme = 'atom'

-- and finally, return the configuration to wezterm
return config