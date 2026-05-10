return {
    "olimorris/codecompanion.nvim",
    version = "^19.0.0",
    opts = {
        interactions = {
            chat   = { adapter = "copilot" },
            inline = { adapter = "copilot" },
            agent  = { adapter = "copilot" },
        },
    },
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
    },
}
