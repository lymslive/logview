" File: dmlog.vim
" Author: lymslive
" Description: support logview
" Last Modified: 2016-08-31

let b:file_ext = expand('%:t:e')
if b:file_ext ==? 'log' || b:file_ext ==? 'error'
    set readonly
    set nomodifiable
endif

let b:dLastCmd = {'lead': '#', 'line': '# '}

" try to execute current line
nnoremap <buffer> <CR> :call logecmd#NormalEnter()<CR>
inoremap <buffer> <CR> <C-R>=logecmd#InsertEnter()<CR>

" block jump
nnoremap <buffer> [[ :call logview#JumptoCommadLine('', 'bW')<CR>
nnoremap <buffer> ]] :call logview#JumptoCommadLine('', 'W')<CR>
nnoremap <buffer> [= :call logview#JumptoOutputEdge('=', 'bW')<CR>
nnoremap <buffer> ]= :call logview#JumptoOutputEdge('=', 'W')<CR>
nnoremap <buffer> [. :call logview#JumptoOutputEdge('.', 'bW')<CR>
nnoremap <buffer> ]. :call logview#JumptoOutputEdge('.', 'W')<CR>
" block selection
onoremap <buffer> = :call logview#SelectOutput()<CR>
vnoremap <buffer> = :<C-U>call logview#SelectOutput()<CR>

" command selection
onoremap <buffer> <bar> :call logcedit#SelectPipe()<CR>
vnoremap <buffer> <bar> :<C-U>call logcedit#SelectPipe()<CR>

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

inoremap <buffer> <C-P> <C-R>=logcedit#IRetriveCommand(-1)<CR>
inoremap <buffer> <C-N> <C-R>=logcedit#IRetriveCommand(1)<CR>

" load the last command but change the last pipe part
" NOT :inoremap, to recursively use the remap
imap <buffer> <C-G><C-P> <C-P><C-O>c<bar>

" donot reload functions
if exists('s:function_loaded') && !exists('s:debug')
   finish
endif

let s:function_loaded = 1
finish
===============
