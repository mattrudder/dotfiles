vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
    use 'wbthomason/packer.nvim'

    use {
        'nvim-telescope/telescope.nvim', branch = '0.1.x',
        requires = { { 'nvim-lua/plenary.nvim' } }
    }

    use {
        "~/dev/marmot.nvim",
        requires = "rktjmp/lush.nvim",
    }

    use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }
    use { 'nvim-treesitter/playground' }

    use {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'dev-v3',
        requires = {
            -- LSP Support
            { 'neovim/nvim-lspconfig' },
            { 'williamboman/mason.nvim' },
            { 'williamboman/mason-lspconfig.nvim' },

            -- Autocompletion
            { 'hrsh7th/nvim-cmp' },
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'L3MON4D3/LuaSnip' },
        }
    }
    use 'mfussenegger/nvim-dap'
    use {
        "SmiteshP/nvim-navic",
        requires = "neovim/nvim-lspconfig"
    }

    use {
        'glepnir/galaxyline.nvim',
        branch = 'main',
        -- your statusline
        config = function()
            require('mattrudder.statusline')
        end,
        -- some optional icons
        requires = {
            { 'nvim-tree/nvim-web-devicons', opt = true },
        },
    }
end)
