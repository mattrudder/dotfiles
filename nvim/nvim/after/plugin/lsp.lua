local lsp = require('lsp-zero').preset({})

lsp.on_attach(function(client, bufnr)
  lsp.default_keymaps({buffer = bufnr})

  local opts = {buffer = bufnr}
  local bind = vim.keymap.set

  bind('n', '<C-r>', function() vim.lsp.buf.rename() end, opts)
end)

lsp.extend_cmp()

local cmp = require('cmp')
local cmp_select = {behavior = cmp.SelectBehavior.Select}

cmp.setup({
	sources = {
		{name = 'nvim_lsp'},
	},
	mapping = {
		['<CR>'] = cmp.mapping.confirm({select = false}),
		['<C-y>'] = cmp.mapping.confirm({select = true}),
		['<C-e>'] = cmp.mapping.abort(),
		['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
		['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
		['<C-Space>'] = cmp.mapping.complete(),
	},
})

require('mason').setup({})
require('mason-lspconfig').setup({
	ensure_installed = {
		'tsserver',
		'eslint',
		'rust_analyzer',
		'lua_ls',
		'zls',
	},
	handlers = {
		lsp.default_setup,
		lua_ls = function()
			-- configure lua language server for neovim
			require('lspconfig').lua_ls.setup(lsp.nvim_lua_ls())
		end
	},
})


