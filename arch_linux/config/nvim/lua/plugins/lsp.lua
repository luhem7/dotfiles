return {
  {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp" },
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- Advertise blink.cmp's completion capabilities to every server.
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      -- lua_ls: recognize the `vim` global so editing nvim config is warning-free.
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
          },
        },
      })

      -- bashls only attaches to `sh` by default; also drive it on zsh/bash files.
      vim.lsp.config("bashls", {
        filetypes = { "sh", "bash", "zsh" },
      })

      -- Only enable servers whose binary is actually installed, so a machine
      -- missing some servers (e.g. a fresh macOS box) stays error-free.
      local want = { "lua_ls", "rust_analyzer", "pyright", "ts_ls", "html", "cssls", "jsonls", "bashls" }
      local enabled = {}
      for _, name in ipairs(want) do
        local cfg = vim.lsp.config[name]
        local cmd = cfg and cfg.cmd
        local exe = type(cmd) == "table" and cmd[1] or nil
        -- Enable if the cmd is runnable, or if we can't introspect it (cmd is a function).
        if exe == nil or vim.fn.executable(exe) == 1 then
          table.insert(enabled, name)
        end
      end
      vim.lsp.enable(enabled)

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = args.buf, desc = "Go to definition" })
        end,
      })
    end,
  },
}
