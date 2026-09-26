return {
    "lervag/vimtex",
    -- VimTeX already loads its editing features through filetype plugins.
    lazy = false,
    init = function()
        if not require("config.profile").gui then
            vim.g.vimtex_view_enabled = 0
            vim.g.vimtex_view_automatic = 0
            return
        end

        if vim.fn.has("macunix") == 1 then
            vim.g.vimtex_view_method = "skim"
        elseif vim.fn.executable("zathura") == 1 then
            vim.g.vimtex_view_method = "zathura"
        end
    end,
}
