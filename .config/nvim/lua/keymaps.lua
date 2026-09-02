local map = vim.keymap.set

map({ "n", "v" }, "<Space>", "<Nop>")
map("n", "<Esc><Esc>", "<Cmd>nohlsearch<CR>")

map("n", "<A-,>", "<Cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<A-.>", "<Cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<A-c>", "<Cmd>confirm bdelete<CR>", { desc = "Close buffer" })

for index = 1, 9 do
    map("n", "<A-" .. index .. ">", "<Cmd>LualineBuffersJump! " .. index .. "<CR>", {
        desc = "Go to buffer " .. index,
    })
end
map("n", "<A-0>", "<Cmd>LualineBuffersJump! $<CR>", {
    desc = "Go to last buffer",
})

local function focus_editor_window(index)
    local editor_windows = {}

    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.api.nvim_win_get_config(win).relative == ""
            and vim.bo[buf].buftype == ""
            and vim.bo[buf].filetype ~= "NvimTree"
        then
            local position = vim.api.nvim_win_get_position(win)
            table.insert(editor_windows, {
                id = win,
                row = position[1],
                column = position[2],
            })
        end
    end

    table.sort(editor_windows, function(left, right)
        if left.row == right.row then
            return left.column < right.column
        end
        return left.row < right.row
    end)

    local target = editor_windows[index]
    if target then
        vim.api.nvim_set_current_win(target.id)
    else
        vim.notify("Editor window " .. index .. " is not open", vim.log.levels.WARN)
    end
end

-- <leader>e focuses the first regular editor window; a count selects another.
-- This deliberately skips sidebars, terminals, help windows, and floating windows.
map("n", "<leader>e", function()
    focus_editor_window(vim.v.count1)
end, { desc = "Focus editor window" })

map("t", "<C-Space>", [[<C-\><C-n>]])
map("t", "<Nul>", [[<C-\><C-n>]])

map({ "n", "v" }, "<leader>y", '"+y')
map("n", "<leader>Y", '"+Y')
