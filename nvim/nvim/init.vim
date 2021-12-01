let g:NERDCreateDefaultMappings = 0

call plug#begin('~/.vim/plugged')

" Color Schemes
Plug 'vim-scripts/Wombat'
Plug 'molok/vim-vombato-colorscheme'
Plug 'folke/lsp-colors.nvim'

" Editor Enhancements
Plug 'editorconfig/editorconfig-vim'
Plug 'nvim-lualine/lualine.nvim'
Plug 'kyazdani42/nvim-web-devicons'

" LSP / Code Completion
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/lsp-status.nvim'
Plug 'williamboman/nvim-lsp-installer'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'
Plug 'onsails/lspkind-nvim'
Plug 'glepnir/lspsaga.nvim'
Plug 'simrat39/symbols-outline.nvim'

" TreeSitter (parser improvements)
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'nvim-treesitter/playground'

" Debugger Plugins
Plug 'mfussenegger/nvim-dap'
Plug 'Pocco81/DAPInstall.nvim'

" Git Integration
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'

" Languages
Plug 'rust-lang/rust.vim'
Plug 'simrat39/rust-tools.nvim'
Plug 'darrikonn/vim-gofmt'

" Utilities
Plug 'tpope/vim-dispatch' " for async dispatch, builds, etc
Plug 'tpope/vim-projectionist' " for default actions based on file type

" Telescope
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }

" Snippets
Plug 'L3MON4D3/LuaSnip'
Plug 'rafamadriz/friendly-snippets'

" Formatting
Plug 'sbdchd/neoformat'

" Comments
Plug 'preservim/nerdcommenter'

call plug#end()

filetype plugin on

let mapleader = " "

lua require("mattrudder")
lua require("nvim-treesitter.configs").setup { indent = { enable = true }, highlight = { enable = true }, incremental_selection = { enable = true }, textobjects = { enable = true }}

if executable('rg')
    let g:rg_derive_root='true'
endif

let loaded_matchparen = 1
nnoremap <leader>pv :Vex<CR>
nnoremap <leader><CR> :so $MYVIMRC<CR>
nnoremap <C-j> :cnext<CR>
nnoremap <C-k> :cprev<CR>
nnoremap <leader>y "+y
nnoremap <silent> <C-f> :silent !tmux neww tmux-sessionizer<CR>

noremap <silent> <C-\> :call nerdcommenter#Comment("n", "Toggle")<CR>

vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

inoremap <C-e> <esc>$i<right>
inoremap <C-a> <esc>0i

augroup highlight_yank
    autocmd!
    autocmd TextYankPost * silent! lua require'vim.highlight'.on_yank({timeout = 40})
augroup END

augroup MINE
    autocmd!
    autocmd BufWritePre lua,cpp,c,h,hpp,cxx,cc Neoformat
augroup END

" Needs to be created before switching color schemes
augroup ColorSchemeTweaks
  autocmd!
  autocmd ColorScheme * highlight Normal guibg=NONE ctermbg=NONE
  autocmd ColorScheme * highlight NonText guibg=NONE ctermbg=NONE
augroup END

colorscheme vombato

