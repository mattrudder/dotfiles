vim.opt.guicursor = ""
vim.opt.guifont = "Berkeley Mono:h12"

local alpha = function()
    return string.format("%x", math.floor(255 * (vim.g.neovide_transparency_point or 0.8)))
end

if vim.g.neovide then
    local change_transparency = function(delta)
        vim.g.neovide_transparency_point = vim.g.neovide_transparency_point + delta
        vim.g.neovide_background_color = "#303030" .. alpha()
    end

    vim.g.neovide_transparency = 0.0
    vim.g.neovide_transparency_point = 0.8
    vim.g.neovide_background_color = "#303030" .. alpha()

    vim.keymap.set({ "n", "v", "o" }, "<C-+>", function ()
        change_transparency(0.01)
    end)

    vim.keymap.set({ "n", "v", "o" }, "<C-->", function ()
        change_transparency(-0.01)
    end)

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
