return {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
        require("lazy").load { plugins = { "markdown-preview.nvim" } }
        vim.fn["mkdp#util#install"]()
    end,
    config = function()
        vim.keymap.set("n", "<leader>mp", "<Plug>MarkdownPreview")
        vim.keymap.set("n", "<leader>ms", "<Plug>MarkdownPreviewStop")
        vim.keymap.set("n", "<leader>mt", "<Plug>MarkdownPreviewToggle")
    end,
}
