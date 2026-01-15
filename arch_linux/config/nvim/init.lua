vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.termguicolors = true

require("config.lazy")

vim.opt.number = true
vim.opt.relativenumber = true

-- Keybindings
vim.keymap.set('n', '<leader>rs', ':source $MYVIMRC | echo "Config reloaded!"<CR>', { desc = 'Reload System Config' })
