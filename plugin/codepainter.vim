" check whether this script is already loaded
if exists("g:loaded_painter")
  finish
endif
let g:loaded_painer = 1

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


let g:paint_indexes = []

"The delimiter will have the form 'delimiter'[0-9]'delimiter'. Default will be #0# for paint0.
let g:delimiter = "#"


func! Test2(text)
    echom a:text
endfunction

"Thanks @zah https://stackoverflow.com/questions/12805922/vim-vmap-send-selected-text-as-parameter-to-function ! (adapted to restore x register)
func! GetSelectedText(color_index)
  if color_index < 0
      echom "Invalid color"
      return
  elseif color_index > 9
      echom "only 10 colors available"
      return
  "save x reg
  let save_x = getreg("x")
  let save_x_type = getregtype("x")
  normal gv"xy
  let selection = getreg("x")
  "build delimiter
  let deli = g:delimiter . a:color_index . g:delimiter
  "check if its already painted
  if selection[0:3] == deli
    "remove marker in every line of selection
    "TODO
    "check if there is another marker
    if normal /deli == ""
      "erase match rule
      call matchdelete(a:color_index)
  else
    "paint
    "add match rule
    if paint_indexes[color_index] == 0


  "restore x reg
  call setreg("x", save_x, save_x_type)
  normal gv
  return
endfunc

"command! -nargs=0 Painter call s:visualToTable()

"vnoremap <F6> :call Test2(GetSelectedText())<cr>
"no hardcodear el número
vnoremap <F6> :call GetSelectedText(0)<cr>

func! s:eraseAll():
  "clean all delimiters
  let regex = g:delimeter . "[0-9]" . g:delimeter
  normal %s/a:regex//g
  "erase match rules
  for i in paint_indexes
    call matchdelete(i)
endfunc
