" check whether fancy cmds or default mappings are already loaded
" or the user doesn't want to load it

" fancy cmds {{{1
if !exists("g:loaded_painter_fancy_cmds")
  let g:loaded_painter_fancy_cmds = 1

  command! -nargs=1 PainterPickColor          silent! call codepainter#ChangeColor(<f-args>)
  command! -nargs=1 PainterPickColorByName    silent! call codepainter#ChangeColorByName(<f-args>)
  command! -nargs=0 PainterEraseAll           silent! call codepainter#EraseAll()
  command! -nargs=? PainterEraseLine          silent! call codepainter#EraseLine(<f-args>)
  command! -nargs=? PainterSaveMarks          silent! call codepainter#SaveMarks(<f-args>)
  command! -nargs=? PainterLoadMarks          silent! call codepainter#LoadMarks(<f-args>)
endif


" default mappings {{{1
if !exists("g:loaded_painter_default_mappings")
  let g:loaded_painter_default_mappings = 1

  if codepainter#config#DefaultMappings()
    vnoremap <silent> <F2> :<c-u> call codepainter#paintText(visualmode())<cr>
    nnoremap <silent> <F2> :<c-u> call codepainter#paintText('')<cr>
    nnoremap <silent> <F3> :<c-u> call codepainter#navigate()<cr>
  endif

endif
