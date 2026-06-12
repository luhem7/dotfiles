vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.termguicolors = true

-- Disable unused language providers (silences :checkhealth warnings)
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0

require("config.lazy")

vim.opt.number = true
vim.opt.relativenumber = true

-- Indentation: tabs, 4 spaces wide
vim.opt.expandtab = false
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4

-- Share yank register with system clipboard when wl-clipboard is available
if vim.fn.executable("wl-copy") == 1 then
	vim.opt.clipboard = "unnamedplus"
end

-- Keybindings
vim.keymap.set('n', '<leader>rs', ':source $MYVIMRC | echo "Config reloaded!"<CR>', { desc = 'Reload System Config' })

-- Toggle comments via Neovim's built-in commenting (gc/gcc)
vim.keymap.set('n', '<leader>/', 'gcc', { remap = true, desc = 'Toggle comment' })
vim.keymap.set('x', '<leader>/', 'gc', { remap = true, desc = 'Toggle comment' })
