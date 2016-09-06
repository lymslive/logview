" File: logview.vim
" Author: lymslive
" Description: support logview, overall command utility
" Create: 2016-08-31
" Modify: 2016-09-03

let s:debug = 1

" Data Var Define:  "{{{1
let s:output_start = repeat('=', 75) . ' <<'
let s:output_stop = '.'

let s:dCommander = {'vim': ':', 'rshell': '#', 'ushell': '$', 'math': '%'}
let s:lCommander = ':#$%'

" Pattern Define:
let s:dPattern = {}
" match lead part
let s:dPattern.leader = '^[:#$%]\ze\s*'
" only match lead
let s:dPattern.valid = '^[:#$%]\s\?$'
" match output frame line
let s:dPattern.start = '^' . s:output_start
let s:dPattern.stop = '^\.$'
" match pure command string, remove leadmark
let s:dPattern.command = '^[:#$%]\s*\zs\w\+.*\S\ze\s*$'
" command arguments | command arguments >> out
let s:dPattern.redircmd = '^\s*\(.\{-}\)\s*\(>>\?\)\s*\(.\{-}\)\s*$'
" match [wsvt][file]
let s:dPattern.target = '^\s*\([wsvt]\?\)\(.\{-}\)\s*$'

" Line Type:
" usually is the first char of line
" 1. ' ' <Space> :indented line
" 2-5. leader command markder
" 6. '=', output range start line
" 7. '.', output range stop line
" 8. '<', output content line beteew '=' and '.'
let s:eLineType = {' ': 1, ':': 2, '#': 3, '$': 4, '%': 5, '=':6, '.':7, '<':8}

" ExportScriptVar: get a s:variable of this script "{{{1
" >a:varname, bare name without 's:' prefix
" <return, the var value, or empty string if non-exists varname
function! logview#ExportScriptVar(varname) "{{{
    try
        let l:value = s:{a:varname}
    catch 
        let l:value = ''
    endtry
    return l:value
endfunction "}}}

" GetLineType: return a char to indicate the line type "{{{1
function! logview#GetLineType(linenr) "{{{
    if a:linenr <= 0
        let l:iLine = line('.')
    else
        let l:iLine = a:linenr
    endif

    let l:linestr = getline(l:iLine)
    let l:cLeader = matchstr(l:linestr, s:dPattern.leader)

    if empty(l:cLeader)
        let [l:start, l:stop] = s:FindOutputRange(l:iLine)
        if l:start > 0 && l:stop > 0
            if l:linestr =~# s:dPattern.start
                let l:cLeader = '='
            elseif l:linestr =~# s:dPattern.stop
                let l:cLeader = '.'
            else
                let l:cLeader = '<'
            endif
        endif
    endif

    return l:cLeader
endfunction "}}}

" Executable: check if current is in-file command line
function! logview#Executable() "{{{
    let l:linenr = line('.')
    let l:lead = matchstr(getline(l:linenr), s:dPattern.leader)
    if empty(l:lead)
        return v:false
    else
        return v:true
    endif
endfunction "}}}
function! logview#OnOutput() "{{{
    let l:linenr = line('.')
    let l:lead = logview#GetLineType(l:linenr)
    if l:lead ==# '=' || l:lead ==# '.' || l:lead ==# '<'
        return v:true
    else
        return v:false
    endif
endfunction "}}}
function! logview#InOutput() "{{{
    let l:linenr = line('.')
    let l:lead = logview#GetLineType(l:linenr)
    if l:lead ==# '<'
        return v:true
    else
        return v:false
    endif
endfunction "}}}

" GetCmdLead: 
function! logview#GetCmdLead() "{{{
    let l:lead = matchstr(getline('.'), s:dPattern.leader)
    return l:lead
endfunction "}}}

" IsValidLead: 
function! logview#IsValidLead(lead) "{{{
    if a:lead =~# s:dPattern.valid
        return v:true
    else
        return v:false
    endif
endfunction "}}}

" OutputFrame: 
function! logview#OutputFrame() "{{{
    return [s:output_start, s:output_stop]
endfunction "}}}

" SelectOutput: text object betwen '== <<' and '.' lines  "{{{1
" include(i) or exclude(a) mode is depend on the cursor postion
function! logview#SelectOutput() "{{{
    let l:curline = line('.')
    let [l:start, l:stop] = s:FindOutputRange(l:curline)

    if l:start <= 0 || l:stop <= 0
        return "\<ESC>"
    endif

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

" JumptoCommandLine: travels in command header lines "{{{1
" a:1, char in any of '#$:', or determined by current line lead mark
" a:2, any other arugment pass to search() builtin as flags
function! logview#JumptoCommadLine(...) "{{{
    let l:cmdmark = ''
    if a:0 >= 1
        let l:cmdmark = a:1
    endif

    " try to use the command marker in current line
    if empty(l:cmdmark) || l:cmdmark ==# '0'
        let l:cmdmark = matchstr(getline('.'), s:dPattern.leader)
    endif

    " search flags, such as 'b'
    let l:flag = ''
    if a:0 >= 2
        let l:flag = a:2
    endif

    if empty(l:cmdmark)
        let l:pattern = s:dPattern.leader
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

" JumptoOutputEdge: travels in output area warpper lines "{{{1
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
        let l:pattern = s:dPattern.start
    elseif a:outmark == '.'
        let l:pattern = s:dPattern.stop
    else
        echoerr 'unexpected arguments: ' . a:outmark
        return 0
    endif

    return search(l:pattern, l:flag)
endfunction "}}}

" BufferNewLgFile: edit a buffer in other window"{{{1
" a:target = [wsvt]
"   w, default, in current window
"   s, splited window; v, vertical splited windw
"   t, new tab
" a:name, the file name, or auto numbered if empty input
function! logview#BufferNewLgFile(target, name) "{{{
    if empty(a:target) || len(a:target) > 1
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

    " update currnet buffer before to new
    update

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

" GetAutoLgName: auto nmebered file name"{{{1
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

" FindOutputRange: find a output range contain a specific line "{{{1
function! s:FindOutputRange(linenr) "{{{
    let l:ret = [0, 0]
    let l:end = line('$')
    if a:linenr > l:end || a:linenr < 1
        return l:ret
    endif

    " backward search output start line '= <<'
    let l:start = 0
    for l:index in range(a:linenr, 1, -1)
        let l:text = getline(l:index)
        if l:text =~# s:dPattern.start
            let l:start = l:index
            break
        endif
        " first find stop line '.'
        if l:text =~# s:dPattern.stop && l:index != a:linenr
            break
        endif
    endfor

    if l:start == 0
        return l:ret
    endif

    " forward find stop line '.'
    let l:stop = 0
    for l:index in range(a:linenr, l:end)
        let l:text = getline(l:index)
        if l:text =~# s:dPattern.stop
            let l:stop = l:index
            break
        endif
        " first find start line
        if l:text =~# s:dPattern.start && l:index != a:linenr
            break
        endif
    endfor

    if l:stop == 0
        return l:ret
    endif

    let l:ret = [l:start, l:stop]
    return l:ret
endfunction "}}}
