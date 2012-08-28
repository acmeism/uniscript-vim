" Language:    UniScriptScript
" Maintainer:  Mick Koch <kchmck@gmail.com>
" URL:         http://github.com/kchmck/vim-uniscript-script
" License:     WTFPL

autocmd BufNewFile,BufRead *.uni set filetype=uniscript
" autocmd BufNewFile,BufRead *.cd.uni set filetype=uniscript
" autocmd BufNewFile,BufRead *.cdent.uni set filetype=uniscript
" autocmd BufNewFile,BufRead *.cd1 set filetype=uniscript

function! s:DetectUniScript()
    if getline(1) =~ '^#!?.*\<uniscript\>'
        set filetype=uniscript
    endif
endfunction

autocmd BufNewFile,BufRead * call s:DetectUniScript()
