return {
    "lervag/vimtex",
    lazy = false,
    init = function()
        if vim.fn.has("macunix") == 1 then
            vim.g.vimtex_view_method = "skim"
        elseif vim.fn.executable("zathura") == 1 then
            vim.g.vimtex_view_method = "zathura"
        end
    end,
}
