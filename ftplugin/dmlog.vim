" File: dmlog.vim
" Author: lymslive
" Description: support logview
" Last Modified: 2016-08-31

" Load Control: "{{{1
let s:thispath = fnamemodify(expand("<sfile>"), ":p:h")
if filereadable(s:thispath . '/' . 'setlocal.vim') 
    if fnamemodify(expand("<sfile>"), ":t:r") !=? 'setlocal'
        execute 'source ' . s:thispath . '/' . 'setlocal.vim'
        finish
    endif
endif

let s:debug = 1
if exists('b:logview_ftplugin_loaded') && !exists('s:debug')
    finish
endif
let s:logview_ftplugin_loaded = 1

set foldmethod=manual

" Buffer Data: "{{{1
let b:file_ext = expand('%:t:e')
if b:file_ext ==? 'log' || b:file_ext ==? 'error'
    set readonly
    set nomodifiable
endif

if expand('%:t:r') =~# '^-\d*$'
    set buftype=nowrite
endif

if !exists('b:dLastCmd')
    let b:dLastCmd = {'lead': '#', 'line': '# '}
endif

if !exists('b:last_search_line')
    let b:last_search_line = 0
    let b:last_search_text = ''
endif

augroup AU_LOGVIEW_FTPLUGIN
    autocmd!
    " this one is which you're most likely to use?
    autocmd InsertEnter <buffer> call logcedit#OnInsertEnter()
augroup end

" Maps: "{{{1
" try to execute current line
nnoremap <buffer> <CR> :call logecmd#NormalEnter()<CR>
inoremap <buffer> <CR> <C-R>=logecmd#InsertEnter()<CR>

" block jump
" first arg can be ':#$%' to search specified cmd type, or defaut any
nnoremap <buffer> [[ :call logview#JumptoCommadLine('', 'bW')<CR>
nnoremap <buffer> ]] :call logview#JumptoCommadLine('', 'W')<CR>
nnoremap <buffer> [= :call logview#JumptoOutputEdge('=', 'bW')<CR>
nnoremap <buffer> ]= :call logview#JumptoOutputEdge('=', 'W')<CR>
nnoremap <buffer> [. :call logview#JumptoOutputEdge('.', 'bW')<CR>
nnoremap <buffer> ]. :call logview#JumptoOutputEdge('.', 'W')<CR>
" block selection
onoremap <buffer> = :call logview#SelectOutput()<CR>
vnoremap <buffer> = :<C-U>call logview#SelectOutput()<CR>

" pipe bar command 
nnoremap <buffer> <bar> :call logcedit#NextPipe()<CR>
onoremap <buffer> <bar> :call logcedit#SelectPipe()<CR>
vnoremap <buffer> <bar> :<C-U>call logcedit#SelectPipe()<CR>
inoremap <buffer> <bar> <C-R>=logcedit#InputPipe()<CR>

" Goto command line, begin of line(Bol), or end of line(Eol)
" Bol ignore the command lead marker
" Also in effect when on output range, then first jump head cmdline
nnoremap <buffer> H <ESC>:call logcedit#GotoCmdBol()<CR>
nnoremap <buffer> I <ESC>:call logcedit#GotoCmdBol()<CR>i
nnoremap <buffer> L <ESC>:call logcedit#GotoCmdEol()<CR>
nnoremap <buffer> A <ESC>:call logcedit#GotoCmdEol()<CR>a
inoremap <buffer> <C-A> <ESC>:call logcedit#GotoCmdBol()<CR>i
inoremap <buffer> <C-E> <ESC>:call logcedit#GotoCmdEol()<CR>a

" open a new line, automatic insert the last used command lead marker
nnoremap <buffer> O <ESC>:call logcedit#OpenCmdAbove()<CR>a
nnoremap <buffer> o <ESC>:call logcedit#OpenCmdBelow()<CR>a
" insert mode, o insert last command in smart way
inoremap <buffer> o <C-R>=logcedit#InputLastCmd('o')<CR>

" remove current command line
inoremap <buffer> <C-U> <C-R>=logcedit#RemoveCmdLine()<CR>

" search command line in file
inoremap <buffer> <C-P> <C-R>=logcedit#IRetriveCommand(-1)<CR>
inoremap <buffer> <C-N> <C-R>=logcedit#IRetriveCommand(1)<CR>

" switch command line lead marker
" args can be one char of ':#$%' or '' to cycle in it
command! -buffer -nargs=? SwitchCmdLead call logcedit#SwitchCmdLead(<q-args>)
nnoremap <buffer> <C-A> @=logview#Executable() ? ":SwitchCmdLead\<lt>CR>" : "\<lt>C-A>"<CR>
inoremap <buffer> <C-T> <C-O>:SwitchCmdLead<CR>

" load the last command but change the last pipe part
" NOT :inoremap, to recursively use the remap
imap <buffer> <C-G><C-P> <C-P><C-O>c<bar>

" copy the current command line to the end of file
nnoremap <buffer> yy @=logview#Executable()? 'yyGp' : 'yy'<CR>

" borrow some vim command line as log in-file command line
command! -buffer -nargs=+ READ call logecmd#ReadCommand(<q-args>)
cnoremap <buffer> <C-G> <C-\>e logecmd#TransferCommand('READ')<CR>

" add piped grep command, with 3 aurgs
" a:1 word, a:1 back replace origin pipe, a:3 where put new command
command! -buffer -nargs=+ PipeGrep call logerout#PipeGrep(<f-args>)
" map, pipe grep current word
nnoremap <buffer> gr :PipeGrep <C-R>=expand('<cword>')<CR> 0 1<CR>
nnoremap <buffer> gR :PipeGrep <C-R>=expand('<cword>')<CR> 1 1<CR>
vnoremap <buffer> gr ygv:<C-\>e (visualmode() !=# 'v')? "'<,'>" : 'PipeGrep ' . getreg() .  ' 0 1'<CR>
vnoremap <buffer> gR ygv:<C-\>e (visualmode() !=# 'v')? "'<,'>" : 'PipeGrep ' . getreg() .  ' 1 1'<CR>

" read a file in new tab buffer, use cat command
command! -buffer -nargs=? CatFile call logerout#CatFile(<f-args>)
nnoremap <buffer> gF :CatFile<CR>

finish
===============
