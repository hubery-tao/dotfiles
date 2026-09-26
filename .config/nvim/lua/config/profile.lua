local config_home = vim.env.XDG_CONFIG_HOME
if not config_home or config_home == "" then
    config_home = vim.env.HOME .. "/.config"
end

local path = config_home .. "/dotfiles/nvim-profile"
local profile = "gui"
if vim.fn.filereadable(path) == 1 then
    profile = vim.trim(table.concat(vim.fn.readfile(path), "\n"))
    if profile ~= "gui" and profile ~= "no-gui" then
        vim.notify("Invalid Neovim profile in " .. path .. "; using gui", vim.log.levels.WARN)
        profile = "gui"
    end
end

return { gui = profile == "gui" }
