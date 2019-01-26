

if exists('g:cscope_preload_path')
  call cscope#_preloadDB()
endif

if g:cscope_auto_update == 1
  au BufWritePost * call <SID>onChange()
endif


call <SID>loadIndex()

