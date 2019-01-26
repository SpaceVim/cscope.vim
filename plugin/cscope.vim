"=============================================================================
" cscope.vim --- cscope layer plugin
" Copyright (c) 2016-2017 Wang Shidong & Contributors
" Author: Wang Shidong < wsdjeg at 163.com >
" URL: https://spacevim.org
" License: GPLv3
"=============================================================================

if !exists('g:cscope_silent')
    ""
    " Silent or not when run cscope command. by default it is 1.
    let g:cscope_silent = 1
endif

if !exists('g:cscope_auto_update')
    let g:cscope_auto_update = 1
endif

if !exists('g:cscope_open_location')
    let g:cscope_open_location = 1
endif

if !exists('g:cscope_split_threshold')
    let g:cscope_split_threshold = 10000
endif

set cscopequickfix=s-,g-,d-,c-,t-,e-,f-,i-
com! -nargs=? -complete=customlist,cscope#_listDirs CscopeClear call cscope#clearDBs("<args>")
com! -nargs=0 CscopeList call cscope#listDBs()
