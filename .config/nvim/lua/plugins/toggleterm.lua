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
            -- nvim-tree replaces a directory argument with NvimTree_1 during
            -- VimEnter, so remember this before that happens.
            local started_with_directory = vim.fn.argc() == 1
                and vim.fn.isdirectory(vim.fn.argv(0)) == 1

            -- Keep Codex outside ToggleTerm's terminal registry. ToggleTerm
            -- deliberately opens a new terminal relative to an existing one;
            -- registering Codex there makes the right-hand Codex pane and the
            -- horizontal shell pane resize each other whenever either reopens.
            local function codex_width()
                return math.floor(vim.o.columns * 0.35)
            end

            local codex = {
                bufnr = nil,
                window = nil,
                job_id = nil,
            }

            local function visible_codex_window()
                if not codex.bufnr or not vim.api.nvim_buf_is_valid(codex.bufnr) then
                    return nil
                end

                local wins = vim.fn.win_findbuf(codex.bufnr)
                for _, win in ipairs(wins) do
                    if vim.api.nvim_win_is_valid(win)
                        and vim.api.nvim_win_get_tabpage(win) == vim.api.nvim_get_current_tabpage()
                    then
                        codex.window = win
                        return win
                    end
                end
            end

            local function snapshot_terminal_heights()
                local heights = {}
                for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    if vim.bo[buf].filetype == "toggleterm"
                        and vim.api.nvim_win_get_config(win).relative == ""
                    then
                        heights[win] = vim.api.nvim_win_get_height(win)
                    end
                end
                return heights
            end

            local function restore_terminal_heights(heights)
                for win, height in pairs(heights) do
                    if vim.api.nvim_win_is_valid(win) then
                        pcall(vim.api.nvim_win_set_height, win, height)
                    end
                end
            end

            local function place_codex_right(win)
                if not win or not vim.api.nvim_win_is_valid(win) then
                    return
                end

                vim.api.nvim_win_call(win, function()
                    -- A vsplit made from the editor may initially occupy only
                    -- its row. Move it to the outer right edge so it spans the
                    -- editor and horizontal terminal rows.
                    vim.cmd("wincmd L")
                end)
                vim.api.nvim_win_set_width(win, codex_width())
                vim.wo[win].winfixwidth = true
                vim.wo[win].winbar = " Codex"
                codex.window = win
            end

            local function find_editor_window()
                for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    if vim.bo[buf].buftype ~= "terminal"
                        and vim.bo[buf].filetype ~= "NvimTree"
                        and vim.api.nvim_win_get_config(win).relative == ""
                    then
                        return win
                    end
                end
            end

            local function focus_or_open_codex()
                local open_win = visible_codex_window()
                if open_win then
                    vim.api.nvim_set_current_win(open_win)
                    return
                end

                local editor_win = find_editor_window()
                if editor_win then
                    vim.api.nvim_set_current_win(editor_win)
                end

                local terminal_heights = snapshot_terminal_heights()
                vim.cmd("botright vsplit")
                local win = vim.api.nvim_get_current_win()

                if codex.bufnr and vim.api.nvim_buf_is_valid(codex.bufnr) then
                    vim.api.nvim_win_set_buf(win, codex.bufnr)
                else
                    local bufnr = vim.api.nvim_create_buf(false, true)
                    codex.bufnr = bufnr
                    vim.api.nvim_win_set_buf(win, bufnr)
                    vim.bo[bufnr].bufhidden = "hide"
                    vim.bo[bufnr].buflisted = false
                    vim.bo[bufnr].swapfile = false

                    codex.job_id = vim.fn.jobstart({ "codex" }, { term = true })
                    vim.bo[bufnr].filetype = "codex"

                    vim.api.nvim_create_autocmd("TermClose", {
                        buffer = bufnr,
                        once = true,
                        callback = function()
                            vim.schedule(function()
                                for _, codex_win in ipairs(vim.fn.win_findbuf(bufnr)) do
                                    if vim.api.nvim_win_is_valid(codex_win)
                                        and #vim.api.nvim_tabpage_list_wins(0) > 1
                                    then
                                        vim.api.nvim_win_close(codex_win, true)
                                    end
                                end

                                if vim.api.nvim_buf_is_valid(bufnr) then
                                    vim.api.nvim_buf_delete(bufnr, { force = true })
                                end
                                if codex.bufnr == bufnr then
                                    codex.bufnr = nil
                                    codex.window = nil
                                    codex.job_id = nil
                                end
                            end)
                        end,
                    })
                end

                place_codex_right(win)
                restore_terminal_heights(terminal_heights)
                vim.cmd("startinsert")
            end

            local function leave_sidebar_before_opening_terminal()
                local current_buf = vim.api.nvim_get_current_buf()
                local current_ft = vim.bo[current_buf].filetype
                if current_buf ~= codex.bufnr and current_ft ~= "NvimTree" then
                    return
                end

                for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    if vim.bo[buf].buftype ~= "terminal"
                        and vim.bo[buf].filetype ~= "NvimTree"
                        and vim.api.nvim_win_get_config(win).relative == ""
                    then
                        vim.api.nvim_set_current_win(win)
                        return
                    end
                end
            end

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
                leave_sidebar_before_opening_terminal()
                term:open()

                -- Opening the first ToggleTerm uses a full-width bottom split.
                -- Put an already-visible native Codex pane back on the outer
                -- right, then restore the height selected for the shell pane.
                local codex_win = visible_codex_window()
                if codex_win then
                    local terminal_heights = snapshot_terminal_heights()
                    place_codex_right(codex_win)
                    restore_terminal_heights(terminal_heights)
                    vim.api.nvim_set_current_win(term.window)
                end
            end

            -- Count-aware mapping:
            -- <leader>t   -> focuses/opens terminal 1
            -- 2<leader>t  -> focuses/opens terminal 2
            vim.keymap.set("n", "<leader>t", function()
                focus_or_open(vim.v.count1)
            end, { desc = "Focus/open terminal" })

            -- In terminal mode, use <C-Space> first to return to Normal mode.
            vim.keymap.set("n", "<leader>c", focus_or_open_codex, {
                desc = "Focus/open Codex workspace",
            })

            vim.api.nvim_create_user_command("Codex", focus_or_open_codex, {
                desc = "Focus/open the right-side Codex workspace",
            })

            -- `nvim .` used to start with only the tree window, which meant a
            -- file had to be opened before the terminal layout could be built.
            -- Give directory sessions an empty editor target and open the
            -- default terminal automatically. Codex stays opt-in via <leader>c.
            if started_with_directory then
                vim.api.nvim_create_autocmd("VimEnter", {
                    once = true,
                    callback = function()
                        vim.schedule(function()
                            -- Do not start interactive jobs for headless runs.
                            if #vim.api.nvim_list_uis() == 0 then
                                return
                            end

                            local editor_win
                            local tree_win

                            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                                local buf = vim.api.nvim_win_get_buf(win)
                                local filetype = vim.bo[buf].filetype

                                if filetype == "NvimTree" then
                                    tree_win = win
                                elseif vim.bo[buf].buftype ~= "terminal"
                                    and vim.api.nvim_win_get_config(win).relative == ""
                                then
                                    editor_win = win
                                    break
                                end
                            end

                            if not editor_win and tree_win then
                                vim.api.nvim_set_current_win(tree_win)
                                vim.cmd("vnew")
                                editor_win = vim.api.nvim_get_current_win()
                                vim.api.nvim_win_set_width(tree_win, 30)

                                local scratch = vim.api.nvim_get_current_buf()
                                vim.bo[scratch].bufhidden = "wipe"
                                vim.bo[scratch].buflisted = false
                                vim.bo[scratch].swapfile = false
                            end

                            if not editor_win then
                                return
                            end

                            vim.api.nvim_set_current_win(editor_win)
                            focus_or_open(1)

                            -- Start directory sessions in the file tree for
                            -- immediate navigation.
                            vim.cmd("stopinsert")
                            if tree_win and vim.api.nvim_win_is_valid(tree_win) then
                                vim.api.nvim_set_current_win(tree_win)
                            end
                        end)
                    end,
                })
            end

            vim.api.nvim_create_autocmd("VimResized", {
                callback = function()
                    local codex_win = visible_codex_window()
                    if codex_win then
                        vim.api.nvim_win_set_width(codex_win, codex_width())
                    end
                end,
            })

            -- ToggleTerm jobs cannot be reattached after Neovim exits. Shut
            -- down every terminal it owns before Neovim unloads the buffers.
            local exit_group = vim.api.nvim_create_augroup("ToggleTermExitCleanup", {
                clear = true,
            })

            vim.api.nvim_create_autocmd("ExitPre", {
                group = exit_group,
                callback = function()
                    local terminal = require("toggleterm.terminal")
                    for _, term in ipairs(terminal.get_all(true)) do
                        term:shutdown()
                    end
                end,
            })

        end,
    },
}
