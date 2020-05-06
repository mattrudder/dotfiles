augroup filetypedetect
  " Git commit message
  autocmd Filetype gitcommit                         setlocal spell tw=72 colorcolumn=73
  " Go shortcuts
  au FileType go nmap <leader>t <Plug>(go-test)
  au FileType go nmap <Leader>r <Plug>(go-rename)
  au FileType go nmap <leader>c <Plug>(go-coverage)
  " Shorter columns in text
  autocmd Filetype tex setlocal spell tw=80 colorcolumn=81
  autocmd Filetype text setlocal spell tw=72 colorcolumn=73
  autocmd Filetype markdown setlocal spell tw=72 colorcolumn=73
  " No autocomplete in text
  autocmd Filetype tex let g:deoplete#enable_at_startup = 0
  autocmd Filetype text let g:deoplete#enable_at_startup = 0
  autocmd Filetype markdown let g:deoplete#enable_at_startup = 0
  " clang format
  autocmd FileType c,cpp ClangFormatAutoEnable
augroup END
