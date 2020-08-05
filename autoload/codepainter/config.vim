let s:cpo_save = &cpo
set cpo&vim

func! codepainter#config#DefaultMappings() abort
  return get(g:, 'codepainter_default_mappings', 1)
endfunc

let &cpo = s:cpo_save
unlet! s:cpo_save
