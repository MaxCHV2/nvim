return {
  "L3MON4D3/LuaSnip",
  version = "v2.*",
  -- Habilita las transformaciones de snippets LSP (requiere jsregexp)
  build = "make install_jsregexp",
  main = "config.plugins.luasnip",
  config = function()
    require("luasnip.loaders.from_vscode").lazy_load()
  end,
  dependencies = {
    "rafamadriz/friendly-snippets",  -- Snippets predefinidos
  },
}
