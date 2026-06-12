return {
  {
    "saghen/blink.cmp",
    -- friendly-snippets supplies a large set of ready-made snippets.
    dependencies = { "rafamadriz/friendly-snippets" },
    -- Pin to the stable V1 line. V2 lives on `main` and is still churning.
    version = "1.*",
    -- Compile the Rust fuzzy matcher locally (rust toolchain installed system-wide).
    build = "cargo build --release",
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- 'super-tab': VSCode-style, <Tab> accepts the current selection.
      -- <C-space> open menu/docs, <C-n>/<C-p> navigate, <C-e> hide.
      keymap = { preset = "super-tab" },
      appearance = {
        -- JetBrainsMono Nerd Font is the system monospace font.
        nerd_font_variant = "mono",
      },
      -- Only show the docs popup when explicitly asked (<C-space>), keeps it calm.
      completion = { documentation = { auto_show = false } },
      sources = {
        -- LSP, file paths, snippets, and words from open buffers.
        default = { "lsp", "path", "snippets", "buffer" },
      },
      -- Use the Rust matcher; warn (don't error) if the binary isn't built yet.
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    -- Lets other plugin specs append to sources.default rather than overwrite it.
    opts_extend = { "sources.default" },
  },
}
