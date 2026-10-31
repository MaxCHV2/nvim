-- ~/.config/nvim/lua/plugins/vimtex.lua

return {
  'lervag/vimtex',
  lazy = true,
  ft = { 'tex' },

  config = function()
    -- Configuración para que vimtex use Skim como visor de PDF.
    vim.g.vimtex_view_method = 'skim'

    -- Desactivamos los atajos por defecto (\ll, etc.) para usar solo los nuestros.
    vim.g.vimtex_mappings_enabled = 0

    -- ✅ NUEVOS ATAJOS CON LA TECLA LÍDER
    local map = vim.keymap.set
    local opts = { noremap = true, silent = true, desc = '' }

    -- Mapea '\' + c para compilar
    opts.desc = 'Vimtex Compile'
    map('n', '<leader>c', '<Plug>(vimtex-compile)', opts)

    -- Mapea '\' + v para ver el PDF
    opts.desc = 'Vimtex View'
    map('n', '<leader>v', '<Plug>(vimtex-view)', opts)

    -- Mapea '\' + k para limpiar (k de 'clean')
    opts.desc = 'Vimtex Clean'
    map('n', '<leader>k', '<Plug>(vimtex-clean)', opts)
  end,
}
