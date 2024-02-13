local builtin = require('telescope.builtin')

-- load files in my vimrc directory, using Ctrl-Comma
vim.keymap.set('n', '<C-,>', function()
    builtin.find_files {
        cwd = "~/.dotfiles/nvim/nvim",
        prompt_title = ".vimrc"
    }
end)

-- Finding files in the workspace/cwd
vim.keymap.set('n', '<C-p>', builtin.find_files, {})

vim.keymap.set('n', '<leader>sf', builtin.find_files, {})
vim.keymap.set('n', '<leader>sg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>ss', builtin.treesitter, {})
vim.keymap.set('n', '<leader>sb', builtin.current_buffer_fuzzy_find, {})
vim.keymap.set('n', '<leader>sr', builtin.lsp_references, {})
vim.keymap.set('n', '<leader>st', builtin.lsp_workspace_symbols, {})
vim.keymap.set('n', '<leader>sx', builtin.quickfix, {})
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, {})

-- Smart Jumps
vim.keymap.set('n', '<leader>gd', builtin.lsp_definitions, {})
