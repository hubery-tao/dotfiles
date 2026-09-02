return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        on_attach = function(bufnr)
            local gitsigns = require("gitsigns")

            -- ]c / [c are Vim's diff-mode hunk jumps; outside diff mode they do
            -- nothing, so hand them to gitsigns and let it delegate back when
            -- the buffer really is in a diff split.
            local function jump(direction)
                return function()
                    if vim.wo.diff then
                        vim.cmd.normal({ direction .. "c", bang = true })
                    else
                        gitsigns.nav_hunk(direction == "]" and "next" or "prev")
                    end
                end
            end

            vim.keymap.set("n", "]c", jump("]"), {
                buffer = bufnr,
                desc = "Next git hunk",
            })
            vim.keymap.set("n", "[c", jump("["), {
                buffer = bufnr,
                desc = "Previous git hunk",
            })
        end,
    },
}
