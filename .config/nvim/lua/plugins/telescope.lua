return {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.5',
    dependencies = {
        'nvim-lua/plenary.nvim',
    },

    config = function()
        require('telescope').setup({
            defaults = {
                preview = {
                    timeout = 1000,
                    filesize_limit = 10,
                },
            },
        })

        local builtin = require('telescope.builtin')

        vim.keymap.set('n', '<leader>ff', builtin.find_files, {
            desc = 'Telescope find files',
        })
        vim.keymap.set('n', '<leader>fg', builtin.live_grep, {
            desc = 'Telescope live grep',
        })
        vim.keymap.set('n', '<leader>fb', builtin.buffers, {
            desc = 'Telescope buffers',
        })
        vim.keymap.set('n', '<leader>fh', builtin.help_tags, {
            desc = 'Telescope help tags',
        })
        vim.keymap.set('n', '<leader>fr', function()
            builtin.resume({
                initial_mode = 'normal',
            })
        end, { desc = 'Telescope resume' })
    end,
}
