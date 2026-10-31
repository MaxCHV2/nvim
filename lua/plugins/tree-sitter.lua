-- nvim-treesitter archivó la rama `master`. La rama `main` cambió la API:
-- ya no existe `nvim-treesitter.configs` ni las tablas `highlight`/`indent`.
-- Ahora se instalan parsers con :TSInstall y el resaltado se activa con
-- vim.treesitter.start().
local ensure_installed = {
  "lua",
  "luadoc",
  "query",
  "vim",
  "vimdoc",
  "c",
  "rust",
  "python",
  "kotlin",
  "dart",
  "markdown",
  "markdown_inline",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      ts.setup()

      -- La rama `main` compila los parsers con el CLI de tree-sitter.
      -- Sin él, saltarse la instalación evita una cascada de errores.
      if vim.fn.executable("tree-sitter") == 1 then
        -- Instala solo lo que falte y exista realmente en el registro de parsers
        local available = ts.get_available()
        local installed = ts.get_installed()
        local missing = {}
        for _, lang in ipairs(ensure_installed) do
          if vim.tbl_contains(available, lang) and not vim.tbl_contains(installed, lang) then
            table.insert(missing, lang)
          end
        end
        if #missing > 0 then
          ts.install(missing)
        end
      end

      -- Resaltado + indentación por treesitter cuando hay parser disponible
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          if not lang then
            return
          end
          if pcall(vim.treesitter.start, args.buf, lang) then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true },
      })

      local select = require("nvim-treesitter-textobjects.select")
      local objects = {
        af = "@function.outer",
        ["if"] = "@function.inner",
        ac = "@conditional.outer",
        ic = "@conditional.inner",
        al = "@loop.outer",
        il = "@loop.inner",
      }
      for lhs, query in pairs(objects) do
        vim.keymap.set({ "x", "o" }, lhs, function()
          select.select_textobject(query, "textobjects")
        end, { desc = "Textobject " .. query })
      end
    end,
  },
}
