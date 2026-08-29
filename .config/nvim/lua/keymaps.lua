vim.keymap.set({'n', 'v'}, '<Space>', '<Nop>')

vim.keymap.set("n", "<esc><esc>", "<cmd>noh<cr>")

vim.keymap.set("n", "<A-,>", "<cmd>bprevious<cr>", {
    desc = "Previous buffer",
})
vim.keymap.set("n", "<A-.>", "<cmd>bnext<cr>", {
    desc = "Next buffer",
})
vim.keymap.set("n", "<A-c>", "<cmd>confirm bdelete<cr>", {
    desc = "Close buffer",
})

for index = 1, 9 do
    vim.keymap.set(
        "n",
        "<A-" .. index .. ">",
        "<cmd>LualineBuffersJump! " .. index .. "<cr>",
        { desc = "Go to buffer " .. index }
    )
end
vim.keymap.set("n", "<A-0>", "<cmd>LualineBuffersJump! $<cr>", {
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
vim.keymap.set("n", "<leader>e", function()
    focus_editor_window(vim.v.count1)
end, { desc = "Focus editor window" })

vim.keymap.set("t", "<C-Space>", [[<C-\><C-n>]])
vim.keymap.set("t", "<Nul>", [[<C-\><C-n>]])

vim.keymap.set({"n","v"}, "<leader>y", '"+y')
vim.keymap.set("n", "<leader>Y", '"+Y')

-- Plugin config keymap doesn't stick; set it here
vim.keymap.set("n", "<localleader>mm", "<Plug>MarkdownPreview")
vim.keymap.set("n", "<localleader>ms", "<Plug>MarkdownPreviewStop")
vim.keymap.set("n", "<localleader>mt", "<Plug>MarkdownPreviewToggle")
