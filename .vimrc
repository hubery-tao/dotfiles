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
set splitbelow
set splitright
set laststatus=2

set timeout
set timeoutlen=500
set ttimeout
set ttimeoutlen=50

if !has('gui_running')
  set t_Co=256
endif


" make spacebar the leader key
let mapleader=" "


nnoremap <Esc><Esc> :nohlsearch<CR>
nnoremap <leader>o :NERDTreeFocus<CR>
nnoremap <leader>t :botright terminal<CR><C-\><C-n>:resize 15<CR>i

"plugins
call plug#begin('~/.vim/plugged')
    Plug 'tpope/vim-surround'
    Plug 'itchyny/lightline.vim'
    Plug 'mg979/vim-visual-multi', {'branch': 'master'}
    Plug 'preservim/nerdtree'
    Plug 'jiangmiao/auto-pairs'
call plug#end()

