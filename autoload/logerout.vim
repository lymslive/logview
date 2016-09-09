" File: dmlog.vim
" Author: lymslive
" Description: support logview, focus on output range analyse
" Create: 2016-09-03
" Modify: 2016-09-03

let s:grep = 'grep'

" PipeGrep: pipe further grep in currnet output "{{{1
" put a new command line with added pipe, remain unexecuted
" > a:1 word, the grep pattern
" > a:2 repipe, replace which pipe, by rdinex, 0 add last, 1 replace last
" > a:3 pos, [0]replace this cmdline, [-1] put before, [1] put after
function! logerout#PipeGrep(...) "{{{
    if logview#InOutput() == v:false
        return
    endif

    if a:0 < 1 || empty(a:1) || a:1 == '0'
        let l:word = expand('<cword>')
    else
        let l:word = a:1
    endif

    if a:0 < 2 || empty(a:2)
        let l:repipe = 0
    else
        let l:repipe = a:2
    endif

    if a:0 < 3 || empty(a:3)
        let l:pos = 1
    else
        let l:pos = a:3
    endif

    let l:linenr = line('.')
    let l:cmdline = s:GetThisCmdlineNo(l:linenr)
    echom l:cmdline
    if l:cmdline <= 0
        return
    endif

    " construct new command line string
    let l:cmdstr = getline(l:cmdline)
    let l:cmdnew = ''
    let l:pipnew = ' ' . s:grep . ' ' . l:word

    let l:pipes = split(l:cmdstr, '|')
    let l:pipelen = len(l:pipes)
    if l:repipe > 0 && l:repipe < l:pipelen
        let l:pipes[-l:repipe] = l:pipnew
        let l:cmdnew = join(l:pipes, '|')
    else
        let l:cmdnew = l:cmdstr . ' |' . l:pipnew
    endif

    " put new command line in postion
    let l:newpos = l:cmdline
    if l:pos == 0
        call setline(l:newpos, l:cmdnew)
        call cursor(l:newpos, 1)
        normal! $

    elseif l:pos == -1
        call append(l:newpos-1, l:cmdnew)
        call cursor(l:newpos, 1)
        normal! $

    elseif l:pos == 1
        let l:newpos = s:GetThisEndlineNo(l:linenr)
        call append(l:newpos, l:cmdnew)
        call cursor(l:newpos+1, 1)
        normal! $

    else
        echoerr 'unexpected a:pos'
    endif
endfunction "}}}

" GetThisCmdlineNo: 
function! s:GetThisCmdlineNo(linenr) "{{{
    for l:line in range(a:linenr, 1, -1)
        if logview#Executable(l:line)
            return l:line
        endif
    endfor
    return 0
endfunction "}}}

" GetThisEndlineNo: 
function! s:GetThisEndlineNo(linenr) "{{{
    for l:line in range(a:linenr, line('$'))
        if logview#GetLineType(l:line) == '.'
            return l:line
        endif
    endfor
    return 0
endfunction "}}}

" CatFile: load a file in *.lg format "{{{1
function! logerout#CatFile(...) "{{{
    if a:0 < 1 || empty(a:1) || a:1 == '0'
        let l:file = expand('<cfile>')
    else
        let l:file = a:1
    endif

    let l:cmdstr = '# cat ' . l:file

    tabedit -FILE.lg
    set buftype=nowrite

    call append(0, l:cmdstr)
    call cursor(1, len(l:cmdstr)-1)
endfunction "}}}
