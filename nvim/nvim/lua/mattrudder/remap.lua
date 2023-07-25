function FormatDocument()
    vim.lsp.buf.format({
        async = true,
    })
end

vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

vim.keymap.set("n", "<leader>kf", FormatDocument)
