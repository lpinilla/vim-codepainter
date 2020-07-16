" check whether this script is already loaded
if exists("g:loaded_painter")
  finish
endif
let g:loaded_painter = 1

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

"You can choose your own delimiter, it must have a 'd' which represents the
"color index, default: #d#
let g:delimiter = "#d#"

function! s:ValidateColorIndex(input)
  if type(a:input) == type(0)
    if (a:input < 0 || a:input > 9)
        echom "Invalid index, must be from 0 to 9"
        return ''
    endif
    return a:input
  else
    echom "input must be digit"
    return ''
  endif
endfunction

func! s:ValidateDelimiter(input)
    "check if its a string
    echom type(a:input)
    if type(a:input) == 1
        if a:input == ""
            echom "input can't be empty"
            return ""
        endif
        if matchstr(a:input, "d") == ""
            echom "You need to supply a d where the digit will be"
            return ""
        endif
    else
        echom "input must be string"
        return ""
    endif
    return a:input
endfunc

"remove marker in every line of selection
func! s:UnmarkSelection(color_index, selection, deli)
    let l:ret = substitute(a:selection, a:deli, "" , "g")
    "check if there is another marker
    if search(a:deli, "W") == 0
      "no more markers for this index, erase match rule
      call matchdelete(g:paint_indexes[a:color_index])
      let g:paint_indexes[a:color_index] = 0
    endif
    return l:ret
endfunc

func! s:MarkSelection(color_index, selection, deli)
"add marker
    let l:ret = a:deli . a:selection
    let l:ret = substitute(l:ret, '\n', '\n' . a:deli, "g")
    "add match rule
    if empty(g:paint_indexes[a:color_index])
      let paint_name = "paint" . a:color_index
      let regex = a:deli . ".*"
      let g:paint_indexes[a:color_index] = matchadd(paint_name, regex)
    endif
    return l:ret
endfunc

"Thanks @zah https://stackoverflow.com/questions/12805922/vim-vmap-send-selected-text-as-parameter-to-function for copying selected text into register

"Thanks @Xavier T. for subtitution on variable https://stackoverflow.com/questions/4864073/using-substitute-on-a-variable"

func! codepainter#paintText(color) range
  let color_index = s:ValidateColorIndex(a:color)
  if color_index != 0 && empty(color_index)
    return
  endif
  let save_x = getreg("x")
  let save_x_type = getregtype("x")
  "copy selection to register x
  let @x = ""
  silent! normal! gv"xx
  let l:selection = getreg("x")
  "build delimiter
  let l:deli = substitute(g:delimiter, "d", color_index, "")
  "check if its already painted
  if l:selection[0:len(l:deli)-1] == l:deli
    let l:selection = s:UnmarkSelection(color_index, l:selection, l:deli)
  else
    let l:selection = s:MarkSelection(color_index, l:selection, l:deli)
  endif
  "paste x register
  let @x = l:selection
  silent! normal! "xP
  "restore x reg
  call setreg("x", save_x, save_x_type)
endfunc

"TODO quitar el número hardcodeado
vnoremap <c-0x31> :<c-u>call codepainter#paintText(0)<cr>


"Commands---------------------------------

command! -nargs=0 PainterEraseAll call codepainter#EraseAll()
command! -nargs=1 PainterChangeDelimiter call codepainter#ChangeDelimiter(<f-args>)

func! codepainter#EraseAll()
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
endfunc

func! codepainter#ChangeDelimiter(nDelimiter)
    if s:ValidateDelimiter(a:nDelimiter) == ""
        return
    endif
    "change every limiter being used
    let l:deli = substitute(g:delimit, "d", "[0-9]", "")
    let l:nDeli = substitute(a:nDelimiter, "d", "[0-9]", "")
    silent! execute '%s/' . g:deli . "/" . l:nDeli . "/g"
    "update global variable
    let g:delimiter = a:nDelimiter
endfunc
