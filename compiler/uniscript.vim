" Language:    UniScriptScript
" Maintainer:  Mick Koch <kchmck@gmail.com>
" URL:         http://github.com/kchmck/vim-uniscript-script
" License:     WTFPL

if exists('current_compiler')
  finish
endif

let current_compiler = 'uniscript'
" Pattern to check if uniscript is the compiler
let s:pat = '^' . current_compiler

" Path to UniScriptScript compiler
if !exists('uniscript_compiler')
  let uniscript_compiler = 'uniscript'
endif

if exists('uniscript_make_compiler')
  echohl WarningMsg
    echom '`uniscript_make_compiler` is deprecated: use `uniscript_compiler` instead'
  echohl None

  let uniscript_compiler = uniscript_make_compiler
endif

" Extra options passed to UniScriptMake
if !exists('uniscript_make_options')
  let uniscript_make_options = ''
endif

" Get a `makeprg` for the current filename. This is needed to support filenames
" with spaces and quotes, but also not break generic `make`.
function! s:GetMakePrg()
  return g:uniscript_compiler . ' -c ' . g:uniscript_make_options . ' $* '
  \                        . fnameescape(expand('%'))
endfunction

" Set `makeprg` and return 1 if uniscript is still the compiler, else return 0.
function! s:SetMakePrg()
  if &l:makeprg =~ s:pat
    let &l:makeprg = s:GetMakePrg()
  elseif &g:makeprg =~ s:pat
    let &g:makeprg = s:GetMakePrg()
  else
    return 0
  endif

  return 1
endfunction

" Set a dummy compiler so we can check whether to set locally or globally.
CompilerSet makeprg=uniscript
call s:SetMakePrg()

CompilerSet errorformat=Error:\ In\ %f\\,\ %m\ on\ line\ %l,
                       \Error:\ In\ %f\\,\ Parse\ error\ on\ line\ %l:\ %m,
                       \SyntaxError:\ In\ %f\\,\ %m,
                       \%-G%.%#

" Compile the current file.
command! -bang -bar -nargs=* UniScriptMake make<bang> <args>

" Set `makeprg` on rename since we embed the filename in the setting.
augroup UniScriptUpdateMakePrg
  autocmd!

  " Update `makeprg` if uniscript is still the compiler, else stop running this
  " function.
  function! s:UpdateMakePrg()
    if !s:SetMakePrg()
      autocmd! UniScriptUpdateMakePrg
    endif
  endfunction

  " Set autocmd locally if compiler was set locally.
  if &l:makeprg =~ s:pat
    autocmd BufFilePost,BufWritePost <buffer> call s:UpdateMakePrg()
  else
    autocmd BufFilePost,BufWritePost          call s:UpdateMakePrg()
  endif
augroup END
