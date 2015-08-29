" My vimrc file, Started from scratch Sept 2, 2013
" by Matt Rudder - matt@mattrudder.com - http://mattrudder.com
set nocompatible
filetype off
set shell=bash

" === General Config ===
set number                      "Line numbers!
set backspace=indent,eol,start  "Allow backspace in insert mode
set history=1000                "Up the cmd history
set showcmd                     "Show incomplete commands
set showmode                    "Show current mode
set autoread                    "Reload files changed outside vim

set hidden

let mapleader=","

" === Colors ===
set t_Co=256
" colorscheme wombat256 " xoria256 is good too :)
colorscheme hemisu
set background=dark
set guifont=Source\ Code\ Pro:h14

" === Vundle ===
source ~/.vim/config/vundle.vim

syntax on

" === Undo ===
silent !mkdir ~/.vim/backups > /dev/null 2>&1
set undodir=~/.vim/backups
set undofile

" === Indentation ===
set autoindent
set smartindent
set smarttab
set shiftwidth=2
set softtabstop=2
set tabstop=2
set expandtab

" Display tabs and trailing spaces visually
set list listchars=tab:\ \ ,trail:·

set nowrap
set linebreak

" === Scrolling ===
set scrolloff=8
set sidescrolloff=15
set sidescroll=1

source ~/.vim/config/bindings.vim
source ~/.local.vimrc

