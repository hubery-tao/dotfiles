vim.keymap.set({'n', 'v'}, '<Space>', '<Nop>', { silent = true })
vim.g.mapleader = " "


vim.keymap.set("n", "<esc><esc>", "<cmd>noh<cr>", {desc = "Quick :noh"})

-- <leader>t: focus terminal window if not, otherwise open new
vim.keymap.set('n', '<leader>t', function()
  local buftype = vim.bo.buftype
  local in_terminal = (buftype == "terminal")

  if not in_terminal then
    -- Look for any visible terminal window and focus it
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      local bt  = vim.api.nvim_buf_get_option(buf, "buftype")
      if bt == "terminal" then
        vim.api.nvim_set_current_win(win)
        return
      end
    end
    -- No terminal window visible -> open one at the bottom
    vim.cmd("botright sp | te")
    vim.cmd("resize" .. math.floor(vim.o.lines * 0.25))
    return
  end

  -- Already in a terminal window -> open a new terminal in a vertical split
  vim.cmd("vs | te")
end, { desc = 'Focus visible ToggleTerm or open one' })
