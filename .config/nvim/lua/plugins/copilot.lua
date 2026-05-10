return {
    "github/copilot.vim",
    cmd = "Copilot",            -- lazy-load when you run :Copilot ...
    event = "InsertEnter",      -- or load when entering insert mode
    init = function()
        vim.g.copilot_no_tab_map = true
    end,
    config = function()
        vim.keymap.set(
            "i",
            "<C-j>",
            'copilot#Accept("\\<CR>")'
        )
        vim.keymap.set(
            "i",
            "<C-l>",
            "<Plug>(copilot-accept-line)"
        )
    end,
}
