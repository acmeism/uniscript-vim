" Language:    UniScript
" Maintainer:  Mick Koch <kchmck@gmail.com>
" URL:         http://github.com/kchmck/vim-uniscript-script
" License:     WTFPL

" Bail if our syntax is already loaded.
if exists('b:current_syntax') && b:current_syntax == 'uniscript'
  finish
endif

" Include JavaScript for uniscriptEmbed.
syn include @uniscriptJS syntax/javascript.vim

" Highlight long strings.
syn sync minlines=100

" UniScript identifiers can have dollar signs.
setlocal isident+=$

" These are `matches` instead of `keywords` because vim's highlighting
" priority for keywords is higher than matches. This causes keywords to be
" highlighted inside matches, even if a match says it shouldn't contain them --
" like with uniscriptAssign and uniscriptDot.
syn match uniscriptStatement /\<\%(return\|break\|continue\|throw\)\>/ display
hi def link uniscriptStatement Statement

syn match uniscriptRepeat /\<\%(for\|while\|until\|loop\)\>/ display
hi def link uniscriptRepeat Repeat

syn match uniscriptConditional /\<\%(if\|else\|unless\|switch\|when\|then\)\>/
\                           display
hi def link uniscriptConditional Conditional

syn match uniscriptException /\<\%(try\|catch\|finally\)\>/ display
hi def link uniscriptException Exception

syn match uniscriptKeyword /\<\%(new\|in\|of\|by\|and\|or\|not\|is\|isnt\|class\|extends\|super\|do\)\>/
\                       display
" The `own` keyword is only a keyword after `for`.
syn match uniscriptKeyword /\<for\s\+own\>/ contained containedin=uniscriptRepeat
\                       display
hi def link uniscriptKeyword Keyword

syn match uniscriptOperator /\<\%(instanceof\|typeof\|delete\)\>/ display
hi def link uniscriptOperator Operator

" The first case matches symbol operators only if they have an operand before.
syn match uniscriptExtendedOp /\%(\S\s*\)\@<=[+\-*/%&|\^=!<>?.]\{-1,}\|[-=]>\|--\|++\|:/
\                          display
syn match uniscriptExtendedOp /\<\%(and\|or\)=/ display
hi def link uniscriptExtendedOp uniscriptOperator

" This is separate from `uniscriptExtendedOp` to help differentiate commas from
" dots.
syn match uniscriptSpecialOp /[,;]/ display
hi def link uniscriptSpecialOp SpecialChar

syn match uniscriptBoolean /\<\%(true\|on\|yes\|false\|off\|no\)\>/ display
hi def link uniscriptBoolean Boolean

syn match uniscriptGlobal /\<\%(null\|undefined\)\>/ display
hi def link uniscriptGlobal Type

" A special variable
syn match uniscriptSpecialVar /\<\%(this\|prototype\|arguments\)\>/ display
hi def link uniscriptSpecialVar Special

" An @-variable
syn match uniscriptSpecialIdent /@\%(\I\i*\)\?/ display
hi def link uniscriptSpecialIdent Identifier

" A class-like name that starts with a capital letter
syn match uniscriptObject /\<\u\w*\>/ display
hi def link uniscriptObject Structure

" A constant-like name in SCREAMING_CAPS
syn match uniscriptConstant /\<\u[A-Z0-9_]\+\>/ display
hi def link uniscriptConstant Constant

" A variable name
syn cluster uniscriptIdentifier contains=uniscriptSpecialVar,uniscriptSpecialIdent,
\                                     uniscriptObject,uniscriptConstant

" A non-interpolated string
syn cluster uniscriptBasicString contains=@Spell,uniscriptEscape
" An interpolated string
syn cluster uniscriptInterpString contains=@uniscriptBasicString,uniscriptInterp

" Regular strings
syn region uniscriptString start=/"/ skip=/\\\\\|\\"/ end=/"/
\                       contains=@uniscriptInterpString
syn region uniscriptString start=/'/ skip=/\\\\\|\\'/ end=/'/
\                       contains=@uniscriptBasicString
hi def link uniscriptString String

" A integer, including a leading plus or minus
syn match uniscriptNumber /\i\@<![-+]\?\d\+\%([eE][+-]\?\d\+\)\?/ display
" A hex, binary, or octal number
syn match uniscriptNumber /\<0[xX]\x\+\>/ display
syn match uniscriptNumber /\<0[bB][01]\+\>/ display
syn match uniscriptNumber /\<0[oO][0-7]\+\>/ display
hi def link uniscriptNumber Number

" A floating-point number, including a leading plus or minus
syn match uniscriptFloat /\i\@<![-+]\?\d*\.\@<!\.\d\+\%([eE][+-]\?\d\+\)\?/
\                     display
hi def link uniscriptFloat Float

" An error for reserved keywords
if !exists("uniscript_no_reserved_words_error")
  syn match uniscriptReservedError /\<\%(case\|default\|function\|var\|void\|with\|const\|let\|enum\|export\|import\|native\|__hasProp\|__extends\|__slice\|__bind\|__indexOf\|implements\|interface\|let\|package\|private\|protected\|public\|static\|yield\)\>/
  \                             display
  hi def link uniscriptReservedError Error
endif

" A normal object assignment
syn match uniscriptObjAssign /@\?\I\i*\s*\ze::\@!/ contains=@uniscriptIdentifier display
hi def link uniscriptObjAssign Identifier

syn keyword uniscriptTodo TODO FIXME XXX contained
hi def link uniscriptTodo Todo

syn match uniscriptComment /#.*/ contains=@Spell,uniscriptTodo
hi def link uniscriptComment Comment

syn region uniscriptBlockComment start=/####\@!/ end=/###/
\                             contains=@Spell,uniscriptTodo
hi def link uniscriptBlockComment uniscriptComment

" A comment in a heregex
syn region uniscriptHeregexComment start=/#/ end=/\ze\/\/\/\|$/ contained
\                               contains=@Spell,uniscriptTodo
hi def link uniscriptHeregexComment uniscriptComment

" Embedded JavaScript
syn region uniscriptEmbed matchgroup=uniscriptEmbedDelim
\                      start=/`/ skip=/\\\\\|\\`/ end=/`/
\                      contains=@uniscriptJS
hi def link uniscriptEmbedDelim Delimiter

syn region uniscriptInterp matchgroup=uniscriptInterpDelim start=/#{/ end=/}/ contained
\                       contains=@uniscriptAll
hi def link uniscriptInterpDelim PreProc

" A string escape sequence
syn match uniscriptEscape /\\\d\d\d\|\\x\x\{2\}\|\\u\x\{4\}\|\\./ contained display
hi def link uniscriptEscape SpecialChar

" A regex -- must not follow a parenthesis, number, or identifier, and must not
" be followed by a number
syn region uniscriptRegex start=/\%(\%()\|\i\@<!\d\)\s*\|\i\)\@<!\/=\@!\s\@!/
\                      skip=/\[[^\]]\{-}\/[^\]]\{-}\]/
\                      end=/\/[gimy]\{,4}\d\@!/
\                      oneline contains=@uniscriptBasicString
hi def link uniscriptRegex String

" A heregex
syn region uniscriptHeregex start=/\/\/\// end=/\/\/\/[gimy]\{,4}/
\                        contains=@uniscriptInterpString,uniscriptHeregexComment
\                        fold
hi def link uniscriptHeregex uniscriptRegex

" Heredoc strings
syn region uniscriptHeredoc start=/"""/ end=/"""/ contains=@uniscriptInterpString
\                        fold
syn region uniscriptHeredoc start=/'''/ end=/'''/ contains=@uniscriptBasicString
\                        fold
hi def link uniscriptHeredoc String

" An error for trailing whitespace, as long as the line isn't just whitespace
if !exists("uniscript_no_trailing_space_error")
  syn match uniscriptSpaceError /\S\@<=\s\+$/ display
  hi def link uniscriptSpaceError Error
endif

" An error for trailing semicolons, for help transitioning from JavaScript
if !exists("uniscript_no_trailing_semicolon_error")
  syn match uniscriptSemicolonError /;$/ display
  hi def link uniscriptSemicolonError Error
endif

" Ignore reserved words in dot accesses.
syn match uniscriptDotAccess /\.\@<!\.\s*\I\i*/he=s+1 contains=@uniscriptIdentifier
hi def link uniscriptDotAccess uniscriptExtendedOp

" Ignore reserved words in prototype accesses.
syn match uniscriptProtoAccess /::\s*\I\i*/he=s+2 contains=@uniscriptIdentifier
hi def link uniscriptProtoAccess uniscriptExtendedOp

" This is required for interpolations to work.
syn region uniscriptCurlies matchgroup=uniscriptCurly start=/{/ end=/}/
\                        contains=@uniscriptAll
syn region uniscriptBrackets matchgroup=uniscriptBracket start=/\[/ end=/\]/
\                         contains=@uniscriptAll
syn region uniscriptParens matchgroup=uniscriptParen start=/(/ end=/)/
\                       contains=@uniscriptAll

" These are highlighted the same as commas since they tend to go together.
hi def link uniscriptBlock uniscriptSpecialOp
hi def link uniscriptBracket uniscriptBlock
hi def link uniscriptCurly uniscriptBlock
hi def link uniscriptParen uniscriptBlock

" This is used instead of TOP to keep things uniscript-specific for good
" embedding. `contained` groups aren't included.
syn cluster uniscriptAll contains=uniscriptStatement,uniscriptRepeat,uniscriptConditional,
\                              uniscriptException,uniscriptKeyword,uniscriptOperator,
\                              uniscriptExtendedOp,uniscriptSpecialOp,uniscriptBoolean,
\                              uniscriptGlobal,uniscriptSpecialVar,uniscriptSpecialIdent,
\                              uniscriptObject,uniscriptConstant,uniscriptString,
\                              uniscriptNumber,uniscriptFloat,uniscriptReservedError,
\                              uniscriptObjAssign,uniscriptComment,uniscriptBlockComment,
\                              uniscriptEmbed,uniscriptRegex,uniscriptHeregex,
\                              uniscriptHeredoc,uniscriptSpaceError,
\                              uniscriptSemicolonError,uniscriptDotAccess,
\                              uniscriptProtoAccess,uniscriptCurlies,uniscriptBrackets,
\                              uniscriptParens

if !exists('b:current_syntax')
  let b:current_syntax = 'uniscript'
endif
