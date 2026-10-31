-- Comando para crear una clase Java
vim.api.nvim_create_user_command('JavaClass', function()
  local filename = vim.fn.expand('%:t:r')  -- Obtiene el nombre del archivo actual sin extensión
  local class_name = filename:gsub("^%l", string.upper)  -- Capitaliza la primera letra
  
  vim.fn.append(0, {
    "public class " .. class_name .. " {",
    "    public static void main(String[] args) {",
    "        // Código aquí",
    "    }",
    "}"
  })
end, {})

-- Comando para insertar System.out.println()
vim.api.nvim_create_user_command('JavaPrint', function()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local new_line = line:sub(1, col) .. "System.out.println();" .. line:sub(col + 1)
  vim.api.nvim_set_current_line(new_line)
  vim.api.nvim_win_set_cursor(0, {vim.fn.line('.'), col + 21})
end, {})

-- Nota: el keymap <space>f (formatear con LSP) se define por buffer en
-- lua/plugins/lsp.lua dentro del autocomando LspAttach.
