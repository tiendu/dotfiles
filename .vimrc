" Basic Settings
set number                          " Show line numbers
set relativenumber                  " Show relative line numbers
set hlsearch                        " Highlight search results
set incsearch                       " Incremental search
set ignorecase                      " Ignore case in search patterns
set smartcase                       " Override ignorecase if search pattern contains uppercase
set noexpandtab                     " Use actual tab characters
set tabstop=4                       " A tab equals 4 spaces visually
set shiftwidth=4                    " Auto-indent uses 4 spaces width
set softtabstop=4                   " Tab in insert mode uses 4 spaces
set nowrap                          " Disable line wrapping
set cursorline                      " Highlight the current line
set clipboard=unnamedplus           " Use system clipboard for yanking and pasting

" Enable list mode to show whitespace characters
set list

" Customize list characters
set listchars=tab:▸\ ,trail:·,extends:>,precedes:<,eol:↴

" Key Mappings
" Set the leader key to space
let mapleader=" "

" Save and quit
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>

" Move lines up and down
nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
inoremap <A-j> <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv

" Map keys to Esc
inoremap jk <Esc>
inoremap kj <Esc>
inoremap jj <Esc>
inoremap kk <Esc>

" Navigate in insert mode
inoremap <C-k> <Esc>ka
inoremap <C-j> <Esc>ja
inoremap <C-h> <Esc>ha
inoremap <C-l> <Esc>la

" Enable the status line
set laststatus=2
set statusline=%f\ %y\ %m\ %r\ %l/%L\ %c

" Set color for line numbers
set termguicolors
highlight LineNr guifg=#FF0000        " Red color for line numbers
highlight CursorLineNr guifg=#00FF00  " Green color for the current line number

" Customize the highlight groups for list characters
highlight Whitespace guifg=#808080    " Grey color for whitespace
highlight TabLine guifg=#808080       " Grey color for tab line
highlight EndOfLine guifg=#808080     " Grey color for end of line
highlight CursorLine cterm=underline  " Underline the current line
