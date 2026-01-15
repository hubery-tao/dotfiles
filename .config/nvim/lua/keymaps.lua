vim.keymap.set({'n', 'v'}, '<Space>', '<Nop>')
vim.g.mapleader = " "
vim.g.maplocalleader = ","

vim.keymap.set("n", "<esc><esc>", "<cmd>noh<cr>")

vim.keymap.set("t", "<C-Space>", [[<C-\><C-n>]])
vim.keymap.set("t", "<Nul>", [[<C-\><C-n>]])

vim.keymap.set({"n","v"}, "<leader>y", '"+y')
vim.keymap.set("n", "<leader>Y", '"+Y')

-- Plugin config keymap doesn't stick; set it here
vim.keymap.set("n", "<localleader>mm", "<Plug>MarkdownPreview")
vim.keymap.set("n", "<localleader>ms", "<Plug>MarkdownPreviewStop")
vim.keymap.set("n", "<localleader>mt", "<Plug>MarkdownPreviewToggle")
