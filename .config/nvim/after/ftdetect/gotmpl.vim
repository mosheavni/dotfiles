augroup special_filetype
  autocmd BufNewFile,BufRead */templates/*.yaml,*/templates/*.tpl,*.gotmpl,,helmfile.yaml if search('{{.\+}}', 'nw') | setlocal filetype=gotmpl | endif
augroup end
