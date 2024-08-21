set nocompatible              " be iMproved, required
set shell=/usr/bin/zsh
filetype off                  " required
" ==== some configurations
set number
"set rtp+=~/.fzf
set tabstop=2
set mouse=a
"set t_Co=256
set splitbelow
set splitright
set termguicolors


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
Plugin 'vim-airline/vim-airline-themes'

" === plugins thet better to install
"Plugin 'majutsushi/tagbar'
Plugin 'kien/ctrlp.vim'
"Plugin 'tpope/vim-fugitive'
Plugin 'airblade/vim-gitgutter'
Plugin 'vim-syntastic/syntastic'
"Plugin 'terryma/vim-multiple-cursors'
Plugin 'plasticboy/vim-markdown'
Plugin 'reedes/vim-pencil'
Plugin 'morhetz/gruvbox'

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
let g:vim_markdown_conceal = 0
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
"let g:airline_theme='powerlineish'
let g:airline_theme='gruvbox'
let g:airline#extensions#tabline#enabled = 1

" ==== GRUVBOX
syntax enable
colorscheme gruvbox
set background=dark

" ==== highlighting whitespace and each 80th character
highlight ExtraWhitespace ctermbg=darkgray guibg=darkgray
match ExtraWhitespace /\s\+$\|^\s\+\ze\S/
call matchadd('ErrorMsg', '\%81v', 100)

" ==== vim antipatterns
" thank's to Tom Ryder
noremap OA <nop>
noremap OB <nop>
noremap OC <nop>
noremap OD <nop>
noremap [1~ <nop>
noremap [4~ <nop>
noremap [5~ <nop>
noremap [6~ <nop>

"noremap <Up> <nop>
"noremap <Down> <nop>
"noremap <Left> <nop>
"noremap <Right> <nop>
"noremap <home> <nop>
"noremap <end> <nop>
"noremap <pageup> <nop>
"noremap <pagedown> <nop>

" ==== transparent background
hi Normal guibg=NONE ctermbg=NONE
