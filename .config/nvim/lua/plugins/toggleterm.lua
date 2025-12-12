return {
    {
        "akinsho/toggleterm.nvim",
        version = "*",

        opts = {
            direction = "horizontal",
            size = function(term)
                if term.direction == "horizontal" then
                    return math.floor(vim.o.lines * 0.25)
                end
            end,
        },

        config = function(_, opts)
            require("toggleterm").setup(opts)

            vim.keymap.set("n", "<leader>t", function()
                vim.cmd(vim.v.count1 .. "ToggleTerm")
            end)

        end,
    },
}

