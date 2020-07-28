" defining the colors
hi paint0 gui=reverse cterm=reverse ctermfg=47  ctermbg=236 guifg=#A3BE8C guibg=#2E3440
hi paint1 gui=reverse cterm=reverse ctermfg=185 ctermbg=236 guifg=#EBCB8B guibg=#2E3440
hi paint2 gui=reverse cterm=reverse ctermfg=15  ctermbg=236 guifg=#A1B6BF guibg=#2E3440
hi paint3 gui=reverse cterm=reverse ctermfg=64  ctermbg=236 guifg=#BFA484 guibg=#2E3440
hi paint4 gui=reverse cterm=reverse ctermfg=167 ctermbg=236 guifg=#BF7A86 guibg=#2E3440
hi paint5 gui=reverse cterm=reverse ctermfg=176 ctermbg=236 guifg=#BB9BF2 guibg=#2E3440
hi paint6 gui=reverse cterm=reverse ctermfg=97  ctermbg=236 guifg=#676073 guibg=#2E3440
hi paint7 gui=reverse cterm=reverse ctermfg=242 ctermbg=15  guifg=#2D401C guibg=#ffffff
hi paint8 gui=reverse cterm=reverse ctermfg=62  ctermbg=236 guifg=#6868BD guibg=#2E3440
hi paint9 gui=reverse cterm=reverse ctermfg=142 ctermbg=236 guifg=#C2B330 guibg=#2E3440

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

func! s:AuxMark(line, start_col, end_col) abort
    if has('nvim')
        return nvim_buf_add_highlight(0, 0, g:paint_name, a:line - 1, a:start_col - 1, a:end_col)
    else
        let l:mark = len(g:marks)
        call prop_type_add( l:mark, {'highlight': g:paint_name })
        call prop_add( a:line, a:start_col, {'length' : a:end_col == -1 ? "99999" : a:end_col - a:start_col + 1 , 'type': l:mark })
        return l:mark
    endif
endfunc

func! s:AuxUnmark(line, id)
    if has('nvim')
        call nvim_buf_clear_namespace(0, a:id, a:line - 1,-1)
    else
        call prop_remove({'type': a:id}, a:line)
        call prop_type_delete(a:id)
    endif
    unlet g:marks[a:line]
endfunc

func! s:SameLineMark(start_pos, end_pos, delta_pos) abort
    let l:mark = s:AuxMark(a:start_pos[1], a:start_pos[2], a:start_pos[2] + a:delta_pos[1])
    let g:marks[a:start_pos[1]] = [a:start_pos, a:end_pos, l:mark, g:paint_name]
endfunc

func! s:VisModeMark(start_pos, end_pos, delta_pos) abort
    let aux_start_pos = copy(a:start_pos)
    let aux_end_pos = copy(a:start_pos)
    let line = 0
    while line < a:delta_pos[0]
        let aux_start_pos[1] += line
        let aux_end_pos[1] += line
        let aux_end_pos[2] = 2147483647 "little hack to say all the line
        let l:mark = s:AuxMark(a:start_pos[1] + line, a:start_pos[2], -1)
        let g:marks[a:start_pos[1] + line] = [copy(aux_start_pos), copy(aux_end_pos), l:mark, g:paint_name]
        let line += 1
    endwhile
    let aux_start_pos[1] += 1
    let l:mark = s:AuxMark(a:start_pos[1] + line, a:start_pos[2], a:start_pos[2] + a:delta_pos[1])
    let g:marks[a:start_pos[1] + line] = [aux_start_pos, a:end_pos, l:mark, g:paint_name]
endfunc

func! s:BlockVisModeMark(start_pos, end_pos, delta_pos) abort
    let aux_start_pos = copy(a:start_pos)
    let aux_end_pos = copy(a:start_pos)
    let line = 0
    while line < a:delta_pos[0]
        let aux_start_pos[1] += line
        let aux_end_pos[1] += line
        let aux_end_pos[2] = a:end_pos[2]
        let l:mark = s:AuxMark(a:start_pos[1] + line, a:start_pos[2], a:start_pos[2] + a:delta_pos[1])
        let g:marks[a:start_pos[1] + line] = [copy(aux_start_pos), copy(aux_end_pos), l:mark, g:paint_name]
        let line += 1
    endwhile
    let aux_start_pos[1] += 1
    let aux_end_pos[1] += 1
    let l:mark = s:AuxMark(a:start_pos[1] + line, a:start_pos[2], a:start_pos[2] + a:delta_pos[1])
    let g:marks[a:start_pos[1] + line] = [aux_start_pos, aux_end_pos, l:mark, g:paint_name]
endfunc

func! s:MarkSelection(start_pos, end_pos, v_mode) abort
    let l:delta_pos = [ a:end_pos[1] - a:start_pos[1], a:end_pos[2] - a:start_pos[2]]
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
        let l:col_deltas = [l:start_pos[2] - l:known_mark[0][2], l:end_pos[2] - l:known_mark[1][2]]
        if (l:col_deltas[0] >= 0 && l:col_deltas[1] <= 0) "inside the known mark -> unmark
            call s:AuxUnmark(l:start_pos[1]+ index, l:known_mark[2])
            if(l:known_mark[3] != g:paint_name)
                call s:MarkSelection(l:start_pos, l:end_pos, a:v_mode)
            endif
        elseif (l:col_deltas[0] >= 0 && l:col_deltas[1] > 0) "extending mark
            call s:AuxUnmark(l:start_pos[1]+ index, l:known_mark[2])
            call s:MarkSelection(l:start_pos, l:end_pos, a:v_mode)
        elseif (l:col_deltas[0] < 0 && l:col_deltas[1] >= 0) "outside bounds, treating as unmarking
            call s:AuxUnmark(l:start_pos[1] + index, l:known_mark[2])
        endif
        let index += 1
    endwhile
endfunc

func! codepainter#EraseAll() abort
    "loop through the list and delete each one
    if has('nvim')
        for key in keys(g:marks)
            silent! call nvim_buf_clear_namespace(0, g:marks[key][2], 1, -1)
        endfor
    else
        for key in keys(g:marks)
            silent! call prop_remove({'type': g:marks[key][2]}, g:marks[key][1][1])
            silent! call prop_type_delete(g:marks[key][2])
        endfor
    endif
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
    let loaded_marks = json_decode(l:file[0])
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
