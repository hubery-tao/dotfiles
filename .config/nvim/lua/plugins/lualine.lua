return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        local function filename_component()
            return {
                "filename",
                path = 1,
                symbols = {
                    modified = " ●",
                    readonly = " ",
                    unnamed = "[No Name]",
                    newfile = "[New]",
                },
            }
        end

        require("lualine").setup({
            options = {
                theme = "tinted",
                globalstatus = true,
                section_separators = { left = "", right = "" },
                component_separators = { left = "│", right = "│" },
                -- Panes that carry no file: a winbar here would only show a
                -- term:// or tree buffer name.
                disabled_filetypes = {
                    winbar = {
                        "NvimTree",
                        "toggleterm",
                        "codex",
                        "claude",
                    },
                },
            },
            tabline = {
                lualine_c = {
                    {
                        "buffers",
                        mode = 2,
                        use_mode_colors = true,
                        symbols = {
                            modified = " ●",
                            alternate_file = "",
                            directory = "",
                        },
                    },
                },
            },
            winbar = {
                lualine_c = { filename_component() },
            },
            inactive_winbar = {
                lualine_c = { filename_component() },
            },
        })
    end,
}
