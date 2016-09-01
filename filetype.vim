" detect filetype for dmlog
augroup filetypedetect
    au BufNewFile,BufRead *.lg     setfiletype dmlog
    au BufNewFile,BufRead *.log    setfiletype dmlog
    au BufNewFile,BufRead *.error  setfiletype dmlog
augroup END
