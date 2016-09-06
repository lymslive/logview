" File: logcedit.vim
" Author: lymslive
" Description: support logview, focus on in-file command line edit
" Create: 2016-09-03
" Modify: 2016-09-03

let s:dPattern = logview#ExportScriptVar('dPattern')

" GotoCmdBol: goto beginning of command line "{{{1
" but next to leading marker #$:
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

" GotoCmdEol: goto end of command line "{{{1
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

" OpenCmdAbove: open new command line above this block "{{{1
" above current head command line, atuo insert last lead mark
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

" OpenCmdBelow: open new command line below this block "{{{1
" below output stop line, atuo insert last lead mark
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

" InputLastCmd: smart insert last command's lead or full line "{{{1
" > a:key, the trigger key in insert mode, will insert itself when needed
function! logcedit#InputLastCmd(key) "{{{
    let l:linenr = line('.')
    let l:linestr = getline('.')

    if empty(l:linestr)
        return b:dLastCmd.lead . ' '
    elseif !logview#Executable()
        return a:key
    else
        if logview#IsValidLead(l:linestr)
            call setline(l:linenr, b:dLastCmd.line)
            return "\<End>"
        else
            return a:key
        endif
    endif

    return v:false
endfunction "}}}

" RemoveCmdLine: <C-U> remove line to command lead "{{{1
" but if only has command lead, remove full line
function! logcedit#RemoveCmdLine() "{{{
    if !logview#Executable()
        return "\<C-U>"
    endif

    let l:linestr = getline('.')
    if logview#IsValidLead(l:linestr)
        return "\<C-U>"
    endif

    let l:lead = logview#GetCmdLead()
    call setline('.', l:lead . ' ')
    return "\<End>"
endfunction "}}}

" SwitchCmdLead: switch command lead in [:#$%] "{{{1
" > a:lead, specify the command lead will be replaced to
"   when a:lead is empty or '0', cycle switch [:#$%] in turn
"   when current line has no lead, the lead is inserted and with a space
function! logcedit#SwitchCmdLead(lead) "{{{
    let l:line = line('.')
    let l:col = col('.')
    let l:linestr = getline('.')
    let l:curlead = logview#GetCmdLead()

    let l:shift = 0
    if empty(a:lead) || a:lead ==# '0'
        let l:lCommander = logview#ExportScriptVar('lCommander')
        if empty(l:curlead)
            let l:linestr = l:lCommander[0] . ' ' . l:linestr
            let l:shift = 2
        else
            let l:index = stridx(l:lCommander, l:curlead)
            if l:index == -1
                return v:false
            endif
            if l:index >= len(l:lCommander) - 1
                let l:index = 0
            else
                let l:index += 1
            endif
            let l:newlead = l:lCommander[l:index]
            let l:linestr = l:newlead . l:linestr[1:]
        endif

    else
        if !logview#IsValidLead(a:lead[0])
            return v:false
        endif

        if empty(l:curlead)
            let l:linestr = a:lead[0] . ' ' . l:linestr
            let l:shift = 2
        else
            let l:linestr = a:lead[0] . l:linestr[1:]
        endif
    endif

    call setline('.', l:linestr)
    if l:shift > 0
        execute 'normal! ' . (0+l:shift) . 'l'
    endif

    return ''
endfunction "}}}

" NextPipe: move to the next pipe in command line and wrap in eol "{{{1
" suggest nnoremap <bar>, can prefix count in normal '|' command
function! logcedit#NextPipe() range "{{{
    let l:count = a:lastline - a:firstline + 1
    let l:oldbar = 'normal! ' . (0+l:count) . '|'

    if logview#Executable() == v:false || getline('.') !~# '|'
        execute l:oldbar
        return v:false
    endif

    if l:count <= 1
        let l:ret = search('|', '', line('.'))
        if l:ret == 0
            normal! ^
            let l:ret = search('|', '', line('.'))
        endif
    else
        execute 'normal! ^' . (0+l:count) . 'f|'
    endif
endfunction "}}}

" SelectPipe: select a piped command line part "{{{1
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

" InputPipe: imap <bar> "{{{1
function! logcedit#InputPipe() "{{{
    let l:linenr = line('.')
    let l:colnr = col('.')
    let l:linestr = getline('.')

    if !logview#Executable()
        return '|'
    endif

    if logview#IsValidLead(l:linestr)
        " only lead before, backward search a command line
        let b:last_search_line = line('.')
        let b:last_search_text = l:linestr
        let l:foundcmd = s:SearchCommandLine(l:linestr[0], -1)
        if l:foundcmd == 0
            return ''
        else
            let l:foundstr = getline(l:foundcmd)
            if l:linestr !=# l:foundstr
                call setline('.', l:foundstr)
            endif

            let l:linestr = getline('.')
            if l:linestr[-1] !=# '|'
                return "\<End>|"
            else
                return "\<End>"
            endif
        endif

    elseif l:colnr >= col('$') && l:linestr[col('$')-1-1] == '|'
        " input repeated | in the end, remove the last pipe part
        normal hxd|
        return "\<End>"

    else
        return '|'
    endif
endfunction "}}}

" OnInsertEnter: reset command line search cycle "{{{1
function! logcedit#OnInsertEnter() "{{{
    let b:last_search_line = 0
    let b:last_search_text = ''
endfunction "}}}

" IRetriveCommand: <C-P> <C-N> "{{{1
" search a command line in file from current line
function! logcedit#IRetriveCommand(direction) "{{{
    " default search forward
    let l:direction = 1
    if a:direction == -1
        let l:direction = -1
    endif

    " not triggered from command line
    if !logview#Executable()
        let b:last_search_line = 0
        return a:direction == 1 ? "\<Down>" : "\<Up>"
    endif

    " set b:last_search_line and b:last_search_text
    if b:last_search_line == 0
        let b:last_search_line = line('.')
    endif

    " the current line in only contain lead, but no command string
    let l:curlinestr = getline('.')
    if empty(b:last_search_text) || logview#IsValidLead(l:curlinestr)
        let b:last_search_text = l:curlinestr
    endif

    " search a matched command line and save line number
    let l:lead = logview#GetCmdLead()
    let l:foundcmd = s:SearchCommandLine(l:lead, a:direction)
    if l:foundcmd == 0
        return ''
    else
        let b:last_search_line = l:foundcmd
    endif

    " insert the result line to current line
    let l:foundstr = getline(l:foundcmd)
    if l:curlinestr !=# l:foundstr
        call setline('.', l:foundstr)
    endif

    return "\<End>"
endfunction "}}}

" SearchCommandLine: repeated search a command line "{{{1
" > a:marker, the command lead marker
" > a:direction, forward(1) or backward(-1)
" buffer variables matters:
" > b:last_search_line, last searched line number
" > b:last_search_text, the front part of line must match this string
function! s:SearchCommandLine(marker, direction) "{{{
    if logview#IsValidLead(a:marker) == v:false
        return 0
    endif

    let l:pattern = '^' . a:marker

    let l:end = line('$')
    let l:index = b:last_search_line

    let l:ret = 0
    while v:true
        let l:index += a:direction
        if l:index < 1 || l:index > l:end
            break
        endif

        let l:linestr = getline(l:index)
        if l:linestr !~# l:pattern || len(l:linestr) < len(b:last_search_text)
            continue
        endif

        let l:front = strpart(l:linestr, 0, len(b:last_search_text))
        if l:front !=# b:last_search_text
            continue
        endif

        " finish search once time
        let l:ret = l:index
        break
    endwhile

    return l:ret
endfunction "}}}

