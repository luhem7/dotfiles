return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      -- Install parsers (runs async, only installs missing ones)
      local parsers = {
        -- Web
        "html", "css", "javascript", "typescript", "tsx", "json",
        -- Python
        "python",
        -- Rust
        "rust", "toml",
        -- Extras
        "lua", "bash", "markdown", "yaml",
      }
      vim.cmd("TSInstall " .. table.concat(parsers, " "))
    end,
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
