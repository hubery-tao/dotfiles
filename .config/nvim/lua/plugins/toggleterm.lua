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

            local Terminal = require("toggleterm.terminal").Terminal
            local terms = {}

            local function focus_or_open(count)
                count = count or vim.v.count1

                -- Create the Terminal object (by number) the first time we use it
                if not terms[count] then
                    terms[count] = Terminal:new({
                        count = count, -- terminal number: 1 => toggleterm#1, 2 => toggleterm#2, etc.
                        direction = opts.direction or "horizontal",
                    })
                end

                local term = terms[count]
                local bufnr = term.bufnr

                -- If this terminal buffer is already visible in a window, just jump to that window.
                -- This avoids opening another split that shows the same terminal.
                if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
                    local wins = vim.fn.win_findbuf(bufnr) -- list of window IDs displaying this buffer
                    if wins and #wins > 0 then
                        vim.api.nvim_set_current_win(wins[1])
                        return
                    end
                end

                -- Otherwise open it (this is what creates the split/window if it isn't visible yet)
                term:open()
            end

            -- Count-aware mapping:
            -- <leader>t   -> focuses/opens terminal 1
            -- 2<leader>t  -> focuses/opens terminal 2
            vim.keymap.set("n", "<leader>t", function()
                focus_or_open(vim.v.count1)
            end)

        end,
    },
}

