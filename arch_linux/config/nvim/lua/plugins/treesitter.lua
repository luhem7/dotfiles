return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      -- Enable treesitter highlighting for supported filetypes
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "*",
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end,
    -- To install parsers, run once manually:
    -- :TSInstall html css javascript typescript tsx json python rust toml lua bash markdown yaml
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    opts = {},
  },
  {
    "norcalli/nvim-colorizer.lua",
    opts = {},
  },
  {
    "HiPhish/rainbow-delimiters.nvim",
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {},
  },
}
