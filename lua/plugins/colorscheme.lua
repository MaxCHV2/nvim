return {
--"embark-theme/vim",
"maxmx03/fluoromachine.nvim",
--"EdenEast/nightfox.nvim",
--"shaunsingh/moonlight.nvim",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      -- load the colorscheme here
-- vim.cmd([[colorscheme embark]])
vim.cmd([[colorscheme fluoromachine]])
--vim.cmd([[colorscheme terafox]])
--vim.cmd([[colorscheme moonlight]])

    end,
}
