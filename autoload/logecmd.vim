" File: logecmd.vim
" Author: lymslive
" Description: support logview, focus on in-file command execute
" Create: 2016-09-03
" Modify: 2016-09-03

" load command script's data
let s:dCommander = logview#ExportScriptVar('dCommander')
let s:dPattern = logview#ExportScriptVar('dPattern')

" Run Infile Command:
" > a:1, line number or default currnet line
function! logecmd#InRunCommand(...) "{{{
    if a:0 > 0 && a:1 > 0
        let l:linenr = a:1
    else
        let l:linenr = line('.')
    endif

    let l:linestr = getline(l:linenr)
    let l:cmdstr = matchstr(l:linestr, s:dPattern.command)
    if empty(l:cmdstr)
        return v:false
    endif

    let l:lead = l:linestr[0]
    let l:ret = v:false

    " run command by lead
    if l:lead ==# s:dCommander.rshell || l:lead ==# s:dCommander.ushell
        " has '>' redirection char, open a new buffer
        let l:redircmd = matchlist(l:cmdstr, s:dPattern.redircmd)
        if len(l:redircmd) > 1
            let l:ret = s:ExectueInNewBuff(l:lead, l:redircmd)
        else
            let l:ret = s:DoShellCmd(l:linenr, l:cmdstr)
        endif

    elseif l:lead ==# s:dCommander.vim
        let l:cmd = l:cmdstr
        execute l:cmd
        let l:ret = v:true

    else
        echoerr 'unexpected command leading marker: ' . l:cLeader
        let l:ret = v:false
    endif

    " save last command
    if l:ret == v:true
        let b:dLastCmd.lead = l:lead
        let b:dLastCmd.line = l:linestr
    endif

    return l:ret
endfunction "}}}

" NormalEnter: <CR> run current line command if possible
function! logecmd#NormalEnter() "{{{
    let l:lead = matchstr(getline('.'), s:dPattern.leader)
    if empty(l:lead)
        return v:false
    else
        return logecmd#InRunCommand()
    endif
endfunction "}}}
" InsertEnter: <CR>
function! logecmd#InsertEnter() "{{{
    let l:ret = logecmd#InRunCommand()
    if l:ret == v:true
        return "\<Esc>"
    else
        return "\<CR>"
    endif
endfunction "}}}

" PrepareOutput: "{{{1
" make sure have two lines to mark output under current line
function! s:PrepareOutput(linenr) "{{{
    let l:linenr = a:linenr

    if l:linenr >= line('$')
        return s:NewOutputMarkLine()
    endif

    let l:next_linestr = getline(l:linenr + 1)
    if l:next_linestr !~# s:dPattern.start
        return s:NewOutputMarkLine()
    endif

    return s:EmptyOutput(l:linenr + 1)
endfunction "}}}

function! s:EmptyOutput(...) "{{{
    if a:0 >= 1
        let l:old_start = a:1
    else
        let l:old_start = search(s:dPattern.start, 'bWc')
    endif

    if l:old_start <= 0
        return v:false
    endif

    let l:old_stop = search(s:dPattern.stop, 'W')
    if l:old_stop == 0
        let l:output_stop = logview#ExportScriptVar('output_stop')
        call append(line('$'), l:output_stop)
        let l:old_stop = line('$')
    endif

    if l:old_stop - l:old_start > 1
        let l:range = (l:old_start+1) . ',' . (l:old_stop-1)
        execute l:range . 'delete'
    endif

    return v:true
endfunction "}}}

function! s:NewOutputMarkLine() "{{{
    let l:linenr = line('.')
    let l:frame = logview#OutputFrame()
    call append(l:linenr, l:frame)
    return v:true
endfunction "}}}

" ExectueInNewBuff: "{{{1
" a:leadmark, '#' or '$'
" a:redircmd, [cmd, redir-target]
function! s:ExectueInNewBuff(leadmark, redircmd) "{{{
    if len(a:redircmd) < 2
        return v:false
    endif

    " deal arguments
    let l:cmd = a:redircmd[1]
    let l:mod = a:redircmd[2]
    let l:tar = a:redircmd[3]

    let l:tar_list = matchlist(l:tar, s:dPattern.target)
    if empty(l:tar_list)
        let l:target = 'w'
        let l:name = ''
    else
        let l:target = l:tar_list[1]
        let l:name = l:tar_list[2]
    endif

    " goto new buffer window
    call logview#BufferNewLgFile(l:target, l:name)
    if l:mod == '>'
        1,$delete
        call append(0, a:leadmark . ' ' . l:cmd)
    else
        call append(line('$'), a:leadmark . ' ' . l:cmd)
    endif

    normal! G
    let l:linenr = line('$')

    return s:DoShellCmd(l:linenr, l:cmd)
endfunction "}}}

" DoShellCmd: "{{{1
function! s:DoShellCmd(linenr, cmdstr) "{{{
    " still have more redir '>'
    if a:cmdstr =~# '>' || empty(a:cmdstr) || a:linenr <= 0
        return v:false
    endif

    call s:PrepareOutput(a:linenr)

    let l:cmd = (1+a:linenr) . 'r !' . a:cmdstr
    echom 'shell command is running, wait a long or short time ...'
    execute l:cmd
    echom 'shell command done!'

    return v:true
endfunction "}}}
