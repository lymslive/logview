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
let s:lead_mark_pattern = '^[#$:]\ze\s*'

" Public Interface Method: "{{{1

" Manage Output Range:
" select the text object which lines betwen '== <<' and '.', 
" include(i) or exclude(a) mode is depend on the cursor postion
function! logview#SelectOutput() "{{{
    let l:curline = line('.')

    let l:start = search('^'. s:output_start, 'bWcn')
    if l:start <= 0
        return "\<ESC>"
    endif

    let l:stop = l:start
    let l:end = line('$')
    for l:index in range(l:start + 1, l:end)
        let l:text = getline(l:index)
        if l:text =~# '^\.$'
            let l:stop = l:index
            break
        endif
    endfor

    " do nothing if the cursor if out of searched range
    if l:stop < l:curline || l:start > l:curline
        return "\<ESC>"
    endif

    let l:moves = 0
    if l:curline == l:start || l:curline == l:stop
        call cursor(l:start, 1)
        let l:moves = l:stop - l:start
    else
        call cursor(l:start+1, 1)
        let l:moves = l:stop - l:start - 2
    endif

    normal! V
    if l:moves > 0
        execute 'normal!' . (0+l:moves) . 'j'
    endif

    return 0
endfunction "}}}

" a:1, char in any of '#$:', or determined by current line lead mark
" a:2, any other arugment pass to search() builtin as flags
function! logview#JumptoCommadLine(...) "{{{
    let l:cmdmark = ''
    if a:0 >= 1
        let l:cmdmark = a:1
    endif

    " try to use the command marker in current line
    if empty(l:cmdmark)
        let l:curlinestr = getline('.')
        let l:lead = l:curlinestr[0]
        if l:lead =~# s:lead_mark_pattern
            let l:cmdmark = l:lead
        endif
    endif

    " search flags, such as 'b'
    let l:flag = ''
    if a:0 >= 2
        let l:flag = a:2
    endif

    if empty(l:cmdmark)
        let l:pattern = s:lead_mark_pattern
    else
        let l:pattern = '^' . l:cmdmark
    endif

    " backward search, first goto beginning, avoid stay inline
    if l:flag =~# 'b'
        normal! ^
    endif

    let l:target = search(l:pattern, l:flag)
    if l:target > 0
        normal! w
    endif

endfunction "}}}

" a:1, a char to say search start line '=' or stop line '.'
" a:2, flags pass to builtin search()
function! logview#JumptoOutputEdge(...) "{{{
    let a:outmark = '='
    if a:0 >= 1 && a:1 == '.'
        let a:outmark = '.'
    endif

    let l:flag = ''
    if a:0 >= 2
        let l:flag = a:2
    endif

    if a:outmark == '='
        let l:pattern = '^' . s:output_start . '$'
    elseif a:outmark == '.'
        let l:pattern = '^' . s:output_stop . '$'
    else
        echoerr 'unexpected arguments: ' . a:outmark
        return 0
    endif

    return search(l:pattern, l:flag)
endfunction "}}}

" Command Line Operate:
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

" assume command line format # cmd1 arg | cmd2 args | ...
" select a pipe part, include '|' char if cursor on it
function! logview#SelectPipe() "{{{
    let l:linenr = line('.')
    let l:linestr = getline('.')
    let l:curchar = l:linestr[col('.')-1]

    " not in command line
    if l:linestr !~# s:lead_mark_pattern
        return
    endif

    " no pipe at all, select the whole line
    if l:linestr !~# '\v\|'
        if &selection ==# 'inclusive'
            normal! ^wv$h
        else
            normal! ^wv$
        endif
        return
    endif

    let l:selbeg = col('.') - 1
    if l:curchar ==# '|'
        " the char under cursor is '|', selection begins with it
    else
        " selection begins next to the left '|' char
        let l:index = l:selbeg
        while l:index > 0
            let l:char = l:linestr[l:index - 1]
            if l:char ==# '|'
                break
            endif
            let l:index -= 1
            normal! h
        endwhile
        let l:selbeg = l:index

        if l:selbeg == 0
            normal! w
            let l:selbeg = col('.') - 1
        endif
    endif

    " selection ends to next '|' char, without next '|'
    let l:index = l:selbeg
    let l:end = col('$') - 1
    while l:index < l:end
        let l:char = l:linestr[l:index + 1]
        if l:char ==# '|'
            break
        endif
        let l:index += 1
    endwhile
    let l:selend = l:index

    " select to end of line, the &selection option matters
    if &selection ==# 'inclusive' && l:selend == l:end
        let l:selend -= 1
    endif

    let l:len = l:selend - l:selbeg
    execute 'normal! v' . l:len . 'l'
endfunction "}}}
" Insert Mode:
" enter: <CR>
function! logview#IEnter() "{{{
    let l:linenr = line('.')
    let l:linestr = getline('.')
    let l:cmdstr = matchstr(l:linestr, '^[#$:]\s*\zs\w\+.*\S\ze\s*$')
    if empty(l:cmdstr)
        return "\<CR>"
    endif

    let l:first_char = l:linestr[0]
    if l:first_char ==# s:shell_command_mark || l:first_char ==# s:shell_command_mark_alt
        " has '>' redirection char, open a new buffer
        let l:redircmd = split(l:cmdstr, '>', 1)
        if len(l:redircmd) > 1
            let l:ret = s:ExectueInNewBuff(l:first_char, l:redircmd)
            if l:ret
                return "\<Esc>"
            else
                return "\<CR>"
            endif
        endif

        " output in current buffer
        call s:PrepareOutput()
        let l:cmd = (1+l:linenr) . 'r !' . l:cmdstr
        echo 'shell command is running, wait a long or short time ...'
        execute l:cmd
        echo 'shell command done!'
        return "\<ESC>"

    elseif l:first_char ==# s:vim_command_mark
        let l:cmd = strpart(l:linestr, 1)
        execute l:cmd
        return "\<ESC>"

    else
        return "\<CR>"
    endif
endfunction "}}}

" <C-P> <C-N>
" TODO: now only support press once
function! logview#IRetriveCommand(direction) "{{{
    let l:start = line('.')

    let l:lastcmd = s:GetLastCommandLine('', a:direction, l:start)
    if empty(l:lastcmd.mark) || l:lastcmd.line == 0
        return ''
    endif

    let l:curlinestr = getline('.')
    if l:curlinestr !=# l:lastcmd.text
        call setline('.', l:lastcmd.text)
    endif

    return "\<End>"
endfunction "}}}

" input last command mark '#$:', bind to `nnoremap o`
function! logview#IRepeatLastCmdMark() "{{{
    let l:start = line('.')

    let l:pattern = s:lead_mark_pattern
    let l:target = search(l:pattern, 'bnW')
    if l:target <= 0
        let l:mark = '#'
    else
        let l:linestr = getline(l:target)
        let l:mark = l:linestr[0]
    endif

    return l:mark . ' '
endfunction "}}}

" Private Helper Functions: "{{{1
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

    return s:EmptyOutput(l:linenr + 1)
endfunction "}}}

function! s:EmptyOutput(...) "{{{
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

function! s:NewOutputMarkLine() "{{{
    let l:linenr = line('.')
    call append(l:linenr, s:output_stop)
    call append(l:linenr, s:output_start)
    return 0
endfunction "}}}

let s:last_sreach_line = 0
function! s:GetLastCommandLine(marker, direction, start) "{{{
    " returned data struct
    let l:ret = {'line':0, 'mark':'', 'text':''}

    let l:cmdmark = a:marker
    if empty(l:cmdmark)
        let l:curlinestr = getline('.')
        let l:lead = l:curlinestr[0]
        if l:lead =~# s:lead_mark_pattern
            let l:cmdmark = l:lead
        endif
    endif

    if l:cmdmark !~# s:lead_mark_pattern
        return l:ret
    endif

    let l:ret.mark = l:cmdmark
    let l:pattern = '^' . l:cmdmark

    " default search forward
    let l:direction = 1
    if a:direction == -1
        let l:direction = -1
    endif

    let l:end = line('$')
    let l:index = a:start

    while v:true
        let l:index += l:direction
        if l:index < 1 || l:index > l:end
            break
        endif
        let l:linestr = getline(l:index)
        if l:linestr =~# l:pattern
            let l:ret.line = l:index
            let l:ret.text = l:linestr
            break
        endif
    endwhile

    return l:ret
endfunction "}}}

" GetAutoLgName: "{{{2
" auto newed *.lg files is numbered, as 1.lg, 2.lg ...
" find a unused(opened) number for a new lg file
function! s:GetAutoLgName(base) "{{{
    let l:base = 0 + a:base
    let l:number = l:base
    while v:true
        let l:number += 1
        let l:lgname = l:number . '\.lg'
        if bufnr(l:lgname) == -1
            break
        endif
    endwhile
    return l:number
endfunction "}}}

" BufferNewLgFile: "{{{2
" a:target = [wsvt]
"   w, default, in current window
"   s, splited window; v, vertical splited windw
"   t, new tab
" a:name, the file name, or auto numbered if empty input
function! s:BufferNewLgFile(target, name) "{{{
    if empty(a:target) || l:len(a:target) > 1
        let l:target = 'w'
    else
        let l:target = a:target
    endif

    if empty(a:name)
        let l:curnumber = expand('%:r')
        let l:newnumber = s:GetAutoLgName(l:curnumber)
        let l:name = l:newnumber . '.lg'
    else
        let l:name = a:name
    endif

    if a:target ==? 'w'
        execute 'edit ' . l:name
    elseif a:target ==? 's'
        execute 'split ' . l:name
    elseif a:target ==? 'v'
        execute 'vertical split ' . l:name
    elseif a:target ==? 't'
        execute 'tabedit ' . l:name
    else
        echoerr 'unexpected new buffer target window [wsvt]'
    endif
endfunction "}}}

" a:leadmark, '#' or '$'
" a:redircmd, [cmd, redir-target]
function! s:ExectueInNewBuff(leadmark, redircmd) "{{{
    if len(a:redircmd) < 2
        return 0
    endif

    let l:cmd = a:redircmd[0]
    let l:tar = a:redircmd[1]
    let l:tar_list = matchlist(l:tar, '^\s*\([wsvt]\?\)\(.*\S\)\s*$')
    if empty(l:tar_list)
        let l:target = 'w'
        let l:name = ''
    else
        let l:target = l:tar_list[1]
        let l:name = l:tar_list[2]
    endif

    call s:BufferNewLgFile(l:target, l:name)
    normal! G
    call append(line('$'), a:leadmark . ' ' . l:cmd)
    let l:linenr = line('$')

    call s:PrepareOutput()
    let l:cmd = (1+l:linenr) . 'r !' . l:cmd
    echo 'shell command is running, wait a long or short time ...'
    execute l:cmd
    echo 'shell command done!'

    return 1
endfunction "}}}

