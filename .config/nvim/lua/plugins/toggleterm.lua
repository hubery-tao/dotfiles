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

            local terminal = require("toggleterm.terminal")
            local Terminal = terminal.Terminal
            local terms = {}
            -- nvim-tree replaces a directory argument with NvimTree_1 during
            -- VimEnter, so remember this before that happens.
            local started_with_directory = vim.fn.argc() == 1
                and vim.fn.isdirectory(vim.fn.argv(0)) == 1

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

            local function default_terminal_height(term)
                local size = opts.size
                if type(size) == "function" then
                    local ok, resolved_size = pcall(size, term or {
                        direction = opts.direction or "horizontal",
                    })
                    size = ok and resolved_size or nil
                end

                return math.max(1, tonumber(size) or 12)
            end

            local function is_editor_window(win)
                local buf = vim.api.nvim_win_get_buf(win)
                return vim.api.nvim_win_get_config(win).relative == ""
                    and vim.bo[buf].buftype == ""
                    and vim.bo[buf].filetype ~= "NvimTree"
            end

            local function editor_windows()
                return vim.tbl_filter(
                    is_editor_window,
                    vim.api.nvim_tabpage_list_wins(0)
                )
            end

            local function find_editor_window()
                return editor_windows()[1]
            end

            -- Agents use native terminal jobs rather than ToggleTerm's
            -- registry so their right-hand pane does not fight shell splits.
            local agent_terminals = require("config.agent_terminals")
            agent_terminals.setup({
                find_editor_window = find_editor_window,
                snapshot_layout = snapshot_terminal_heights,
                restore_layout = restore_terminal_heights,
            })

            local function terminal_cwd(bufnr)
                local job_id = vim.b[bufnr].terminal_job_id
                if job_id then
                    local pid = vim.fn.jobpid(job_id)
                    if pid and pid > 0 then
                        local cwd = vim.uv.fs_realpath("/proc/" .. pid .. "/cwd")
                        if cwd then
                            return cwd
                        end
                    end
                end

                return vim.fn.getcwd()
            end

            local function pick_editor_window(editor_windows)
                local labels = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
                if #editor_windows > #labels then
                    vim.notify("Too many editor windows to label", vim.log.levels.ERROR)
                    return
                end

                table.sort(editor_windows, function(left, right)
                    local left_position = vim.api.nvim_win_get_position(left)
                    local right_position = vim.api.nvim_win_get_position(right)
                    if left_position[1] == right_position[1] then
                        return left_position[2] < right_position[2]
                    end
                    return left_position[1] < right_position[1]
                end)

                local saved = {}
                local window_by_label = {}
                local laststatus = vim.o.laststatus
                vim.o.laststatus = 2

                for index, win in ipairs(editor_windows) do
                    local label = labels:sub(index, index)
                    saved[win] = {
                        statusline = vim.api.nvim_get_option_value("statusline", { win = win }),
                        winhl = vim.api.nvim_get_option_value("winhl", { win = win }),
                    }
                    window_by_label[label] = win

                    vim.api.nvim_set_option_value("statusline", "%= " .. label .. " %=", {
                        win = win,
                    })
                    vim.api.nvim_set_option_value(
                        "winhl",
                        "StatusLine:NvimTreeWindowPicker,StatusLineNC:NvimTreeWindowPicker",
                        { win = win }
                    )
                end

                vim.cmd("redraw")
                vim.api.nvim_echo({ { "Pick editor window: ", "Question" } }, false, {})
                local ok, input = pcall(vim.fn.getcharstr)
                if vim.o.cmdheight == 0 then
                    vim.api.nvim_echo({ { "" } }, false, {})
                else
                    vim.cmd("normal! :")
                end

                for win, options in pairs(saved) do
                    if vim.api.nvim_win_is_valid(win) then
                        vim.api.nvim_set_option_value("statusline", options.statusline, { win = win })
                        vim.api.nvim_set_option_value("winhl", options.winhl, { win = win })
                    end
                end
                vim.o.laststatus = laststatus
                vim.cmd("redraw")

                if not ok then
                    return
                end
                return window_by_label[input:upper()]
            end

            local function open_terminal_path_in_editor()
                local terminal_buf = vim.api.nvim_get_current_buf()
                local path = vim.fn.expand("<cWORD>")
                path = path:gsub("^[%(%[%{<%'%\"]+", "")
                    :gsub("[%)%]%}>%'%\",;:]+$", "")
                if path == "" then
                    vim.notify("No path under cursor", vim.log.levels.WARN)
                    return
                end

                local line, column
                local plain_path, line_text, column_text = path:match("^(.-):(%d+):?(%d*)$")
                if plain_path then
                    path = plain_path
                    line = tonumber(line_text)
                    column = tonumber(column_text)
                end

                path = vim.fn.expand(path)
                if not vim.startswith(path, "/") then
                    path = vim.fs.joinpath(terminal_cwd(terminal_buf), path)
                end
                path = vim.fs.normalize(path)

                local available_editors = editor_windows()

                local function open_in(win)
                    if not win or not vim.api.nvim_win_is_valid(win) then
                        return
                    end

                    vim.api.nvim_set_current_win(win)
                    local ok, error_message = pcall(vim.cmd.edit, vim.fn.fnameescape(path))
                    if not ok then
                        vim.notify(error_message, vim.log.levels.ERROR)
                        return
                    end

                    if line then
                        local last_line = vim.api.nvim_buf_line_count(0)
                        local target_line = math.min(math.max(line, 1), last_line)
                        local text = vim.api.nvim_buf_get_lines(0, target_line - 1, target_line, false)[1]
                        local target_column = math.min(
                            math.max((column or 1) - 1, 0),
                            #text
                        )
                        vim.api.nvim_win_set_cursor(0, { target_line, target_column })
                    end
                end

                if #available_editors == 0 then
                    vim.cmd("aboveleft new")
                    open_in(vim.api.nvim_get_current_win())
                elseif #available_editors == 1 then
                    open_in(available_editors[1])
                else
                    open_in(pick_editor_window(available_editors))
                end
            end

            vim.api.nvim_create_autocmd("FileType", {
                pattern = "toggleterm",
                callback = function(event)
                    vim.keymap.set("n", "gf", open_terminal_path_in_editor, {
                        buffer = event.buf,
                        desc = "Open path in an editor window",
                    })
                    vim.keymap.set("n", "gF", open_terminal_path_in_editor, {
                        buffer = event.buf,
                        desc = "Open path with position in an editor window",
                    })
                end,
            })

            local function leave_sidebar_before_opening_terminal()
                local current_buf = vim.api.nvim_get_current_buf()
                local current_ft = vim.bo[current_buf].filetype
                if not agent_terminals.is_buffer(current_buf) and current_ft ~= "NvimTree" then
                    return
                end

                local editor_win = find_editor_window()
                if editor_win then
                    vim.api.nvim_set_current_win(editor_win)
                end
            end

            local function order_visible_terminals()
                local windows = {}
                local visible_terms = {}

                for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    local id = vim.b[buf].toggle_number
                    if id
                        and vim.bo[buf].filetype == "toggleterm"
                        and vim.api.nvim_win_get_config(win).relative == ""
                    then
                        local position = vim.api.nvim_win_get_position(win)
                        table.insert(windows, {
                            id = win,
                            row = position[1],
                            column = position[2],
                        })
                        table.insert(visible_terms, {
                            id = id,
                            bufnr = buf,
                        })
                    end
                end

                -- ToggleTerm always splits the most recently opened terminal,
                -- so reopening a lower-numbered hidden terminal can otherwise
                -- put it after higher-numbered terminals. Keep the split tree
                -- intact and reorder the terminal buffers within those windows.
                table.sort(windows, function(left, right)
                    if left.row == right.row then
                        return left.column < right.column
                    end
                    return left.row < right.row
                end)
                table.sort(visible_terms, function(left, right)
                    return left.id < right.id
                end)

                for index, win in ipairs(windows) do
                    local visible_term = visible_terms[index]
                    vim.api.nvim_win_set_buf(win.id, visible_term.bufnr)

                    local term = terminal.get(visible_term.id, true)
                    if term then
                        term.window = win.id
                    end
                end
            end

            local function normalize_workspace_frame()
                local current_win = vim.api.nvim_get_current_win()
                local windows = {}
                local fixed_options = {}

                for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                    if vim.api.nvim_win_get_config(win).relative == "" then
                        table.insert(windows, win)
                        fixed_options[win] = {
                            width = vim.wo[win].winfixwidth,
                            height = vim.wo[win].winfixheight,
                        }

                        -- Fixed panes can prevent the outer split frame from
                        -- expanding back to the full Neovim grid. Temporarily
                        -- release them while normalizing the entire split tree.
                        vim.wo[win].winfixwidth = false
                        vim.wo[win].winfixheight = false
                    end
                end

                local anchor_win = current_win
                if vim.api.nvim_win_get_config(current_win).relative ~= "" then
                    anchor_win = windows[1]
                end

                if anchor_win and vim.api.nvim_win_is_valid(anchor_win) then
                    vim.api.nvim_win_call(anchor_win, function()
                        -- :resize or :vertical resize on an outer window can
                        -- leave unused rows or columns. Maximize once in both
                        -- directions, then equalize every flexible split.
                        vim.cmd("wincmd _")
                        vim.cmd("wincmd |")
                        vim.cmd("wincmd =")
                    end)
                end

                for win, fixed in pairs(fixed_options) do
                    if vim.api.nvim_win_is_valid(win) then
                        vim.wo[win].winfixwidth = fixed.width
                        vim.wo[win].winfixheight = fixed.height
                    end
                end

                return anchor_win
            end

            local function reset_workspace_layout(notify_user)
                local current_win = vim.api.nvim_get_current_win()
                local anchor_win = normalize_workspace_frame()
                local agent_win = agent_terminals.visible_window()

                -- Apply the workspace-specific defaults only after the whole
                -- split frame once again fills the available Neovim grid.
                if agent_win then
                    agent_terminals.place_right(agent_win)
                end

                -- Reset nvim-tree through its public API so a manually changed
                -- width does not become the new persisted tree width.
                local tree_ok, tree_api = pcall(require, "nvim-tree.api")
                if tree_ok then
                    pcall(tree_api.tree.resize)
                end

                -- A terminal's fixed height is an absolute row count, so it
                -- can look wrong after attaching a UI with different lines.
                -- Re-evaluate ToggleTerm's configured 25% size for this UI.
                for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    local id = vim.b[buf].toggle_number
                    if id
                        and vim.bo[buf].filetype == "toggleterm"
                        and vim.api.nvim_win_get_config(win).relative == ""
                    then
                        local term = terminal.get(id, true)
                        pcall(
                            vim.api.nvim_win_set_height,
                            win,
                            default_terminal_height(term)
                        )
                        vim.wo[win].winfixheight = true
                    end
                end

                order_visible_terminals()

                -- Keep the fixed sidebar, agent, and terminal dimensions while
                -- distributing the remaining space evenly among other splits.
                if anchor_win and vim.api.nvim_win_is_valid(anchor_win) then
                    vim.api.nvim_win_call(anchor_win, function()
                        vim.cmd("wincmd =")
                    end)
                end

                if vim.api.nvim_win_is_valid(current_win) then
                    vim.api.nvim_set_current_win(current_win)
                end
                if notify_user then
                    vim.notify("Workspace layout restored")
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
                order_visible_terminals()

                -- Opening the first ToggleTerm uses a full-width bottom split.
                -- Put an already-visible native agent pane back on the outer
                -- right, then restore the height selected for the shell pane.
                local agent_win = agent_terminals.visible_window()
                if agent_win then
                    local terminal_heights = snapshot_terminal_heights()
                    agent_terminals.place_right(agent_win)
                    restore_terminal_heights(terminal_heights)
                end

                vim.api.nvim_set_current_win(term.window)
                vim.cmd("startinsert")
            end

            -- Count-aware mapping:
            -- <leader>t   -> focuses/opens terminal 1
            -- 2<leader>t  -> focuses/opens terminal 2
            vim.keymap.set("n", "<leader>t", function()
                focus_or_open(vim.v.count1)
            end, { desc = "Focus/open terminal" })

            vim.keymap.set("n", "<leader>=", function()
                reset_workspace_layout(true)
            end, { desc = "Restore workspace layout" })

            vim.api.nvim_create_user_command("ResetWorkspaceLayout", function()
                reset_workspace_layout(true)
            end, {
                desc = "Restore ToggleTerm and the agent pane to their default sizes",
            })

            -- `nvim .` used to start with only the tree window, which meant a
            -- file had to be opened before the terminal layout could be built.
            -- Give directory sessions an empty editor target and open the
            -- default terminal automatically. The agents stay opt-in via
            -- <leader>c and <leader>a.
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
                                elseif is_editor_window(win) then
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
                    -- Wait until Neovim has applied the new UI dimensions,
                    -- then recompute all fixed workspace pane sizes.
                    vim.schedule(function()
                        reset_workspace_layout(false)
                    end)
                end,
            })

            -- ToggleTerm jobs cannot be reattached after Neovim exits. Shut
            -- them down only after quitting can no longer be cancelled.
            local exit_group = vim.api.nvim_create_augroup("ToggleTermExitCleanup", {
                clear = true,
            })

            vim.api.nvim_create_autocmd("VimLeavePre", {
                group = exit_group,
                callback = function()
                    for _, term in ipairs(terminal.get_all(true)) do
                        term:shutdown()
                    end
                end,
            })

        end,
    },
}
