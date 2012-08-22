" Language:    UniScriptScript
" Maintainer:  Mick Koch <kchmck@gmail.com>
" URL:         http://github.com/kchmck/vim-uniscript-script
" License:     WTFPL

if exists("b:did_ftplugin")
  finish
endif

let b:did_ftplugin = 1

setlocal formatoptions-=t formatoptions+=croql
setlocal comments=:#
setlocal commentstring=#\ %s
setlocal omnifunc=javascriptcomplete#CompleteJS

" Enable UniScriptMake if it won't overwrite any settings.
if !len(&l:makeprg)
  compiler uniscript
endif

" Check here too in case the compiler above isn't loaded.
if !exists('uniscript_compiler')
  let uniscript_compiler = 'uniscript'
endif

" Path to uniscriptlint executable
if !exists('uniscript_linter')
  let uniscript_linter = 'uniscriptlint'
endif

" Options passed to UniScriptLint
if !exists('uniscript_lint_options')
  let uniscript_lint_options = ''
endif

" Reset the UniScriptCompile variables for the current buffer.
function! s:UniScriptCompileResetVars()
  " Compiled output buffer
  let b:uniscript_compile_buf = -1
  let b:uniscript_compile_pos = []

  " If UniScriptCompile is watching a buffer
  let b:uniscript_compile_watch = 0
endfunction

" Clean things up in the source buffer.
function! s:UniScriptCompileClose()
  exec bufwinnr(b:uniscript_compile_src_buf) 'wincmd w'
  silent! autocmd! UniScriptCompileAuWatch * <buffer>
  call s:UniScriptCompileResetVars()
endfunction

" Update the UniScriptCompile buffer given some input lines.
function! s:UniScriptCompileUpdate(startline, endline)
  let input = join(getline(a:startline, a:endline), "\n")

  " Move to the UniScriptCompile buffer.
  exec bufwinnr(b:uniscript_compile_buf) 'wincmd w'

  " UniScript doesn't like empty input.
  if !len(input)
    return
  endif

  " Compile input.
  let output = system(g:uniscript_compiler . ' -scb 2>&1', input)

  " Be sure we're in the UniScriptCompile buffer before overwriting.
  if exists('b:uniscript_compile_buf')
    echoerr 'UniScriptCompile buffers are messed up'
    return
  endif

  " Replace buffer contents with new output and delete the last empty line.
  setlocal modifiable
    exec '% delete _'
    put! =output
    exec '$ delete _'
  setlocal nomodifiable

  " Highlight as JavaScript if there is no compile error.
  if v:shell_error
    setlocal filetype=
  else
    setlocal filetype=javascript
  endif

  call setpos('.', b:uniscript_compile_pos)
endfunction

" Update the UniScriptCompile buffer with the whole source buffer.
function! s:UniScriptCompileWatchUpdate()
  call s:UniScriptCompileUpdate(1, '$')
  exec bufwinnr(b:uniscript_compile_src_buf) 'wincmd w'
endfunction

" Peek at compiled UniScriptScript in a scratch buffer. We handle ranges like this
" to prevent the cursor from being moved (and its position saved) before the
" function is called.
function! s:UniScriptCompile(startline, endline, args)
  if !executable(g:uniscript_compiler)
    echoerr "Can't find UniScriptScript compiler `" . g:uniscript_compiler . "`"
    return
  endif

  " If in the UniScriptCompile buffer, switch back to the source buffer and
  " continue.
  if !exists('b:uniscript_compile_buf')
    exec bufwinnr(b:uniscript_compile_src_buf) 'wincmd w'
  endif

  " Parse arguments.
  let watch = a:args =~ '\<watch\>'
  let unwatch = a:args =~ '\<unwatch\>'
  let size = str2nr(matchstr(a:args, '\<\d\+\>'))

  " Determine default split direction.
  if exists('g:uniscript_compile_vert')
    let vert = 1
  else
    let vert = a:args =~ '\<vert\%[ical]\>'
  endif

  " Remove any watch listeners.
  silent! autocmd! UniScriptCompileAuWatch * <buffer>

  " If just unwatching, don't compile.
  if unwatch
    let b:uniscript_compile_watch = 0
    return
  endif

  if watch
    let b:uniscript_compile_watch = 1
  endif

  " Build the UniScriptCompile buffer if it doesn't exist.
  if bufwinnr(b:uniscript_compile_buf) == -1
    let src_buf = bufnr('%')
    let src_win = bufwinnr(src_buf)

    " Create the new window and resize it.
    if vert
      let width = size ? size : winwidth(src_win) / 2

      belowright vertical new
      exec 'vertical resize' width
    else
      " Try to guess the compiled output's height.
      let height = size ? size : min([winheight(src_win) / 2,
      \                               a:endline - a:startline + 2])

      belowright new
      exec 'resize' height
    endif

    " We're now in the scratch buffer, so set it up.
    setlocal bufhidden=wipe buftype=nofile
    setlocal nobuflisted nomodifiable noswapfile nowrap

    autocmd BufWipeout <buffer> call s:UniScriptCompileClose()
    " Save the cursor when leaving the UniScriptCompile buffer.
    autocmd BufLeave <buffer> let b:uniscript_compile_pos = getpos('.')

    nnoremap <buffer> <silent> q :hide<CR>

    let b:uniscript_compile_src_buf = src_buf
    let buf = bufnr('%')

    " Go back to the source buffer and set it up.
    exec bufwinnr(b:uniscript_compile_src_buf) 'wincmd w'
    let b:uniscript_compile_buf = buf
  endif

  if b:uniscript_compile_watch
    call s:UniScriptCompileWatchUpdate()

    augroup UniScriptCompileAuWatch
      autocmd InsertLeave <buffer> call s:UniScriptCompileWatchUpdate()
    augroup END
  else
    call s:UniScriptCompileUpdate(a:startline, a:endline)
  endif
endfunction

" Complete arguments for the UniScriptCompile command.
function! s:UniScriptCompileComplete(arg, cmdline, cursor)
  let args = ['unwatch', 'vertical', 'watch']

  if !len(a:arg)
    return args
  endif

  let match = '^' . a:arg

  for arg in args
    if arg =~ match
      return [arg]
    endif
  endfor
endfunction

" Run uniscriptlint on a file, and add any errors between @startline and @endline
" to the quickfix list.
function! s:UniScriptLint(startline, endline, bang, args)
  if !executable(g:uniscript_linter)
    echoerr "Can't find UniScriptScript linter `" . g:uniscript_linter . "`"
    return
  endif

  let filename = expand('%')

  if !len(filename)
    echoerr 'UniScriptLint must be ran on a saved file'
    return
  endif

  let lines = split(system(g:uniscript_linter . ' --csv ' . g:uniscript_lint_options .
  \                        ' ' . a:args . ' ' . filename . ' 2>&1'), '\n')
  let qflist = []

  for line in lines
    let match = matchlist(line, '\f\+,\(\d\+\),error,\(.\+\)')

    " Ignore invalid lines.
    if !len(match)
      continue
    endif

    let lnum = str2nr(match[1])

    " Don't add the error if it's not in the range.
    if lnum < a:startline || lnum > a:endline
      continue
    endif

    let text = match[2]

    call add(qflist, {'bufnr': bufnr('%'), 'lnum': lnum, 'text': text})
  endfor

  call setqflist(qflist, 'r')

  " Don't jump if there's a bang.
  if !len(a:bang)
    silent! cc 1
  endif
endfunction

" Don't overwrite the UniScriptCompile variables.
if !exists('b:uniscript_compile_buf')
  call s:UniScriptCompileResetVars()
endif

" Peek at compiled UniScriptScript.
command! -range=% -bar -nargs=* -complete=customlist,s:UniScriptCompileComplete
\        UniScriptCompile call s:UniScriptCompile(<line1>, <line2>, <q-args>)
" Run some UniScriptScript.
command! -range=% -bar UniScriptRun <line1>,<line2>:w !uniscript -s
" Run uniscriptlint on the file.
command! -range=% -bang -bar -nargs=* UniScriptLint
\        call s:UniScriptLint(<line1>, <line2>, '<bang>', <q-args>)
