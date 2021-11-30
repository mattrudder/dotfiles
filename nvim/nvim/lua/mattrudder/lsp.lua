vim.lsp.set_log_level("debug")

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

local lsp_status = require('lsp-status')
lsp_status.register_progress()

-- Setup nvim-cmp.
local cmp = require("cmp")
local source_mapping = {
    buffer = "[Buffer]",
    nvim_lsp = "[LSP]",
    nvim_lua = "[Lua]",
    path = "[Path]",
}
local lspkind = require("lspkind")
lspkind.init({
    with_text = true,
})

local luasnip = require("luasnip")
cmp.setup({
    snippet = {
        expand = function(args)
            require("luasnip").lsp_expand(args.body)
        end,
    },
    mapping = {
        ["<C-p>"] = cmp.mapping.select_prev_item(),
        ["<C-n>"] = cmp.mapping.select_next_item(),
        ["<C-u>"] = cmp.mapping.scroll_docs(-4),
        ["<C-d>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.close(),
        ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.confirm({ select = true })
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            else
                fallback()
            end
        end, { 'i', 's' }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
            if luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, { 'i', 's'}),
        ["<CR>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Insert,
            select = false,
        }),
    },
    formatting = {
        format = function(entry, vim_item)
            vim_item.kind = lspkind.presets.default[vim_item.kind]
            local menu = source_mapping[entry.source.name]
            vim_item.menu = menu
            return vim_item
        end
    },
    sources = {
        { name = "nvim_lsp" },
        { name = "luasnip" },
        { name = "buffer" },
    },
})

local function config(lsp_config, installer_config)
    return vim.tbl_deep_extend("force", {
        capabilities = require("cmp_nvim_lsp").update_capabilities(vim.lsp.protocol.make_client_capabilities()),
    }, { capabilities = lsp_status.capabilities }, lsp_config or {}, installer_config or {})
end

local setups = {
    ["rust_analyzer"] = function(_config)
        if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
            _config.cmd = { _config.cmd[1] .. ".exe" }
        end
        require("rust-tools").setup(_config)
    end
}

local configs = {
    ["rust_analyzer"] = {
        tools = {
            autoSetHints = true,
            hover_with_actions = true,
            inlay_hints = {
                show_parameter_hints = true,
                parameter_hints_prefix = "",
                other_hints_prefix = "",
            },
        },
        settings = {
            ["rust_analyzer"] = {
                checkOnSave = {
                    command = "clippy",
                },
            },
        },
    },
    ["sumneko_lua"] = {
	    settings = {
		    Lua = {
			    runtime = {
				    -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
				    version = "LuaJIT",
				    -- Setup your lua path
				    path = vim.split(package.path, ";"),
			    },
			    diagnostics = {
				    -- Get the language server to recognize the `vim` global
				    globals = { "vim" },
			    },
			    workspace = {
				    -- Make the server aware of Neovim runtime files
				    library = {
					    [vim.fn.expand("$VIMRUNTIME/lua")] = true,
					    [vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
				    },
			    },
		    },
	    },
    },
}

local lsp_installer = require("nvim-lsp-installer")
lsp_installer.on_server_ready(function(server)
    local lsp_cfg = configs[server.name]
    local installer_cfg = server:get_default_options()
    local cmd = installer_cfg.cmd or { "" }
    local cfg = config(lsp_cfg, installer_cfg)

    cfg.on_attach = function(client, bufnr)
        if lsp_cfg.on_attach then
            lsp_cfg.on_attach(client, bufnr)
        end
        lsp_status.on_attach(client)
    end

    local setup = setups[server.name]
    if setup == nil then
        server:setup(cfg)
    else
        setup(cfg)
    end
end)

local nvim_lsp = require('lspconfig')
local servers = { 'rust_analyzer' }
for _, lsp in ipairs(servers) do
    local server = nvim_lsp[lsp]
    local lsp_cfg = configs[server.name]
    local cfg = config(lsp_cfg)

    cfg.on_attach = function(client, bufnr)
        if lsp_cfg.on_attach then
            lsp_cfg.on_attach(client, bufnr)
        end
        lsp_status.on_attach(client)
    end

    local setup = setups[server.name]
    if setup == nil then
        server:setup(cfg)
    else
        setup(cfg)
    end
end


require("symbols-outline").setup({
    highlight_hovered_item = true,
    show_guides = true,
})

local snippets_paths = function()
    local plugins = { "friendly-snippets" }
    local paths = {}
    local path
    local root_path = vim.env.HOME .. "/.vim/plugged/"
    for _, plug in ipairs(plugins) do
        path = root_path .. plug
        if vim.fn.isdirectory(path) ~= 0 then
            table.insert(paths, path)
        end
    end
    return paths
end

require("luasnip.loaders.from_vscode").lazy_load({
    paths = snippets_paths(),
    include = nil,
    exclude = {}
})

