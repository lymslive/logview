" File: dmlog.vim
" Author: lymslive
" Description: support logview
" Last Modified: 2016-08-31

let b:first_line = ''
let b:file_exte = ''

nnoremap <buffer> H <ESC>:call logview#GotoLineBeginning()<CR>
nnoremap <buffer> I <ESC>:call logview#GotoLineBeginning()<CR>i

inoremap <buffer> <CR> <C-R>=logview#IEnter()<CR>

" donot reload functions
if exists('s:function_loaded') && !exists('s:debug')
   finish
endif

let s:function_loaded = 1
finish
===============
