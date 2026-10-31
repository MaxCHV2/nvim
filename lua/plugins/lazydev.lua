-- Sustituye a folke/neodev.nvim, que está archivado y ya no se mantiene.
-- Aporta autocompletado y tipos de la API de Neovim a lua_ls.
return {
  "folke/lazydev.nvim",
  ft = "lua",
  opts = {
    library = {
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
    },
  },
}
