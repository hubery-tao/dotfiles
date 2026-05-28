return {
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = {
        "pyright",
        "ruff",
        "lua_ls",
        "clangd",
        "texlab",
        "marksman",
        "fortls"
      },
      automatic_enable = true,
    },
  },
}
