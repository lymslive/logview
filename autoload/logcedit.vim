" File: logcedit.vim
" Author: lymslive
" Description: support logview, focus on in-file command line edit
" Create: 2016-09-03
" Modify: 2016-09-03

let s:dPattern = logview#ExportScriptVar('dPattern')

" GotoCmdBol:
" jump to the beginning of the line but next to leading marker #$:
" suggest map is: H I <C-A>
function! logcedit#GotoCmdBol() "{{{
    if logview#Executable()
        normal! ^w
    elseif logview#OnOutput()
        call logview#JumptoCommadLine('', 'bW')
    else
        normal! ^
    endif
endfunction "}}}

" GotoCmdEol:
" jump to the end of the line but next to leading marker #$:
" suggest map is: L A <C-E>
function! logcedit#GotoCmdEol() "{{{
    if logview#Executable()
        normal! $
    elseif logview#OnOutput()
        call logview#JumptoCommadLine('', 'bW')
        normal! $
    else
        normal! $
    endif
endfunction "}}}

" OpenCmdAbove:
" open a new line with last command lead above the head line
function! logcedit#OpenCmdAbove() "{{{
    let l:leadstr = b:dLastCmd.lead . ' '
    if logview#Executable()
        execute 'normal! O' . l:leadstr
    elseif logview#OnOutput()
        call logview#JumptoCommadLine('', 'bW')
        execute 'normal! O' . l:leadstr
    else
        normal! O
    endif
endfunction "}}}

" OpenCmdBelow:
" open a new line with last command lead below output stop line
function! logcedit#OpenCmdBelow() "{{{
    let l:leadstr = b:dLastCmd.lead . ' '
    let l:type = logview#GetLineType(line('.'))
    if empty(l:type)
        normal! o
    else
        if l:type !=# logview#ExportScriptVar('output_stop')
            call logview#JumptoOutputEdge('.', 'W')
        endif
        execute 'normal! o' . l:leadstr
    endif
endfunction "}}}

function! logcedit#MationPipe(...) "{{{
endfunction "}}}

" SelectPipe:
" assume command line format # cmd1 arg | cmd2 args | ...
" select a pipe part, include '|' char if cursor on it
function! logcedit#SelectPipe() "{{{
    let l:linenr = line('.')
    let l:linestr = getline('.')
    let l:curchar = l:linestr[col('.')-1]

    " not in command line
    if logview#Executable() == v:false
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

function! logcedit#LastCmdLead(...) "{{{
endfunction "}}}

function! logcedit#LastCmdLine(...) "{{{
endfunction "}}}

function! logcedit#LookupCmdLine(...) "{{{
endfunction "}}}

" <C-P> <C-N>
" TODO: now only support press once
function! logcedit#IRetriveCommand(direction) "{{{
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
function! logcedit#IRepeatLastCmdMark() "{{{
    let l:start = line('.')

    let l:pattern = s:dPattern.leader
    let l:target = search(l:pattern, 'bnW')
    if l:target <= 0
        let l:mark = '#'
    else
        let l:linestr = getline(l:target)
        let l:mark = l:linestr[0]
    endif

    return l:mark . ' '
endfunction "}}}

function! s:GetLastCommandLine(marker, direction, start) "{{{
    " returned data struct
    let l:ret = {'line':0, 'mark':'', 'text':''}

    let l:cmdmark = a:marker
    if empty(l:cmdmark)
        let l:cmdmark = logview#GetCmdLead()
    endif

    if logview#IsValidLead(l:cmdmark) == v:false
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

