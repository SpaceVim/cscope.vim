"=============================================================================
" cscope.vim --- after plugin for cscope.vim
" Copyright (c) 2016-2017 Wang Shidong & Contributors
" Author: Wang Shidong < wsdjeg at 163.com >
" URL: https://spacevim.org
" License: GPLv3
"=============================================================================

if exists('g:cscope_preload_path')
  call cscope#preloadDB()
endif

if g:cscope_auto_update == 1
  au BufWritePost * call cscope#onChange()
endif


call cscope#loadIndex()
