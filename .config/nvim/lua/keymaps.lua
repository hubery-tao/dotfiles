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

vim.keymap.set("t", "<C-Space>", [[<C-\><C-n>]])
vim.keymap.set("t", "<Nul>", [[<C-\><C-n>]])

vim.keymap.set({"n","v"}, "<leader>y", '"+y')
vim.keymap.set("n", "<leader>Y", '"+Y')

-- Plugin config keymap doesn't stick; set it here
vim.keymap.set("n", "<localleader>mm", "<Plug>MarkdownPreview")
vim.keymap.set("n", "<localleader>ms", "<Plug>MarkdownPreviewStop")
vim.keymap.set("n", "<localleader>mt", "<Plug>MarkdownPreviewToggle")
