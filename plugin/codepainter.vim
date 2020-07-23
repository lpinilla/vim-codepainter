" check whether this script is already loaded
" or the user doesn't want to load it
if exists("g:loaded_painter")
  finish
endif
let g:loaded_painter = 1

command! -nargs=1 PainterPickColor call codepainter#ChangeColor(<f-args>)
command! -nargs=1 PainterChangeDelimiter call codepainter#ChangeDelimiter(<f-args>)
command! -nargs=0 PainterEraseAll call codepainter#EraseAll()

" NOTE: Maybe is a good idea to use leader instead
vnoremap <F2> :<c-u>call codepainter#paintText()<cr>
