" ===========================================================================
" FILE: ri.vim
" AUTHOR: Yuku Takahashi <taka84u9 at gmail.com>
" VERSION: 0.1.0
" Last Modified: 29 Apr 2012
" License: MIT license {{{
"   Permission is hereby granted, free of charge, to any person obtaining
"   a copy of this software and associated documentation files (the
"   "Software"), to deal in the Software without restriction, including
"   without limitation the rights to use, copy, modify, merge, publish,
"   distribute, sublicense, and/or sell copies of the Software, and to
"   permit persons to whom the Software is furnished to do so, subject to
"   the following conditions:
" 
"   The above copyright notice and this permission notice shall be included
"   in  all copies or substantial portions of the Software.
" 
"   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"   OR  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"   IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"   CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"   SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
" ===========================================================================
if !exists('g:ref_ri_cmd')
  let g:ref_ri_cmd = executable('ri') ? 'ri' : ''
endif
let s:cmd = g:ref_ri_cmd

if !exists('g:ref_ri_use_cache')
  let g:ref_ri_use_cache = 0
endif

" source definition {{{1

let s:source = {'name': 'ri'}

function! s:source.available() " {{{2
  return !empty(g:ref_ri_cmd)
endfunction

function! s:source.get_body(query) " {{{2
  let res = s:ri(a:query)
  if res.stderr != ''
    throw res.stderr
  endif
  return res.stdout
endfunction

function! s:source.opened(query) " {{{2
  call s:syntax()
  setlocal concealcursor=nc
  setlocal conceallevel=2
endfunction

function! s:source.get_keyword() " {{{2
  let id = '\v\w+[!?]?'
  let pos = getpos('.')[1:]

  if &l:filetype ==# 'ref-ri'
    let [type, name] = s:detect_type()
    if type ==# 'class'
      let kwd = ref#get_text_on_cursor('\S\+[!?]\{0,1}')
      if kwd != ''
        return name . '.' . kwd
      end
    endif
  endif
  return ref#get_text_on_cursor('\v((\w+\:\:)*(\w+[.#]))?\w+[!?]{0,1}')
endfunction

function! s:source.complete(query) " {{{2
  let classes = g:ref_ri_use_cache ?
    \ self.cache('classes', function(self.classes_list)) :
    \ self.classes_list('classes')
  try
    let [class, sep, method] =
      \ matchlist(a:query,
      \           '\([[:upper:]][[:alnum:]_]*\%(::[[:upper:]][[:alnum:]_]*\)*\)\(#\|\.\)\(.*\)')[1:3]
  catch /E688/
    let matched = filter(copy(classes), 'v:val =~# "^\\V" . a:query')
    if empty(matched)
      let matched = filter(copy(classes), 'v:val =~# "\\V" . a:query')
    endif
    return matched
  catch
    return []
  endtry
  if !empty(filter(copy(classes), 'v:val =~#  "^\\V" . class'))
    let methods = g:ref_ri_use_cache ?
      \ copy(self.cache(class, function(self.methods_list))) :
      \ self.methods_list(class)
    if sep == '#' " instance method
      call filter(methods, 'v:val =~ "#"')
    else " class method
      call filter(methods, 'v:val !~ "#"')
    endif
    return filter(methods, 'v:val =~# "^\\V" . class . sep . method')
  endif
  return []
endfunction

function! s:source.classes_list(name) " {{{2
  let classes = split(s:ri('-l -T').stdout, "\n")
  return ref#uniq(classes)
endfunction

function! s:source.methods_list(class) " {{{2
  let methods = split(s:ri(a:class . '.').stdout, "\n")[2:]
  call map(methods, "substitute(v:val, '::\\([^:#]*\\)$', '.\\1', '')")
  return ref#uniq(methods)
endfunction

function! ref#ri#define() " {{{2
  return copy(s:source)
endfunction

call ref#register_detection('ruby', 'ri')

" syntax highlight {{{1
function! s:syntax() "
  command! -nargs=+ HtmlHiLink highlight def link <args>

  syntax clear

  syntax spell toplevel
  syntax case ignore
  syntax sync linebreaks=1

  " RDoc text markup
  syntax region rdocBold      start=/\\\@<!\(^\|\A\)\@=\*\(\s\|\W\)\@!\(\a\{1,}\s\|$\n\)\@!/ skip=/\\\*/ end=/$\|\*\($\|\A\|\s\|\n\)\@=/ contains=@Spell
  syntax region rdocEmphasis  start=/\\\@<!\(^\|\A\)\@=_\(\s\|\W\)\@!\(\a\{1,}\s\|$\n\)\@!/  skip=/\\_/  end=/$\|_\($\|\A\|\s\|\n\)\@=/  contains=@Spell
  "syntax region rdocMonospace start=/\\\@<!\(^\|\A\)\@=+\(\s\|\W\)\@!\(\a\{1,}\s\|$\n\)\@!/  skip=/\\+/  end=/+\($\|\A\|\s\|\n\)\@=/  contains=@Spell

  " RDoc links: {link}[URL]
  syntax region rdocLink matchgroup=rdocDelimiter start="\!\?{" end="}\ze\s*[\[\]]" contains=@Spell nextgroup=rdocURL,rdocID skipwhite oneline
  syntax region rdocID   matchgroup=rdocDelimiter start="{"     end="}"  contained
  syntax region rdocURL  matchgroup=rdocDelimiter start="\["    end="\]" contained
  " RDoc inline links:           protocol   optional  user:pass@       sub/domain                 .com, .co.uk, etc      optional port   path/querystring/hash fragment
  "                            ------------ _____________________ --------------------------- ________________________ ----------------- __
  syntax match  rdocInlineURL /https\?:\/\/\(\w\+\(:\w\+\)\?@\)\?\([A-Za-z][-_0-9A-Za-z]*\.\)\{1,}\(\w\{2,}\.\?\)\{1,}\(:[0-9]\{1,5}\)\?\S*/

  " Define RDoc markup groups
  syntax match  rdocLineContinue ".$" contained
  syntax match  rdocRule      /^\s*\*\s\{0,1}\*\s\{0,1}\*$/
  syntax match  rdocRule      /^\s*-\s\{0,1}-\s\{0,1}-$/
  syntax match  rdocRule      /^\s*_\s\{0,1}_\s\{0,1}_$/
  syntax match  rdocRule      /^\s*-\{3,}$/
  syntax match  rdocRule      /^\s*\*\{3,5}$/
  syntax match  rdocListItem  "^\s*[-*+]\s\+"
  syntax match  rdocListItem  "^\s*\d\+\.\s\+"
  syntax match  rdocLineBreak /  \+$/

  " RDoc pre-formatted markup
  " syntax region rdocCode      start=/\s*``[^`]*/          end=/[^`]*``\s*/
  syntax match  rdocCode  /^\s*\n\(\(\s\{1,}[^ ]\|\t\+[^\t]\).*\n\)\+/
  syntax match  rdocTag /<\/\?\(em\|tt\|pre\|code\)[^>]*>/ conceal
  syntax match  rdocCode  /<em[^>]*>.*<\/em>/ contains=rdocTag
  syntax match  rdocCode  /<tt[^>]*>.*<\/tt>/ contains=rdocTag
  syntax match  rdocCode  /<pre[^>]*>.*<\/pre>/ contains=rdocTag
  syntax match  rdocCode  /<code[^>]*>.*<\/code>/ contains=rdocTag

  " RDoc HTML headings
  syntax region htmlH1  start="^\s*="       end="\($\)" contains=@Spell
  syntax region htmlH2  start="^\s*=="      end="\($\)" contains=@Spell
  syntax region htmlH3  start="^\s*==="     end="\($\)" contains=@Spell
  syntax region htmlH4  start="^\s*===="    end="\($\)" contains=@Spell
  syntax region htmlH5  start="^\s*====="   end="\($\)" contains=@Spell
  syntax region htmlH6  start="^\s*======"  end="\($\)" contains=@Spell

  " Highlighting for RDoc groups
  HtmlHiLink rdocCode         String
  HtmlHiLink rdocLineContinue Comment
  HtmlHiLink rdocListItem     Identifier
  HtmlHiLink rdocRule         Identifier
  HtmlHiLink rdocLineBreak    Todo
  HtmlHiLink rdocLink         htmlLink
  HtmlHiLink rdocInlineURL    htmlLink
  HtmlHiLink rdocURL          htmlString
  HtmlHiLink rdocID           Identifier
  HtmlHiLink rdocBold         htmlBold
  HtmlHiLink rdocEmphasis     htmlItalic
  "HtmlHiLink rdocMonospace    String

  HtmlHiLink htmlH1           Title
  HtmlHiLink htmlH2           htmlH1
  HtmlHiLink htmlH3           htmlH2
  HtmlHiLink htmlH4           htmlH3
  HtmlHiLink htmlH5           htmlH4
  HtmlHiLink htmlH6           htmlH5

  HtmlHiLink rdocDelimiter    Delimiter

  delcommand HtmlHiLink
endfunction

" functions {{{1

function! s:detect_type() " {{{2
  let line = getline(1)
  if stridx(line, '<') >= 0
    let name = matchstr(line, '^= \zs[^ ]\+\ze')
    return ['class', name]
  endif
  return ['list', '']
endfunction


function! s:get_version() " {{{2
  return split(matchstr(ref#system(ref#to_list(g:ref_ri_cmd, '--version')).stdout, '^ri \zs.*\ze$'), '\.')
endfunction

function! s:ri(args) " {{{2
  if s:get_version()[0] > 1
    let format = 'rdoc'
  else
    let format = 'plain'
  endif

  return ref#system(ref#to_list(g:ref_ri_cmd, '--format='.format) + ref#to_list(a:args))
endfunction

" vim: foldmethod=marker
