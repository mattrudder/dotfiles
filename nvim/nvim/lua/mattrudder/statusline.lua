local lualine = require('lualine')


lualine.setup {
    options = {
        icons_enabled = true,
        theme = 'wombat',
        component_separators = { left = '', right = ''},
        section_separators = { left = '', right = ''},
        disabled_filetypes = {},
        always_divide_middle = true,
    },
    sections = {
        lualine_a = {'mode'},
        lualine_b = {'branch', 'diff'},
        -- lualine_c = {'filename', {'diagnostics', sources={'nvim_lsp', 'coc'}}, "require('mattrudder.lspstatus').status()"},--"require'lsp-status'.status()"},
        lualine_c = {'filename', {'diagnostics', sources={'nvim_lsp', 'coc'}}, 'g:coc_status'},
        lualine_x = {'encoding', 'fileformat', 'filetype'},
        lualine_y = {'progress'},
        lualine_z = {'location'}
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {'filename'},
        lualine_x = {'location'},
        lualine_y = {},
        lualine_z = {}
    },
    tabline = {},
    extensions = {}
}
