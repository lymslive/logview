" File: dmlog.vim
" Author: lymslive
" Description: support logview
" Last Modified: 2016-08-31

let b:first_line = ''
let b:file_exte = ''

" the beginning of line ignore the command lead marker
nnoremap <buffer> H <ESC>:call logview#GotoLineBeginning()<CR>
nnoremap <buffer> I <ESC>:call logview#GotoLineBeginning()<CR>i

" open a new line, automatic insert the last used command lead marker
nnoremap <buffer> o o<C-R>=logview#IRepeatLastCmdMark()<CR>
nnoremap <buffer> O O<C-R>=logview#IRepeatLastCmdMark()<CR>

" try to execute current line
inoremap <buffer> <CR> <C-R>=logview#IEnter()<CR>
inoremap <buffer> <C-P> <C-R>=logview#IRetriveCommand(-1)<CR>
inoremap <buffer> <C-N> <C-R>=logview#IRetriveCommand(1)<CR>

" block selection
onoremap <buffer> = :call logview#SelectOutput()<CR>
vnoremap <buffer> = :<C-U>call logview#SelectOutput()<CR>
" command selection
onoremap <buffer> <bar> :call logview#SelectPipe()<CR>
vnoremap <buffer> <bar> :<C-U>call logview#SelectPipe()<CR>

" load the last command but change the last pipe part
" NOT :inoremap, to recursively use the remap
imap <buffer> <C-G><C-P> <C-P><C-O>c<bar>

" block jump
nnoremap <buffer> [[ :call logview#JumptoCommadLine('', 'bW')<CR>
nnoremap <buffer> ]] :call logview#JumptoCommadLine('', 'W')<CR>
nnoremap <buffer> [= :call logview#JumptoOutputEdge('=', 'bW')<CR>
nnoremap <buffer> ]= :call logview#JumptoOutputEdge('=', 'W')<CR>
nnoremap <buffer> [. :call logview#JumptoOutputEdge('.', 'bW')<CR>
nnoremap <buffer> ]. :call logview#JumptoOutputEdge('.', 'W')<CR>

" donot reload functions
if exists('s:function_loaded') && !exists('s:debug')
   finish
endif

let s:function_loaded = 1
finish
===============
