local M = {}

local config = {}

-- The right-hand slot shows one agent at a time, but every agent keeps its
-- own terminal buffer and job. Switching agents only swaps the visible buffer.
local agents = {
    codex = { command = { "codex" }, filetype = "codex" },
    claude = { command = { "claude" }, filetype = "claude" },
}

local function visible_agent_window(agent)
    if not agent.bufnr or not vim.api.nvim_buf_is_valid(agent.bufnr) then
        return nil
    end

    for _, win in ipairs(vim.fn.win_findbuf(agent.bufnr)) do
        if vim.api.nvim_win_is_valid(win)
            and vim.api.nvim_win_get_tabpage(win) == vim.api.nvim_get_current_tabpage()
        then
            return win
        end
    end
end

function M.is_buffer(bufnr)
    for _, agent in pairs(agents) do
        if agent.bufnr == bufnr then
            return true
        end
    end
    return false
end

-- Return the right-hand slot, whichever agent currently occupies it.
function M.visible_window()
    for _, agent in pairs(agents) do
        local win = visible_agent_window(agent)
        if win then
            return win
        end
    end
end

function M.place_right(win)
    if not win or not vim.api.nvim_win_is_valid(win) then
        return
    end

    vim.api.nvim_win_call(win, function()
        -- A vsplit made from the editor may initially occupy only its row.
        -- Move it to the outer right so it spans the shell rows as well.
        vim.cmd("wincmd L")
    end)
    vim.api.nvim_win_set_width(win, config.width())
    vim.wo[win].winfixwidth = true
end

function M.focus(name)
    local agent = agents[name]
    if not agent then
        vim.notify("Unknown agent: " .. tostring(name), vim.log.levels.ERROR)
        return
    end

    local open_win = visible_agent_window(agent)
    if open_win then
        vim.api.nvim_set_current_win(open_win)
        return
    end

    local has_buffer = agent.bufnr and vim.api.nvim_buf_is_valid(agent.bufnr)
    if not has_buffer and vim.fn.executable(agent.command[1]) ~= 1 then
        vim.notify(
            agent.command[1] .. " is not installed or not in PATH",
            vim.log.levels.ERROR
        )
        return
    end

    -- Reuse the slot when the other agent holds it so the two sessions keep
    -- running independently without stacking multiple right-hand panes.
    local win = M.visible_window()
    local layout_snapshot

    if win then
        vim.api.nvim_set_current_win(win)
    else
        local editor_win = config.find_editor_window()
        if editor_win then
            vim.api.nvim_set_current_win(editor_win)
        end

        layout_snapshot = config.snapshot_layout()
        vim.cmd("botright vsplit")
        win = vim.api.nvim_get_current_win()
    end

    local created = false
    local previous_buf = vim.api.nvim_win_get_buf(win)

    if has_buffer then
        vim.api.nvim_win_set_buf(win, agent.bufnr)
    else
        created = true
        local bufnr = vim.api.nvim_create_buf(false, true)
        agent.bufnr = bufnr
        vim.api.nvim_win_set_buf(win, bufnr)
        vim.bo[bufnr].bufhidden = "hide"
        vim.bo[bufnr].buflisted = false
        vim.bo[bufnr].swapfile = false

        -- jobstart(..., { term = true }) attaches to the current buffer.
        local job_id = vim.fn.jobstart(agent.command, { term = true })
        if job_id <= 0 then
            vim.api.nvim_buf_delete(bufnr, { force = true })
            agent.bufnr = nil
            if layout_snapshot and #vim.api.nvim_tabpage_list_wins(0) > 1 then
                vim.api.nvim_win_close(win, true)
                config.restore_layout(layout_snapshot)
            elseif vim.api.nvim_buf_is_valid(previous_buf) then
                vim.api.nvim_win_set_buf(win, previous_buf)
            end
            vim.notify("Failed to start " .. agent.command[1], vim.log.levels.ERROR)
            return
        end

        agent.job_id = job_id
        vim.bo[bufnr].filetype = agent.filetype

        vim.api.nvim_create_autocmd("TermClose", {
            buffer = bufnr,
            once = true,
            callback = function()
                vim.schedule(function()
                    for _, agent_win in ipairs(vim.fn.win_findbuf(bufnr)) do
                        if vim.api.nvim_win_is_valid(agent_win)
                            and #vim.api.nvim_tabpage_list_wins(0) > 1
                        then
                            vim.api.nvim_win_close(agent_win, true)
                        end
                    end

                    if vim.api.nvim_buf_is_valid(bufnr) then
                        vim.api.nvim_buf_delete(bufnr, { force = true })
                    end
                    if agent.bufnr == bufnr then
                        agent.bufnr = nil
                        agent.job_id = nil
                    end
                end)
            end,
        })
    end

    M.place_right(win)
    if layout_snapshot then
        config.restore_layout(layout_snapshot)
    end

    -- New sessions enter terminal mode; returning to a running session keeps
    -- Normal mode so its scrollback remains navigable.
    if created then
        vim.cmd("startinsert")
    end
end

function M.shutdown_all()
    for _, agent in pairs(agents) do
        local job_id = agent.job_id
        if job_id and vim.fn.jobwait({ job_id }, 0)[1] == -1 then
            vim.fn.jobstop(job_id)
        end
    end
end

function M.setup(opts)
    config = vim.tbl_extend("force", {
        find_editor_window = function() end,
        snapshot_layout = function() end,
        restore_layout = function() end,
        width = function()
            return math.floor(vim.o.columns * 0.33)
        end,
    }, opts or {})

    -- In terminal mode, use <C-Space> first to return to Normal mode.
    vim.keymap.set("n", "<leader>c", function()
        M.focus("codex")
    end, { desc = "Focus/open Codex workspace" })

    vim.keymap.set("n", "<leader>a", function()
        M.focus("claude")
    end, { desc = "Focus/open Claude Code workspace" })

    vim.api.nvim_create_user_command("Codex", function()
        M.focus("codex")
    end, { desc = "Focus/open the right-side Codex workspace" })

    vim.api.nvim_create_user_command("Claude", function()
        M.focus("claude")
    end, { desc = "Focus/open the right-side Claude Code workspace" })

    local exit_group = vim.api.nvim_create_augroup("AgentTerminalExitCleanup", {
        clear = true,
    })
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = exit_group,
        callback = M.shutdown_all,
    })
end

return M
