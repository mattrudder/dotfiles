vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:ver25-Cursor,r-cr-o:hor20"
vim.opt.guifont = "Berkeley Mono:h14"

if vim.g.neovide then
    vim.g.neovide_transparency = 0.85
    vim.g.neovide_refresh_rate = 175
    vim.g.neovide_refresh_rate_idle = 20
end

if vim.g.neoray then
    vim.opt.guifont = "BerkeleyMono:h12"
    vim.cmd [[
        NeoraySet CursorAnimTime 0.07
        NeoraySet Transparency 0.95
        NeoraySet TargetTPS 175
    ]]
end

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = vim.fn.stdpath('data') .. "/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50
vim.opt.colorcolumn = "80"

vim.g.mapleader = " "
