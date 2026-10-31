-- LSP: usa la API nativa de Neovim 0.11+ (vim.lsp.config / vim.lsp.enable).
-- nvim-lspconfig solo aporta las definiciones base en su carpeta `lsp/`.
return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "mason-org/mason.nvim",
    "hrsh7th/cmp-nvim-lsp",
  },
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    ----------------------------------------------------------------------
    -- Keymaps globales de diagnóstico
    ----------------------------------------------------------------------
    vim.keymap.set("n", "<space>e", vim.diagnostic.open_float, { desc = "Diagnóstico flotante" })
    vim.keymap.set("n", "[d", function()
      vim.diagnostic.jump({ count = -1, float = true })
    end, { desc = "Diagnóstico anterior" })
    vim.keymap.set("n", "]d", function()
      vim.diagnostic.jump({ count = 1, float = true })
    end, { desc = "Diagnóstico siguiente" })
    vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist, { desc = "Diagnósticos a loclist" })

    ----------------------------------------------------------------------
    -- Keymaps por buffer al conectarse un servidor
    ----------------------------------------------------------------------
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
      callback = function(ev)
        local opts = function(desc)
          return { buffer = ev.buf, desc = "LSP: " .. desc }
        end

        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts("declaración"))
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts("definición"))
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts("hover"))
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts("implementación"))
        vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts("ayuda de firma"))
        vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, opts("añadir carpeta"))
        vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, opts("quitar carpeta"))
        vim.keymap.set("n", "<space>wl", function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, opts("listar carpetas"))
        vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, opts("tipo"))
        vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts("renombrar"))
        vim.keymap.set({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, opts("code action"))
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts("referencias"))
        vim.keymap.set("n", "<space>f", function()
          vim.lsp.buf.format({ async = true })
        end, opts("formatear"))
      end,
    })

    ----------------------------------------------------------------------
    -- Capacidades compartidas por todos los servidores
    ----------------------------------------------------------------------
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    if ok_cmp then
      capabilities = cmp_lsp.default_capabilities(capabilities)
    end

    vim.lsp.config("*", { capabilities = capabilities })

    ----------------------------------------------------------------------
    -- Ajustes por servidor (solo lo que difiere del default de lspconfig)
    ----------------------------------------------------------------------
    vim.lsp.config("pylsp", {
      settings = {
        pylsp = {
          plugins = {
            pylint = { enabled = true },
            pyflakes = { enabled = false },
            pycodestyle = { enabled = true },
            black = { enabled = true, line_length = 88 },
            yapf = { enabled = false },
          },
        },
      },
    })

    vim.lsp.config("ccls", {
      init_options = {
        cache = { directory = ".ccls-cache" },
        highlight = { lsRanges = true },
      },
    })

    vim.lsp.config("rust_analyzer", {
      settings = {
        ["rust-analyzer"] = {
          imports = { granularity = { group = "module" }, prefix = "self" },
          cargo = { buildScripts = { enable = true } },
          procMacro = { enable = true },
        },
      },
    })

    -- kotlin-language-server empaqueta el compilador Kotlin 2.1.0, que no sabe
    -- interpretar versiones de Java >= 22 y muere con "IllegalArgumentException".
    -- Se le pasa un JDK compatible solo a este servidor; el `java` del sistema
    -- (y por tanto jdtls) se queda intacto.
    local function kotlin_jdk()
      for _, version in ipairs({ "21", "17" }) do
        local home = vim.fn.system({ "/usr/libexec/java_home", "-v", version })
        if vim.v.shell_error == 0 then
          return vim.trim(home)
        end
      end
      return nil
    end

    local kotlin_config = {
      -- Si el proyecto no es Gradle/Maven, lspconfig deja `init_options` vacío y
      -- Lua lo serializa como `[]`; el servidor espera un objeto y responde
      -- "Expected BEGIN_OBJECT but was BEGIN_ARRAY". Siempre damos un
      -- storagePath válido.
      before_init = function(params, config)
        params.initializationOptions = {
          storagePath = config.root_dir or vim.fn.stdpath("cache") .. "/kotlin-language-server",
        }
      end,
    }

    local kotlin_java_home = kotlin_jdk()
    if kotlin_java_home then
      kotlin_config.cmd_env = { JAVA_HOME = kotlin_java_home }
    end

    vim.lsp.config("kotlin_language_server", kotlin_config)

    vim.lsp.config("lua_ls", {
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          workspace = { checkThirdParty = false },
          telemetry = { enable = false },
        },
      },
    })

    ----------------------------------------------------------------------
    -- Habilita únicamente los servidores cuyo ejecutable exista.
    -- Así no aparecen errores "Spawning language server ... failed".
    ----------------------------------------------------------------------
    -- Algunos servidores necesitan más que su propio binario. rust_analyzer, por
    -- ejemplo, resuelve su root_dir llamando a `rustc --print sysroot`, y sin la
    -- toolchain de Rust eso lanza un error en cada BufRead.
    local extra_requirements = {
      rust_analyzer = { "rustc" },
    }

    local function is_available(name)
      for _, bin in ipairs(extra_requirements[name] or {}) do
        if vim.fn.executable(bin) ~= 1 then
          return false
        end
      end

      local ok, cfg = pcall(function()
        return vim.lsp.config[name]
      end)
      if not ok or type(cfg) ~= "table" then
        return false
      end
      local cmd = cfg.cmd
      if type(cmd) == "function" then
        return true
      end
      if type(cmd) == "table" and cmd[1] then
        return vim.fn.executable(cmd[1]) == 1
      end
      return false
    end

    -- Para C/C++ se prefiere clangd; ccls solo si clangd no está.
    local c_server = is_available("clangd") and "clangd" or "ccls"

    local wanted = {
      c_server,
      "lua_ls",
      "pylsp",
      "jdtls",
      "kotlin_language_server",
      "dartls",
      "rust_analyzer",
      "texlab",
      "tailwindcss",
    }

    local missing = {}
    for _, name in ipairs(wanted) do
      if is_available(name) then
        vim.lsp.enable(name)
      else
        table.insert(missing, name)
      end
    end

    -- Los servidores faltantes se reportan solo bajo demanda con :LspMissing,
    -- en lugar de lanzar notificaciones en cada arranque.
    vim.api.nvim_create_user_command("LspMissing", function()
      if #missing == 0 then
        vim.notify("Todos los servidores LSP configurados están disponibles.", vim.log.levels.INFO)
      else
        vim.notify(
          "Servidores LSP no instalados: "
            .. table.concat(missing, ", ")
            .. "\nInstálalos con :Mason",
          vim.log.levels.WARN
        )
      end
    end, { desc = "Lista los servidores LSP configurados que no están instalados" })
  end,
}
