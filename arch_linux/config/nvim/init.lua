vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.termguicolors = true

require("config.lazy")

vim.opt.number = true
vim.opt.relativenumber = true

-- Indentation: tabs, 4 spaces wide
vim.opt.expandtab = false
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4

-- Keybindings
vim.keymap.set('n', '<leader>rs', ':source $MYVIMRC | echo "Config reloaded!"<CR>', { desc = 'Reload System Config' })
