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

"The delimiter will have the form 'delimiter'[0-9]'delimiter'. Default will be #0# for paint0.
let g:delimiter = "#"

function! codepainter#ValidateColorIndex(input)
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


"Thanks @zah https://stackoverflow.com/questions/12805922/vim-vmap-send-selected-text-as-parameter-to-function for copying selected text into register

"Thanks @Xavier T. for subtitution on variable https://stackoverflow.com/questions/4864073/using-substitute-on-a-variable"

func! codepainter#paintText(color)
  let color_index = codepainter#ValidateColorIndex(a:color)
  if color_index != 0 && empty(color_index)
    return
  endif
  let save_x = getreg("x")
  let save_x_type = getregtype("x")
  "copy selection to register x
  "normal gv"xy
  normal "xy
  let l:selection = getreg("x")
  "build delimiter
  let l:deli = g:delimiter . color_index . g:delimiter
  "check if its already painted
  if l:selection[0:3] == l:deli
    "remove marker in every line of selection
    let l:selection = substitute(l:selection, l:deli, "" , "")
    "check if there is another marker
    if normal /l:deli == ""
      "no more markers for this index, erase match rule
      call matchdelete(color_index)
    endif
  else
    "paint
    "add marker
    let l:selection = l:deli . l:selection
    let l:selection = substitute(l:selection, '\\n', '\\n' . l:deli, "")
    "add match rule
    if empty(g:paint_indexes[color_index])
      let paint_name = "paint" . color_index
      let regex =  l:deli . ".*"
      let g:paint_indexes[color_index] = matchadd(paint_name, regex)
    endif
  "paste x register
  echo "final" . l:selection
  put =l:selection
  endif
  "restore x reg
  call setreg("x", save_x, save_x_type)
endfunc

"command! -nargs=0 Painter call s:visualToTable()

"TODO quitar el número hardcodeado
vnoremap <F6> :call codepainter#paintText(0)<cr>

func! s:eraseAll()
  "clean all delimiters
  let regex = g:delimeter . "[0-9]" . g:delimeter
  normal %s/a:regex//g
  "erase all match rules listed
  for index in g:paint_indexes
    call matchdelete(index)
  endfor
endfunc
