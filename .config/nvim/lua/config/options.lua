local opt = vim.opt

opt.swapfile = false
opt.number = true
opt.expandtab = true
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.showmatch = true
opt.splitbelow = true
opt.splitright = true
opt.termguicolors = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.timeoutlen = 500

vim.g.clipboard = "osc52"

vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
})
