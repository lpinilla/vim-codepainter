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
let g:paint_name = "paint0"
let g:marks = {}
"map holding the markings folowing this structure
"marks = {
"   <key> line: <val> [start_pos, end_pos, mark_id, paint_name]
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
    let l:delta_pos = [a:end_pos[1] - a:start_pos[1], a:end_pos[2] - a:start_pos[2]]
    let l:mark = 0
    "on the same line
    if l:delta_pos[0] == 0
        "calc n of bytes on the same line
        let l:mark = nvim_buf_add_highlight(0, 0, g:paint_name,
                    \ a:start_pos[1] - 1,
                    \ a:start_pos[2] - 1,
                    \ a:start_pos[2] + l:delta_pos[1])
        let g:marks[a:start_pos[1]] =
                    \ [a:start_pos, a:end_pos, l:mark, g:paint_name]
    else "more than 1 line
        if a:v_mode == 'v' "visual mode
            let line = 0
            while line < l:delta_pos[0]
                let l:mark = nvim_buf_add_highlight(0, 0, g:paint_name,
                            \ a:start_pos[1] - 1 + line,
                            \ a:start_pos[2] - 1, -1)
                let g:marks[a:start_pos[1] + line - 1] =
                            \ [a:start_pos, a:end_pos, l:mark, g:paint_name]
                let line += 1
            endwhile
            let l:mark = nvim_buf_add_highlight(0, 0, g:paint_name,
            \ a:start_pos[1]+line - 1, 0,
            \ a:start_pos[2] + l:delta_pos[1])
            let g:marks[a:start_pos[1] + line - 1] =
                    \  [a:start_pos, a:end_pos, l:mark, g:paint_name]
        else "block visual mode
            let line = 0
            while line <= l:delta_pos[0]
                let l:mark = nvim_buf_add_highlight(0, 0, g:paint_name,
                \ a:start_pos[1]+ line-1,
                \ a:start_pos[2] - 1,
                \ a:start_pos[2] +  l:delta_pos[1])
                let g:marks[a:start_pos[1] + line] =
                        \  [a:start_pos, a:end_pos, l:mark, g:paint_name]
                let line += 1
            endwhile
        endif
    endif
endfunc

func! codepainter#paintText(v_mode) range
    "mark text
    let l:start_pos = getpos("'<")
    let l:end_pos = getpos("'>")
    "check if it was stored, it means we need to unmark
    if has_key(g:marks, l:start_pos[1])
        let l:known_mark = g:marks[l:start_pos[1]]
        let l:col_deltas = [l:start_pos[2] - l:known_mark[0][2], l:end_pos[2] - l:known_mark[1][2]]
        "inside the known mark -> unmark
        if (l:col_deltas[0] >= 0 && l:col_deltas[1] <= 0)
            call nvim_buf_clear_namespace(0, l:known_mark[2], l:start_pos[1] - 1, -1)
            "if(l:known_mark[3] == g:paint)
            unlet g:marks[l:start_pos[1]]
        endif
    else
        call s:MarkSelection(l:start_pos, l:end_pos, a:v_mode)
    endif
endfunc

vnoremap <F2> :<c-u>call codepainter#paintText(visualmode())<cr>
nnoremap <F2> :<c-u>call codepainter#paintText('')<cr>
"Commands---------------------------------

command! -nargs=1 PainterPickColor call codepainter#ChangeColor(<f-args>)
command! -nargs=1 PainterPickColorByName call codepainter#ChangeColorByName(<f-args>)
command! -nargs=0 PainterEraseAll call codepainter#EraseAll()

func! codepainter#EraseAll()
    "loop through the list and delete each one
    for key in keys(g:marks)
        echom g:marks[key]
        silent! call nvim_buf_clear_namespace(0, g:marks[key][2], 1, -1)
    endfor
    let g:marks = {}
endfunc

func! codepainter#ChangeColor(nPaint)
  let l:paint = s:ValidateColorIndex(a:nPaint)
  if l:paint != 0 && empty(l:paint)
    return
  endif
  let g:paint_name = "paint" . l:paint
endfunc

func! codepainter#ChangeColorByName(strPaint)
    if a:strPaint != type(1)
        return
    endif
    let g:paint_name = substitute(a:strPaint, "\"", "" ,"g")
endfunc

