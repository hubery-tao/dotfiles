vim.opt.swapfile = false
vim.opt.number = true
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.autoindent = true
vim.opt.backup = false
vim.opt.hlsearch = true
vim.opt.showmatch = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.laststatus = 2
vim.opt.termguicolors = true
vim.opt.winbar = ' %f'
vim.opt.cursorline = true

vim.g.clipboard = "osc52"

vim.cmd("syntax on")
vim.cmd("filetype on")

vim.g.mapleader = " "
vim.g.maplocalleader = ","

require("config.lazy")
require("keymaps")
