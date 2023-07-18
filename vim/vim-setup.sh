#!/bin/bash

echo "Setup env to install vim plugins"

if [ ! -d ~/.vim ]; then
	echo "create ~/.vim directory"
	mkdir -p ~/.vim/autoload ~/.vim/bundle && wget -O ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
fi

[ ! -f ~/.vimrc ] && echo "execute pathogen#infect()" > ~/.vimrc && echo "syntax on" >> ~/.vimrc && echo "filetype plugin indent on" >> ~/.vimrc

cd ~/.vim/bundle && \
	 git clone https://github.com/vim-airline/vim-airline.git && \
	 git clone https://github.com/vim-airline/vim-airline-themes.git && \
	 git clone https://github.com/preservim/nerdtree.git && \
	 git clone https://github.com/kien/ctrlp.vim.git && \
	 git clone https://github.com/ycm-core/YouCompleteMe.git && \
	 git clone https://github.com/vim-scripts/cscope.vim.git

if [ -f ~/.vimrc ]; then
cat << EOT >> ~/.vimrc
" ******* New added section (for c code better formatting)

filetype plugin indent on
nmap <C-J> vip=                         " forces (re)indentation of a block of code

syntax on

set noexpandtab                         " use tabs, not spaces
set tabstop=8                           " tabstops of 8
set shiftwidth=8                        " indents of 8
set textwidth=78                        " screen in 80 columns wide, wrap at 78

" ***** For Git use
set colorcolumn=81
" However, in Git commit messages, let’s make it 72 characters
autocmd FileType gitcommit set textwidth=72
autocmd FileType gitcommit set colorcolumn=73

set autoindent smartindent              " turn on auto/smart indenting
set smarttab                            " make <tab> and <backspace> smarter
set backspace=eol,start,indent          " allow backspacing over indent, eol, & start

syn keyword cType uint ubyte ulong uint64_t uint32_t uint16_t uint8_t boolean_t int64_t int32_t int16_t int8_t u_int64_t u_int32_t u_int16_t u_int8_t

syn keyword cOperator likely unlikely

syn match ErrorLeadSpace /^ \+/         " highlight any leading spaces
syn match ErrorTailSpace / \+$/         " highlight any trailing spaces
" match Error80           /\%>80v.\+/    " highlight anything past 80 in red ===========> actually doea not work

if has("gui_running")
"       hi Error80        gui=NONE   guifg=#ffffff   guibg=#6e2e2e ===========> actually doea not work
       hi ErrorLeadSpace gui=NONE   guifg=#ffffff   guibg=#6e2e2e
       hi ErrorTailSpace gui=NONE   guifg=#ffffff   guibg=#6e2e2e
" else  =======> Not needed branch
"        exec "hi Error80        cterm=NONE   ctermfg=" . <SID>X(79) . " ctermbg=" . <SID>X(32)
"       exec "hi ErrorLeadSpace cterm=NONE   ctermfg=" . <SID>X(79) . " ctermbg=" . <SID>X(33)
"        exec "hi ErrorTailSpace cterm=NONE   ctermfg=" . <SID>X(79) . " ctermbg=" . <SID>X(33)
endif

set formatoptions=tcqlron

set cinoptions=:0,l1,t0,g0

" set foldmethod=syntax

" set tags=/home/khaled/workspace/linux-janitors/linux/tags
set tags=./tags,./TAGS,tags,TAGS

" ***************


" Airline
let g:airline#extensions#tabline#enabled = 1 " Enable the list of buffers
let g:airline#extensions#tabline#fnamemod = ':t' " Show just the filename

" -----------Buffer Management---------------
set hidden " Allow buffers to be hidden if you've modified a buffer

let mapleader = " " " map leader to Space

" Move to the next buffer
nmap <leader>l :bnext<CR>

" Move to the previous buffer
nmap <leader>h :bprevious<CR>

" Close the current buffer and move to the previous one
" This replicates the idea of closing a tab
nmap <leader>q :bp <BAR> bd #<CR>

" Show all open buffers and their status
nmap <leader>bl :ls<CR>

" Use arrow keys to navigate window splits
nnoremap <silent> <Right> :wincmd l <CR>
nnoremap <silent> <Left> :wincmd h <CR>
noremap <silent> <Up> :wincmd k <CR>
noremap <silent> <Down> :wincmd j <CR>

" ctrl-p
let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/](\.(git|hg|svn)|\_site)$',
  \ 'file': '\v\.(exe|so|dll|class|png|jpg|jpeg)$',
\}

" Use the nearest .git|.svn|.hg|.bzr directory as the cwd
let g:ctrlp_working_path_mode = 'r'
nmap <leader>p :CtrlP<cr>  " enter file search mode

" Nerdtree
autocmd vimenter * NERDTree
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
map <C-n> :NERDTreeToggle<CR>  " open and close file tree
nmap <leader>n :NERDTreeFind<CR>  " open current buffer in file tree

" Modify below if you want less invasive autocomplete
let g:ycm_semantic_triggers =  {
  \   'c' : ['->', '.'],
  \   'objc' : ['->', '.'],
  \   'cpp,objcpp' : ['->', '.', '::'],
  \   'perl' : ['->'],
  \ }

let g:ycm_complete_in_comments_and_strings=1
let g:ycm_key_list_select_completion=['<C-n>', '<Down>']
let g:ycm_key_list_previous_completion=['<C-p>', '<Up>']
let g:ycm_autoclose_preview_window_after_completion = 1

" let g:ycm_global_ycm_extra_conf = '/home/khaled/.vim/plugged/YouCompleteMe/third_party/ycmd/.ycm_extra_conf.py'

set completeopt-=preview

" shall add CSCOPE_DB to /home/$USER/.bashrc file (CSCOPE_DB=*/cscope.out; export $CSCOPE_DB)
cs add $CSCOPE_DB

:set number
:set mouse=a

" ******** Linux Coding Style

if exists("g:loaded_linuxsty")
    finish
endif
let g:loaded_linuxsty = 1

set wildignore+=*.ko,*.mod.c,*.order,modules.builtin

augroup linuxsty
    autocmd!

    autocmd FileType c,cpp call s:LinuxConfigure()
    autocmd FileType diff,kconfig setlocal tabstop=8
augroup END

function s:LinuxConfigure()
    let apply_style = 0

    if exists("g:linuxsty_patterns")
        let path = expand('%:p')
        for p in g:linuxsty_patterns
            if path =~ p
                let apply_style = 1
                break
            endif
        endfor
    else
        let apply_style = 1
    endif

    if apply_style
        call s:LinuxCodingStyle()
    endif
endfunction

command! LinuxCodingStyle call s:LinuxCodingStyle()

function! s:LinuxCodingStyle()
    call s:LinuxFormatting()
    call s:LinuxKeywords()
    call s:LinuxHighlighting()
endfunction

function s:LinuxFormatting()
    setlocal tabstop=8
    setlocal shiftwidth=8
    setlocal softtabstop=8
    setlocal textwidth=80
    setlocal noexpandtab

    setlocal cindent
    setlocal cinoptions=:0,l1,t0,g0,(0
endfunction

function s:LinuxKeywords()
    syn keyword cOperator likely unlikely
    syn keyword cType u8 u16 u32 u64 s8 s16 s32 s64
    syn keyword cType __u8 __u16 __u32 __u64 __s8 __s16 __s32 __s64
endfunction

function s:LinuxHighlighting()
    highlight default link LinuxError ErrorMsg

    syn match LinuxError / \+\ze\t/     " spaces before tab
    syn match LinuxError /\%81v.\+/     " virtual column 81 and more

    " Highlight trailing whitespace, unless we're in insert mode and the
    " cursor's placed right after the whitespace. This prevents us from having
    " to put up with whitespace being highlighted in the middle of typing
    " something
    autocmd InsertEnter * match LinuxError /\s\+\%#\@<!$/
    autocmd InsertLeave * match LinuxError /\s\+$/
endfunction

" vim: ts=4 et sw=4

" *************

EOT
fi

cd ~/.vim/bundle/YouCompleteMe && git submodule update --init --recursive
python3.6 install.py # the python version must be python3+ and shall install g++-8

# Install coccinelle vim syntax highlighting
pushd /home/actia-es/hacking/colinlk_tools/tools-box/vim
git clone https://github.com/ahf/cocci-syntax.git
cd cocci-syntax
make
make install
popd

cd

exit 0
