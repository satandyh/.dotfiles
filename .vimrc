set nocompatible              " be iMproved, required
set shell=/usr/bin/bash
filetype off                  " required
" ==== some configurations
set number
set rtp+=~/.fzf
set tabstop=4
set mouse=a

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
" === plugin manager
Plugin 'VundleVim/Vundle.vim'

" === plugins that just #should be#
Plugin 'scrooloose/nerdtree'
"Plugin 'valloric/youcompleteme'
Plugin 'vim-airline/vim-airline'

" === plugins thet better to install
Plugin 'majutsushi/tagbar'
Plugin 'kien/ctrlp.vim'
Plugin 'tpope/vim-fugitive'
Plugin 'airblade/vim-gitgutter'
Plugin 'vim-syntastic/syntastic'
"Plugin 'terryma/vim-multiple-cursors'
Plugin 'plasticboy/vim-markdown'
Plugin 'reedes/vim-pencil' 

" === plugins named snippets - for programming languages
Plugin 'sirver/ultisnips'
Plugin 'honza/vim-snippets'

" ===============================================
" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
" filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

" ==== NERDTREE
" === this one from https://github.com/sebbekarlsson/i3/blob/master/.vimrc
"let NERDTreeIgnore = ['__pycache__', '\.pyc$', '\.o$', '\.so$', '\.a$', '\.swp', '*\.swp', '\.swo', '\.swn', '\.swh', '\.swm', '\.swl', '\.swk', '\.sw*$', '[a-zA-Z]*egg[a-zA-Z]*', '.DS_Store']

let NERDTreeShowHidden=1
let g:NERDTreeWinPos="left"
let g:NERDTreeDirArrows=0
"map <C-t> :NERDTreeToggle<CR>
map <F3> :NERDTreeToggle<CR>

" === just look
"autocmd VimEnter * NERDTree .

" ==== VIM-MARKDOWN
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_toc_autofit = 1
"let g:vim_markdown_emphasis_multiline = 1
"let g:vim_markdown_auto_insert_bullets = 0
"let g:vim_markdown_new_list_item_indent = 0

" ==== VIM-PENCIL
let g:pencil#wrapModeDefault = 'soft'

augroup pencil
  autocmd!
" because I like this plugin
"  autocmd FileType markdown,mkd,md call pencil#init()
"  autocmd FileType text         call pencil#init()
  autocmd FileType * call pencil#init()
augroup END


" ==== VIM-AIRLINE
let g:airline_section_x = '%{PencilMode()}'
