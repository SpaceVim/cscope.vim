"=============================================================================
" cscope.vim --- after plugin for cscope.vim
" Copyright (c) 2016-2017 Wang Shidong & Contributors
" Author: Wang Shidong < wsdjeg at 163.com >
" URL: https://spacevim.org
" License: GPLv3
"=============================================================================

if !empty(g:cscope_preload_path)
  call cscope#_preloadDB()
endif

if g:cscope_auto_update == 1
  au BufWritePost * call cscope#_onChange()
endif


call cscope#_loadIndex()

