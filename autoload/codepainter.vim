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

let g:paint_name = "paint0"
let g:auto_load_marks = 1 "look for json files with the same name and load them by default
let g:marks = {}
"map holding the markings folowing this structure
"marks = {
"   <key> line: <val> [start_pos, end_pos, mark_id, paint_name]
"}

function! s:ValidateColorIndex(input) abort
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

func! s:SameLineMark(start_pos, end_pos, delta_pos) abort
 "calc n of bytes on the same line
    let l:mark = nvim_buf_add_highlight(0, 0, g:paint_name,
                \ a:start_pos[1] - 1,
                \ a:start_pos[2] - 1,
                \ a:start_pos[2] + a:delta_pos[1])
    let g:marks[a:start_pos[1]] =
                \ [a:start_pos, a:end_pos, l:mark, g:paint_name]
endfunc

func! s:VisModeMark(start_pos, end_pos, delta_pos) abort
    let aux_start_pos = copy(a:start_pos)
    let aux_end_pos = copy(a:start_pos)
    let line = 0
    while line < a:delta_pos[0]
        let aux_start_pos[1] += line
        let aux_end_pos[1] += line
        let aux_end_pos[2] = 2147483647 "little hack to say all the line
        let l:mark = nvim_buf_add_highlight(0, 0, g:paint_name,
                    \ a:start_pos[1] - 1 + line,
                    \ a:start_pos[2] - 1, -1)
        let g:marks[a:start_pos[1] + line] =
                \  [copy(aux_start_pos), copy(aux_end_pos), l:mark, g:paint_name]
        let line += 1
    endwhile
    let aux_start_pos[1] += 1
    let l:mark = nvim_buf_add_highlight(0, 0, g:paint_name,
    \ a:start_pos[1] + line - 1, 0,
    \ a:start_pos[2] + a:delta_pos[1])
    let g:marks[a:start_pos[1] + line] =
            \  [aux_start_pos, a:end_pos, l:mark, g:paint_name]
endfunc

func! s:BlockVisModeMark(start_pos, end_pos, delta_pos) abort
    let line = 0
    let aux_start_pos = copy(a:start_pos)
    let aux_end_pos = copy(a:start_pos)
    while line < a:delta_pos[0]
        let aux_start_pos[1] += line
        let aux_end_pos[1] += line
        let aux_end_pos[2] = a:end_pos[2]
        let l:mark = nvim_buf_add_highlight(0, 0, g:paint_name,
                    \ a:start_pos[1] + line - 1,
                    \ a:start_pos[2] - 1,
                    \ a:start_pos[2] +  a:delta_pos[1])
        let g:marks[a:start_pos[1] + line] =
                    \  [copy(aux_start_pos), copy(aux_end_pos), l:mark, g:paint_name]
        let line += 1
    endwhile
    let aux_start_pos[1] += 1
    let aux_end_pos[1] += 1
    let l:mark = nvim_buf_add_highlight(0, 0, g:paint_name,
                    \ a:start_pos[1] + line - 1,
                    \ a:start_pos[2] - 1,
                    \ a:start_pos[2] +  a:delta_pos[1])
   let g:marks[a:start_pos[1] + line] =
                    \  [aux_start_pos, aux_end_pos, l:mark, g:paint_name]
endfunc


func! s:MarkSelection(start_pos, end_pos, v_mode) abort
    let l:delta_pos = [ a:end_pos[1] - a:start_pos[1],
                    \   a:end_pos[2] - a:start_pos[2]]
    if l:delta_pos[0] == 0 "on the same line
        call s:SameLineMark(a:start_pos, a:end_pos, l:delta_pos)
    else "more than 1 line
        if a:v_mode == 'v' "visual mode
            call s:VisModeMark(a:start_pos, a:end_pos, l:delta_pos)
        else "block visual mode
            call s:BlockVisModeMark(a:start_pos, a:end_pos, l:delta_pos)
        endif
    endif
endfunc

func! codepainter#paintText(v_mode) range abort
    "mark text
    let l:start_pos = getpos("'<")
    let l:end_pos = getpos("'>")
    if l:start_pos == [0,0,0,0] && l:end_pos == [0,0,0,0]
        return
    endif
    "if last character is \n, subtract 1 from column (to avoid problems)
    if getline("'>")[col("'>") - 1] == "0x0a"
        let l:end_pos[2] -= 1
    endif
    let index = 0
    while index <= l:end_pos[1] - l:start_pos[1]
        "if it wasn't stored, we mark it
        if !has_key(g:marks, l:start_pos[1] + index)
            call s:MarkSelection(l:start_pos, l:end_pos, a:v_mode)
            return
        endif
        let l:known_mark = g:marks[l:start_pos[1] + index]
        let l:col_deltas = [l:start_pos[2] - l:known_mark[0][2],
                    \       l:end_pos[2] - l:known_mark[1][2]]
        "inside the known mark -> unmark
        if (l:col_deltas[0] >= 0 && l:col_deltas[1] <= 0)
            call nvim_buf_clear_namespace(0, l:known_mark[2], l:start_pos[1]+index-1,-1)
            unlet g:marks[l:start_pos[1]+index]
            if(l:known_mark[3] != g:paint_name)
                call s:MarkSelection(l:start_pos, l:end_pos, a:v_mode)
            endif
        elseif (l:col_deltas[0] >= 0 && l:col_deltas[1] > 0) "extending mark
            call nvim_buf_clear_namespace(0, l:known_mark[2], l:start_pos[1]+index-1,-1)
            call s:MarkSelection(l:start_pos, l:end_pos, a:v_mode)
        elseif (l:col_deltas[0] < 0 && l:col_deltas[1] >= 0)
            call nvim_buf_clear_namespace(0, l:known_mark[2], l:start_pos[1]+index-1,-1)
        endif
        let index += 1
    endwhile
endfunc

func! codepainter#EraseAll() abort
    "loop through the list and delete each one
    for key in keys(g:marks)
        echom g:marks[key]
        silent! call nvim_buf_clear_namespace(0, g:marks[key][2], 1, -1)
    endfor
    let g:marks = {}
endfunc

func! codepainter#ChangeColor(nPaint) abort
  let l:paint = s:ValidateColorIndex(a:nPaint)
  if l:paint != 0 && empty(l:paint)
    return
  endif
  let g:paint_name = "paint" . l:paint
endfunc

func! codepainter#ChangeColorByName(strPaint) abort
    if a:strPaint != type(1) || empty(a:strPaint)
        return
    endif
    let g:paint_name = substitute(a:strPaint, "\"", "" ,"g")
endfunc

func! codepainter#SaveMarks(...) abort
    let l:path = a:0 == 0 ? expand("%") : substitute(a:1, "\"", "","g")
    let l:path = substitute(l:path, expand("%:e"), "json", "")
    let jsonString = json_encode(g:marks)
    execute ("redir! >" . l:path)
    silent! echon jsonString
    redir END
    echom "Saved on " . l:path
endfunc

func! codepainter#LoadMarks(...) abort
    let l:path = a:0 == 0 ? expand("%") : substitute(a:1, "\"", "","g")
    let l:path = substitute(l:path, expand("%:e"), "json", "")
    let l:file = readfile(l:path)
    let loaded_marks = json_decode(l:file)
    let saved_paint = g:paint_name
    for l:mark in keys(loaded_marks)
        let l:aux = loaded_marks[l:mark]
        let g:paint_name = l:aux[3]
        call s:MarkSelection(l:aux[0], l:aux[1], "v")
    endfor
    let g:paint_name = saved_paint
    echom "Loaded marks from " . l:path
endfunc

"load marks for this file
if g:auto_load_marks | silent! call codepainter#LoadMarks(substitute(expand("%"), expand("%:e"), "json", "")) | endif
