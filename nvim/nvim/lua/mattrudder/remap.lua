function FormatDocument()
    vim.lsp.buf.format({
        async = true,
    })
end

local bind = vim.keymap.set

bind('n', '<leader>pv', vim.cmd.Ex)

bind('n', '<leader>kf', FormatDocument)
--[[
bind('i', '"', '""<left>')
bind('i', "'", "''<left>")
bind('i', '(', '()<left>')
bind('i', '[', '[]<left>')
bind('i', '{', '{}<left>')
--]]

bind('i', '<C-s>', '<C-O>:w<CR>')
bind('n', '<C-s>', ':w<CR>')

