" check whether this script is already loaded
" or the user doesn't want to load it
if exists("g:loaded_painter")
  finish
endif
let g:loaded_painter = 1

vnoremap <F2> :<c-u>call codepainter#paintText(visualmode())<cr>
nnoremap <F2> :<c-u>call codepainter#paintText('')<cr>

command! -nargs=1 PainterPickColor call codepainter#ChangeColor(<f-args>)
command! -nargs=1 PainterPickColorByName call codepainter#ChangeColorByName(<f-args>)
command! -nargs=0 PainterEraseAll call codepainter#EraseAll()
command! -nargs=1 PainterEraseLine call codepainter#EraseLine(<f-args>)
command! -nargs=? PainterSaveMarks call codepainter#SaveMarks(<f-args>)
command! -nargs=? PainterLoadMarks call codepainter#LoadMarks(<f-args>)
