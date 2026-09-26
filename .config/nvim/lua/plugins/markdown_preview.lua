return {
    "iamcco/markdown-preview.nvim",
    enabled = require("config.profile").gui,
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    keys = {
        {
            "<localleader>mm",
            "<Plug>MarkdownPreview",
            ft = "markdown",
            desc = "Start Markdown preview",
        },
        {
            "<localleader>ms",
            "<Plug>MarkdownPreviewStop",
            ft = "markdown",
            desc = "Stop Markdown preview",
        },
        {
            "<localleader>mt",
            "<Plug>MarkdownPreviewToggle",
            ft = "markdown",
            desc = "Toggle Markdown preview",
        },
    },
    build = function()
        require("lazy").load({ plugins = { "markdown-preview.nvim" } })
        vim.fn["mkdp#util#install"]()
    end,
}
