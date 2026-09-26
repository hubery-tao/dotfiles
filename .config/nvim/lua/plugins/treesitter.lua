return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        -- Only missing parsers are installed; updates run through lazy's build hook.
        require("nvim-treesitter").install({
            "c",
            "fortran",
            "lua",
            "markdown",
            "markdown_inline",
            "python",
            "vim",
            "vimdoc",
        })

        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("TreesitterHighlight", { clear = true }),
            callback = function(event)
                local max_filesize = 100 * 1024 -- 100 KB
                local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(event.buf))
                if ok and stats and stats.size > max_filesize then
                    return
                end

                -- Filetypes without an installed parser keep their normal highlighting.
                pcall(vim.treesitter.start, event.buf)
            end,
        })
    end,
}
