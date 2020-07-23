" defining the colors
hi paint0 gui=reverse guifg=#A3BE8C guibg=#2E3440
hi paint1 gui=reverse guifg=#EBCB8B guibg=#2E3440
hi paint2 gui=reverse guifg=#A1B6BF guibg=#2E3440
hi paint3 gui=reverse guifg=#BFA484 guibg=#2E3440
hi paint4 gui=reverse guifg=#BF7A86 guibg=#2E3440
hi paint5 gui=reverse guifg=#BB9BF2 guibg=#2E3440
hi paint6 gui=reverse guifg=#676073 guibg=#2E3440
hi paint7 gui=reverse guifg=#2D401C guibg=#ffffff
hi paint8 gui=reverse guifg=#6868BD guibg=#2E3440
hi paint9 gui=reverse guifg=#C2B330 guibg=#2E3440

let g:paint_indexes = [0,0,0,0,0,0,0,0,0,0]
let g:paint_n = 0

"You can choose your own delimiter, it must have a 'd' which represents the
"color index, default: #d#
let g:delimiter = "#d#"

function! s:ValidateColorIndex(input) abort
  let l:n = str2nr(a:input)
  if type(l:n) == type(0)
    if (l:n < 0 || l:n > 9)
        echom "Invalid index, must be from 0 to 9"
        return ''
    endif
    return l:n
  else
    echom "Input must be digit"
    return ''
  endif
endfunction

function! s:ValidateDelimiter(input) abort
    "check if its a string
    echom type(a:input)
    if type(a:input) == 1
        if a:input == ""
            echom "Input can't be empty"
            return ""
        endif
        if matchstr(a:input, "d") == ""
            echom "You need to supply a d where the digit will be"
            return ""
        endif
    else
        echom "Input must be string"
        return ""
    endif
    return a:input
endfunction

"remove marker in every line of selection
function! s:UnmarkSelection(color_index, selection, deli) abort
    let l:ret = substitute(a:selection, a:deli, "" , "g")
    "check if there is another marker
    "save cursor position
    let save_pos = getpos('.')
    "go to beginning of buffer
    call setpos('.', [0,0,0,0])
    if search(a:deli, "W") == 0
      "no more markers for this index, erase match rule
      call matchdelete(g:paint_indexes[a:color_index])
      let g:paint_indexes[a:color_index] = 0
    endif
    "restore position
    call setpos('.', save_pos)
    return l:ret
endfunction

function! s:MarkSelection(color_index, selection, deli) abort
    "add marker
    let l:ret = a:deli . a:selection
    "hack to make it more comfortable
    if l:ret[-1:-1] == "\x0a"
        let l:ret = substitute(l:ret[:-2], '\n', '\n' . a:deli, "g") . "\n"
    else
        let l:ret = substitute(l:ret, '\n', '\n' . a:deli, "g")
    endif
    "add match rule
    if empty(g:paint_indexes[a:color_index])
      let paint_name = "paint" . a:color_index
      let regex = a:deli . ".*"
      let g:paint_indexes[a:color_index] = matchadd(paint_name, regex)
    endif
    return l:ret
endfunction

"Thanks @zah https://stackoverflow.com/questions/12805922/vim-vmap-send-selected-text-as-parameter-to-function for copying selected text into register

"Thanks @Xavier T. for subtitution on variable https://stackoverflow.com/questions/4864073/using-substitute-on-a-variable"

function! codepainter#paintText() range
  let save_x = getreg("x")
  let save_x_type = getregtype("x")
  "copy selection to register x
  let @x = ""
  silent! normal! gv"xx
  let l:selection = getreg("x")
  "build delimiter
  let l:deli = substitute(g:delimiter, "d", g:paint_n, "")
  "check if its already painted
  if l:selection[0:len(g:delimiter)-1] =~# substitute(g:delimiter, "d", "[0-9]", "")
    let l:selection = s:UnmarkSelection(g:paint_n, l:selection, l:deli)
  else
    let l:selection = s:MarkSelection(g:paint_n, l:selection, l:deli)
  endif
  "paste x register
  let @x = l:selection
  silent! normal! "xP
  "restore x reg
  call setreg("x", save_x, save_x_type)
endfunction

function! codepainter#EraseAll() abort
  "clean all delimiters
  let l:delimiter = substitute(g:delimiter, "d", "[0-9]", "")
  silent! execute '%s/' . l:delimiter . "//g"
  "erase all match rules listed
  let index = 0
  while index < 10
    if g:paint_indexes[index] != 0
      call matchdelete(g:paint_indexes[index])
      let g:paint_indexes[index] = 0
    endif
  let index = index + 1
  endwhile
endfunction

function! codepainter#ChangeDelimiter(nDelimiter) abort
  let l:nDeli = s:ValidateDelimiter(a:nDelimiter)
  if l:nDeli == ""
      return
  endif
  "change every limiter being used
  let l:deli = substitute(g:delimiter, "d", '\\([0-9]\\)', "")
  let l:nDeli = substitute(l:nDeli, "d", '\\1', "")
  silent! execute '%s/' . l:deli . "/" . l:nDeli . "/g"
  "recreate every matching rule
  let index = 0
  while index < 10
    if g:paint_indexes[index] != 0
      call matchdelete(g:paint_indexes[index])
      let paint_name = "paint" . index
      let regex = substitute(l:nDeli, '\\1', index, "") . ".*"
      let g:paint_indexes[index] = matchadd(paint_name, regex)
    endif
    let index = index + 1
  endwhile
  "update global variable
  let g:delimiter = a:nDelimiter
endfunction

function! codepainter#ChangeColor(nPaint) abort
  let l:paint = s:ValidateColorIndex(a:nPaint)
  if l:paint != 0 && empty(l:paint)
    return
  endif
  let g:paint_n = l:paint
endfunction
