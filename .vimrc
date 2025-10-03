syntax on
filetype on
set noswapfile
set number
set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4
set autoindent
set nobackup
set hlsearch
set showmatch
inoremap " ""<left>
inoremap ' ''<left>
inoremap ( ()<left>
inoremap [ []<left>
inoremap { {}<left>
inoremap <expr> " getline('.')[col('.')-1] == '"' ? "\<Right>" : "\"\"\<Left>"
inoremap <expr> ' getline('.')[col('.')-1] == "'" ? "\<Right>" : "''\<Left>"
inoremap <expr> ) getline('.')[col('.')-1] == ')' ? "\<Right>" : ")"
inoremap <expr> ] getline('.')[col('.')-1] == ']' ? "\<Right>" : "]"
inoremap <expr> } getline('.')[col('.')-1] == '}' ? "\<Right>" : "}"
inoremap {<CR> {<CR>}<ESC>O
inoremap {;<CR> {<CR>};<ESC>O
inoremap <expr> <Tab> match(getline('.')[col('.')-1], '[)\]}",'']') != -1 ? "\<Right>" : "\<Tab>"

call plug#begin('~/.vim/plugged')
Plug 'tpope/vim-surround'
call plug#end()

