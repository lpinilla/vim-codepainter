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
let g:paint_n = 0
let g:layer0 = nvim_create_namespace("layer0")
let g:markings = {}
"map holding the markings folowing this structure
"markings = {
"   namespace: (string) string,
"   id: (int) line_n,
"   marks: [[int start_col, int end_col, string paint_name]]
"}

function! s:ValidateColorIndex(input)
  let l:n = str2nr(a:input)
  if type(l:n) != type(0)
    echom "input must be digit"
    return ''
  else
    if (l:n < 0 || l:n > 9)
        echom "Invalid index, must be from 0 to 9"
        return ''
    endif
  endif
  return l:n
endfunction


func! s:MarkSelection(start_pos, end_pos, v_mode)
    let l:paint_name = "paint" . g:paint_n
    let l:delta_pos = [a:end_pos[1] - a:start_pos[1], a:end_pos[2] - a:start_pos[2]]
    let l:mark = 0
    if l:delta_pos[0] == 0
        "calc n of bytes on the same line
        let l:mark = nvim_buf_add_highlight(0, g:layer0, l:paint_name,
                    \ a:start_pos[1] - 1,
                    \ a:start_pos[2] - 1, a:start_pos[2] + l:delta_pos[1])
    else
        "more than 1 line
        if a:v_mode == 'v' "visual mode
            let line = 0
            while line < l:delta_pos[0]
                let l:mark = nvim_buf_add_highlight(0, g:layer0, l:paint_name,
                            \ a:start_pos[1] - 1 + line,
                            \ a:start_pos[2] - 1, -1)
                let line += 1
            endwhile
            let l:mark = nvim_buf_add_highlight(0, g:layer0, l:paint_name,
            \ a:start_pos[1]+line - 1, 0, a:start_pos[2] + l:delta_pos[1])
        else "block visual mode
            let line = 0
            while line <= l:delta_pos[0]
                let l:mark = nvim_buf_add_highlight(0, g:layer0, l:paint_name,
                \ a:start_pos[1]+ line-1, a:start_pos[2] - 1, a:start_pos[2] +  l:delta_pos[1])
                let line += 1
            endwhile
        endif
    endif
    echom l:mark
endfunc

func! codepainter#paintText(v_mode) range
    "mark text
    call s:MarkSelection(getpos("'<"), getpos("'>"), a:v_mode)
endfunc

vnoremap <F2> :<c-u>call codepainter#paintText(visualmode())<cr>
nnoremap <F2> :<c-u>call codepainter#paintText('')<cr>
"Commands---------------------------------

command! -nargs=1 PainterPickColor call codepainter#ChangeColor(<f-args>)
command! -nargs=0 PainterEraseAll call codepainter#EraseAll()

func! codepainter#EraseAll()
    silent! call nvim_buf_clear_namespace(0, g:layer0, 1, -1)
endfunc

func! codepainter#ChangeColor(nPaint)
  let l:paint = s:ValidateColorIndex(a:nPaint)
  if l:paint != 0 && empty(l:paint)
    return
  endif
  let g:paint_n = l:paint
endfunc

