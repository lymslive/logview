" File: dmlog.vim
" Author: lymslive
" Description: support logview
" Last Modified: 2016-08-31

let s:debug = 1
let s:output_start = repeat('=', 75) . ' <<'
let s:output_stop = '.'
let s:shell_command_mark = '#'
let s:shell_command_mark_alt = '$'
let s:vim_command_mark = ':'
let s:lead_mark_pattern = '^[#$:]\?'

" GotoLineBeginning:
" jump to the beginning of the line but next to leading #$:
function! logview#GotoLineBeginning() "{{{
    let l:linestr = getline('.')
    if empty(l:linestr)
        return 0
    endif

    let l:first_char = l:linestr[0]
    if l:first_char ==# s:shell_command_mark
      \ || l:first_char ==# s:shell_command_mark_alt
      \ || l:first_char ==# s:vim_command_mark
        normal! ^w
    else
        normal! ^
    endif

endfunction "}}}

" Insert Mode Enter: <CR>
function! logview#IEnter() "{{{
    let l:linenr = line('.')
    let l:linestr = getline('.')
    if empty(l:linestr)
        return 0
    endif

    let l:first_char = l:linestr[0]
    if l:first_char ==# s:shell_command_mark || l:first_char ==# s:shell_command_mark_alt
        call s:PrepareOutput()
        let l:cmd = (1+l:linenr) . 'r !' . strpart(l:linestr, 1)
        execute l:cmd
        return "\<ESC>"

    elseif l:first_char ==# s:vim_command_mark
        let l:cmd = strpart(l:linestr, 1)
        execute l:cmd
        return "\<ESC>"

    else
        return "\<CR>"
    endif
endfunction "}}}

" make sure have two lines to mark output under current line
function! s:PrepareOutput() "{{{
    let l:linenr = line('.')
    if l:linenr >= line('$')
        return s:NewOutputMarkLine()
    endif

    let l:next_linestr = getline(l:linenr + 1)
    if l:next_linestr !~# '^'. s:output_start
        return s:NewOutputMarkLine()
    endif

    return logview#EmptyOutput(l:linenr + 1)
endfunction "}}}

function! s:NewOutputMarkLine() "{{{
    let l:linenr = line('.')
    call append(l:linenr, s:output_stop)
    call append(l:linenr, s:output_start)
    return 0
endfunction "}}}

" Empty Current Output Range:
function! logview#EmptyOutput(...) "{{{
    if a:0 >= 1
        let l:old_start = a:1
    else
        let l:old_start = search('^'. s:output_start, 'bWc')
    endif

    if l:old_start <= 0
        return -1
    endif

    let l:old_stop = search('^\.$', 'W')
    if l:old_stop == 0
        call append(line('$'), s:output_stop)
        let l:old_stop = line('$')
    endif

    if l:old_stop - l:old_start > 1
        let l:range = (l:old_start+1) . ',' . (l:old_stop-1)
        execute l:range . 'delete'
    endif

    return 0
endfunction "}}}
