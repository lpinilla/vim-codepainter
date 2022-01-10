let s:cpo_save = &cpo
set cpo&vim

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

if !exists("g:paint_name")
  let g:paint_name = "paint0"
endif
let g:auto_load_marks = 1 "look for json files with the same name and load them by default
let g:marks = {}
let g:vim_index = 0
let g:navigation_index = 0
let g:has_nvim = has('nvim')

"dictionary holding the markings folowing this structure
"marks = {
"   <key> line: <val> [[start_pos, end_pos, mark_id, paint_name]]
"}

func! s:AuxMark(start_pos, end_pos) abort
    let l:mark = 0
    if g:has_nvim
        let l:mark = nvim_buf_add_highlight(0, 0, g:paint_name, a:start_pos[1] - 1, a:start_pos[2] - 1, a:end_pos[2])
    else
        call prop_type_add(g:vim_index, {'highlight': g:paint_name })
        call prop_add( a:start_pos[1], a:start_pos[2], {'length' : a:end_pos[2] == -1 ? "99999" : a:end_pos[2] - a:start_pos[2] + 1 , 'type': g:vim_index})
    let l:mark = g:vim_index
    let g:vim_index += 1
    endif
    if !has_key(g:marks, a:start_pos[1])
        let g:marks[a:start_pos[1]] = []
    endif
    let g:marks[a:start_pos[1]] = add(g:marks[a:start_pos[1]], [copy(a:start_pos), copy(a:end_pos), l:mark, g:paint_name])
endfunc

func! s:AuxUnmark(line, id)
    if g:has_nvim
        call nvim_buf_clear_namespace(0, a:id, a:line - 1,-1)
    else
        call prop_remove({'type': a:id}, a:line)
        call prop_type_delete(a:id)
    endif
    let idx = 0
    while idx < len(g:marks[a:line])
        let l:mark = g:marks[a:line][idx]
        if l:mark[2] == a:id
            call remove(g:marks[a:line], idx)
            break
        endif
        let idx += 1
    endwhile
    if empty(g:marks[a:line])
        unlet g:marks[a:line]
    endif
endfunc

func! s:MultiLineMark(start_pos, end_pos, delta_pos, aux_col) abort
    let aux_start_pos = copy(a:start_pos)
    let aux_end_pos = copy(a:start_pos)
    let aux_end_pos[2] = a:end_pos[2]
    let line = 0
    while line < a:delta_pos
        let end_col = col([aux_start_pos[1], "$"])
        let aux_end_pos[2] = min([a:aux_col, end_col])
        call s:AuxMark(aux_start_pos, aux_end_pos)
        let aux_start_pos[1] += 1
        let aux_end_pos[1] += 1
        let line += 1
    endwhile
    let end_col = col([aux_start_pos[1], "$"])
    let aux_end_pos[2] = min([a:aux_col, end_col])
    call s:AuxMark(aux_start_pos, aux_end_pos)
endfunc

func! s:MarkSelection(start_pos, end_pos, v_mode) abort
    let l:delta_pos = a:end_pos[1] - a:start_pos[1]
    if l:delta_pos == 0 "on the same line
        call s:MultiLineMark(a:start_pos,a:end_pos, l:delta_pos, a:end_pos[2])
    else "more than 1 line
        if a:v_mode == 'v' "visual mode
            call s:MultiLineMark(a:start_pos, a:end_pos, l:delta_pos, 2147483647)
        else "block visual mode
            call s:MultiLineMark(a:start_pos, a:end_pos, l:delta_pos, a:end_pos[2])
        endif
    endif
endfunc

func! codepainter#paintText(v_mode) range abort
    "mark text
    let l:start_pos = getpos("'<")
    let l:end_pos = getpos("'>")
    "neovim doesn't clean the position of < and > (selections), so
    "the only way of knowing if we are indeed painting is if the
    "cursor is inside that range
    if l:start_pos[1] != getpos(".")[1]
        return
    endif
    if l:start_pos == [0,0,0,0] && l:end_pos == [0,0,0,0]
        return
    endif
    "if last character is \n, subtract 1 from column (to avoid problems)
    if getline("'>")[col("'>") - 1] == "0x0a"
        let l:end_pos[2] -= 1
    endif
    let index = 0
    let l:found = 0
    let l:remarked = 0
    let lines = l:end_pos[1] - l:start_pos[1]
    while !l:remarked && l:found != (lines+1) && index <= lines
        "if it wasn't stored, we mark it
        if !has_key(g:marks, l:start_pos[1] + index)
            call s:MarkSelection(l:start_pos, l:end_pos, a:v_mode)
            return
        endif
        for known_mark in g:marks[l:start_pos[1] + index]
            let l:col_deltas = [l:start_pos[2]  - known_mark[0][2], l:end_pos[2] - known_mark[1][2]]
            if l:col_deltas == [0, 0] || l:col_deltas == [0, -2147483646]
                let l:found += 1
                call s:AuxUnmark(l:start_pos[1] + index, known_mark[2])
                if known_mark[3] != g:paint_name
                    call s:MarkSelection(l:start_pos, l:end_pos, a:v_mode)
                    let l:remarked = 1
                    break
                endif
            endif
        endfor
        let index += 1
    endwhile
    if l:found == 0
        call s:MarkSelection(l:start_pos, l:end_pos, a:v_mode)
    endif
endfunc

func! codepainter#EraseAll() abort
    "loop through the dictionary and delete each one in the array, if the array is
    "empty, remove from the dictionary
    let nvim_flag = g:has_nvim
    for line in keys(g:marks)
        for l:mark in g:marks[line]
            if nvim_flag
                silent! call nvim_buf_clear_namespace(0, l:mark[2], 0, -1)
            else
                silent! call prop_remove({'type': l:mark[2]}, l:mark[1][1])
                silent! call prop_type_delete(l:mark[2])
            endif
        endfor
    endfor
    let g:marks = {}
endfunc

func! codepainter#EraseLine(...) abort
    if a:0 == 0
        call s:EraseLines(1)
    elseif a:0 == 1
        call s:EraseLines(a:1, 1)
    else
        call s:EraseLines(a:1, a:2)
    endif
endfunc

func! s:EraseLines(...) abort
    let l:line = a:0 == 1 ? getpos(".")[1] : a:1
    let l:n_lines = a:0 == 1 ? a:1 : a:2
    let nvim_flag = g:has_vim
    let l:iter = 0
    while l:iter < l:n_lines
        for l:mark in g:marks[l:line + l:iter]
            if nvim_flag
                silent! call nvim_buf_clear_namespace(0, l:mark[2], 0, -1)
            else
                silent! call prop_remove({'type': l:mark[2]}, l:mark[1][1])
                silent! call prop_type_delete(l:mark[2])
            endif
           unlet g:marks[l:line + l:iter]
        endfor
        let l:iter += 1
    endwhile
endfunc

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
    let l:aux = expand("%:e")
    if len(l:aux) == 0
        let l:path = l:path . ".json"
    else
        let l:path = substitute(l:path, expand("%:e"), "json", "")
    endif
    let jsonString = json_encode(g:marks)
    execute ("redir! >" . l:path)
    silent! echon jsonString
    redir END
    echom "Saved on " . l:path
endfunc

func! codepainter#LoadMarks(...) abort
    let l:path = a:0 == 0 ? expand("%") : substitute(a:1, "\"", "","g")
    if a:0 == 0
        let l:aux = expand("%:e")
        if len(l:aux) == 0
            let l:path = l:path . ".json"
        else
            let l:path = substitute(l:path, expand("%:e"), "json", "")
        endif
    endif
    let l:file = readfile(l:path)
    let loaded_marks = json_decode(l:file[0])
    let saved_paint = g:paint_name
    for l:line in keys(loaded_marks)
        for l:mark in loaded_marks[l:line]
            let l:aux = l:mark
            let g:paint_name = l:aux[3]
            call s:MarkSelection(l:aux[0], l:aux[1], "v")
        endfor
    endfor
    let g:paint_name = saved_paint
    echom "Loaded marks from " . l:path
endfunc

func! s:DictToOrderedList() abort
    let l:marks_list = []
    " loop through each mark of the dict and store start positions
    for l:key in keys(g:marks)
        let l:marks_list = l:marks_list + [g:marks[l:key][0][0]]
    endfor
    " return the list with natural order
    return sort(l:marks_list)
endfunc

func! codepainter#navigate() abort
    let l:ordered_marks = s:DictToOrderedList()
    call setpos(".", l:ordered_marks[g:navigation_index % len(l:ordered_marks)])
    let g:navigation_index += 1
endfunc

"load marks for this file
if g:auto_load_marks | silent! call codepainter#LoadMarks(substitute(expand("%"), expand("%:e"), "json", "")) | endif

let &cpo = s:cpo_save
unlet! s:cpo_save
