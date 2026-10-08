return {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    init = function()
        vim.g.mkdp_port = "8090"
        vim.g.mkdp_open_to_the_world = 0
        vim.g.mkdp_echo_preview_url = 1

        -- Remote sessions show the URL instead of opening a server-side browser.
        if not require("config.profile").gui or vim.env.SSH_CONNECTION or vim.env.SSH_TTY then
            vim.cmd([[
                function! DotfilesMarkdownPreview(url) abort
                    call mkdp#util#echo_url(a:url)
                endfunction
            ]])
            vim.g.mkdp_browserfunc = "DotfilesMarkdownPreview"
            vim.g.mkdp_echo_preview_url = 0
        end
    end,
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
