" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! visualctrlg#load() "{{{
    " dummy function to load this script.
endfunction "}}}

function! s:Plural(num)
    return a:num == 1 ? '' : 's'
endfunction
function! visualctrlg#report(verbose) "{{{
    let default = 1
    let sleep_arg = v:count != 0 ? v:count : default
    let text = s:get_selected_text()

    let lines_num = getpos("'>")[1] - getpos("'<")[1] + 1
    let byte_num = strlen(text)
    let char_num = s:strchars(text)
    if a:verbose
        let displaywidth = s:FormatRange('display width', s:DetermineWidth(text, s:strdisplaywidth))
        let netwidth     = s:FormatRange('net width'    , s:DetermineWidth(text, function('s:NetWidth')))
        echo printf('%d line%s, %d byte%s, %d char%s, %s, %s',
        \           lines_num, s:Plural(lines_num), byte_num, s:Plural(byte_num), char_num, s:Plural(char_num), netwidth, displaywidth)
    else
        echo printf('%d line%s, %d byte%s, %d char%s',
        \           lines_num, s:Plural(lines_num), byte_num, s:Plural(byte_num), char_num, s:Plural(char_num))
    endif

    " Sleep to see the output in command-line.
    execute 'sleep' sleep_arg
endfunction "}}}

function! visualctrlg#report_verbosely(...) "{{{
    return call('visualctrlg#report', [1] + a:000)
endfunction "}}}

function! visualctrlg#report_briefly(...) "{{{
    return call('visualctrlg#report', [0] + a:000)
endfunction "}}}


function! s:get_selected_text() "{{{
    let save_z      = getreg('z', 1)
    let save_z_type = getregtype('z')
    try
        silent normal! gv"zy
        return @z
    finally
        call setreg('z', save_z, save_z_type)
    endtry
endfunction "}}}

function! s:DetermineWidth(text, Func)
    let widths = map(split(a:text, "\n", 1), 'call(a:Func, [v:val])')
    if empty(widths[-1])
        " Ignore the trailing newline when processing entire lines.
        call remove(widths, -1)
    endif
    return [min(widths), max(widths)]
endfunction
function! s:NetWidth(text)
    return s:strdisplaywidth(substitute(a:text, '^\s*\(.\{-}\)\s*$', '\1', ''))
endfunction
function! s:FormatRange(rangestring, range)
    let [min, max] = a:range
    return (min == max || min == 0 ? max . ' ' . a:rangestring : a:rangestring . ' between ' . min . ' and ' . max)
endfunction

" strchars() {{{
if exists('*strchars')
    let s:strchars = function('strchars')
else
    function! s:strchars(expr)
        return strlen(substitute(a:expr, '.', 'x', 'g'))
    endfunction
endif
" }}}
" strdisplaywidth() {{{
if exists('*strdisplaywidth')
    let s:strdisplaywidth = function('strdisplaywidth')
else
    " From s:strdisplaywidth() of autofmt.vim. ynkdir++
    function! s:emulate_strdisplaywidth(str, ...)
        let vcol = get(a:000, 0, 0)
        let w = 0
        for c in split(a:str, '\zs')
            if c == "\t"
                let w += &tabstop - ((vcol + w) % &tabstop)
            elseif c =~ '^.\%2v'  " single-width char
                let w += 1
            elseif c =~ '^.\%3v'  " double-width char or ctrl-code (^X)
                let w += 2
            elseif c =~ '^.\%5v'  " <XX>    (^X with :set display=uhex)
                let w += 4
            elseif c =~ '^.\%7v'  " <XXXX>  (e.g. U+FEFF)
                let w += 6
            endif
        endfor
        return w
    endfunction
    let s:strdisplaywidth = function('s:emulate_strdisplaywidth')
endif
" }}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
