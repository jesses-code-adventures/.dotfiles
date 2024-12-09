" global options
set guicursor=
set nu
set relativenumber

syntax on

set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab

set smartindent
set nowrap

set noswapfile
set nobackup
set undodir=~/.vim/undodir-vanilla-vim
set undofile

set nohlsearch
set incsearch

set scrolloff=999
set signcolumn=auto
set isfname+=@-@

set updatetime=10
set colorcolumn=0
set laststatus=3

" netrw settings
let g:netrw_browse_split = 0
let g:netrw_banner = 0
let g:netrw_winsize = 25

" set leader key
let mapleader = " "

" key mappings
nnoremap <leader>pv :Ex<CR>
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv
nnoremap J mzJ`z
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz
nnoremap n nzzzv
nnoremap N Nzzzv
xnoremap <leader>pp "_dP
nnoremap <leader>y "+y
vnoremap <leader>y "+y
nnoremap <leader>Y "+Y
nnoremap <leader>d "_d
vnoremap <leader>d "_d
inoremap <C-e> <Esc>
nnoremap Q <nop>
nnoremap <C-Up> :resize +10<CR>
nnoremap <C-Down> :resize -10<CR>
nnoremap <C-Left> :vertical resize -10<CR>
nnoremap <C-Right> :vertical resize +10<CR>
nnoremap <leader>gt :vsplit<CR><C-w>L:vertical resize -60<CR>:terminal<CR>
tnoremap <Esc><Esc> <C-\><C-n>

" wrap markdown text on resize
autocmd FileType,VimResized markdown setlocal textwidth=76 wrap breakindent linebreak formatoptions+=t

" syntax highlighting for .env files
autocmd BufNewFile,BufRead *.env.* set filetype=sh

colorscheme elflord
