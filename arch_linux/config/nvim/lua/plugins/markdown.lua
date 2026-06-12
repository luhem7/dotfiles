return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    -- Lazy-load only when a markdown buffer is opened.
    ft = { "markdown" },
    -- nvim-web-devicons is the icon provider (already used elsewhere for code
    -- block language icons); treesitter supplies the markdown/latex parsers.
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      -- Mimic Obsidian's UI for callouts, checkboxes, and styling.
      preset = "obsidian",
      -- Render LaTeX math blocks/inline into unicode. Needs the `latex`
      -- treesitter parser plus a converter CLI (`latex2text` from pylatexenc).
      latex = {
        enabled = true,
        converter = "latex2text",
      },
      -- Smart modal view: pretty render in normal mode, and the line under the
      -- cursor drops back to raw markdown so it's easy to edit precisely.
      anti_conceal = {
        enabled = true,
      },
    },
    keys = {
      { "<leader>mt", "<cmd>RenderMarkdown toggle<cr>", desc = "Markdown toggle render", ft = "markdown" },
      { "<leader>mp", "<cmd>RenderMarkdown preview<cr>", desc = "Markdown side preview", ft = "markdown" },
      { "<leader>me", "<cmd>RenderMarkdown expand<cr>", desc = "Markdown expand reveal", ft = "markdown" },
      { "<leader>mc", "<cmd>RenderMarkdown contract<cr>", desc = "Markdown contract reveal", ft = "markdown" },
    },
  },
}
