return {
  {
    "junegunn/fzf.vim",
    dependencies = { "junegunn/fzf" },
    keys = {
      { "<leader>ff", "<cmd>Files<cr>", desc = "fzf Find files" },
      { "<leader>fg", "<cmd>Rg<cr>", desc = "fzf Ripgrep" },
      { "<leader>fb", "<cmd>Buffers<cr>", desc = "fzf Buffers" },
      { "<leader>fc", "<cmd>History:<cr>", desc = "fzf Command History" },
    },
  },
}
