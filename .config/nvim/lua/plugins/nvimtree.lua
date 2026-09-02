return {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    opts = {},
    keys = {
        { "<leader>o", "<Cmd>NvimTreeFocus<CR>", desc = "Focus file tree" },
    },
}
