let s:save_cpo = &cpo
set cpo&vim

""
" @section Introduction, intro
" @order intro key-mappings dicts functions exceptions layers api faq
" cscope.vim is a smart cscope plugin for SpaceVim.
"
" It will try to find a proper cscope database for current file, then connect
" to it. If there is no proper cscope database for current file, you are
" prompted to specify a folder with a string like --
"
"     Can not find proper cscope db, please input a path to create cscope db
"     for.
"
" Then the plugin will create cscope database for you, connect to it, and find
" what you want. The found result will be listed in a location list window.
" Next
" time when you open the same file or other file that the cscope database can
" be
" used for, the plugin will connect to the cscope database automatically. You
" need not take care of anything about cscope database.
"
" When you have a file edited/added in those folders for which cscope
" databases
" have been created, cscove will automatically update the corresponding
" database.
"
" Cscove frees you from creating/connecting/updating cscope database, let you
" focus on code browsing.

" where to store cscope file?

function! s:echo(msg)
  echo a:msg
endfunction

if !exists('g:cscope_cmd')
  if executable('cscope')
    let g:cscope_cmd = 'cscope'
  else
    call s:echo('cscope: command not found')
    finish
  endif
endif

let s:FILE = SpaceVim#api#import('file')
let s:JSON = SpaceVim#api#import('data#json')
let s:cscope_cache_dir = s:FILE.unify_path('~/.cache/SpaceVim/cscope/')
let s:cscope_db_index = s:cscope_cache_dir.'index'
let s:dbs = {}




""
" search your {word} with {action} in the database suitable for current
" file.
function! cscope#find(action, word)
  let dirtyDirs = []
  for d in keys(s:dbs)
    if s:dbs[d]['dirty'] == 1
      call add(dirtyDirs, d)
    endif
  endfor
  if len(dirtyDirs) > 0
    call s:updateDBs(dirtyDirs)
  endif
  let dbl = s:AutoloadDB(s:FILE.unify_path(SpaceVim#plugins#projectmanager#current_root()))
  if dbl == 0
    try
      exe ':lcs f '.a:action.' '.a:word
      if g:cscope_open_location == 1
        lw
      endif
    catch
      echohl WarningMsg | echo 'Can not find '.a:word.' with querytype as '.a:action.'.' | echohl None
    endtry
  endif
endfunction

function! s:RmDBfiles()
  let odbs = split(globpath(s:cscope_cache_dir, "*"), "\n")
  for f in odbs
    call delete(f)
  endfor
endfunction

function! s:CheckNewFile(dir, newfile)
  let id = s:dbs[a:dir]['id']
  let cscope_files = s:cscope_cache_dir.id.".files"
  let files = readfile(cscope_files)
  if len(files) > g:cscope_split_threshold
    let cscope_files = s:cscope_cache_dir.id."_inc.files"
    if filereadable(cscope_files)
      let files = readfile(cscope_files)
    else
      let files = []
    endif
  endif
  if count(files, a:newfile) == 0
    call add(files, a:newfile)
    call writefile(files, cscope_files)
  endif
endfunction

function! s:FlushIndex()
  call writefile([s:JSON.json_encode(s:dbs)], s:cscope_db_index)
endfunction


function! s:ListFiles(dir)
  let d = []
  let f = []
  let cwd = a:dir
  try
    while cwd != ''
      let a = split(globpath(cwd, "*"), "\n")
      for fn in a
        if getftype(fn) == 'dir'
          if !exists('g:cscope_ignored_dir') || fn !~? g:cscope_ignored_dir
            call add(d, fn)
          endif
        elseif getftype(fn) != 'file'
          continue
        else
          if stridx(fn, ' ') != -1
            let fn = '"'.fn.'"'
          endif
          call add(f, fn)
        endif
      endfor
      let cwd = len(d) ? remove(d, 0) : ''
    endwhile
  catch /^Vim:Interrupt$/
  catch
    echo "caught" v:exception
  endtry
  return f
endfunction

""
" provide an interactive interface for finding what you want.
function! cscope#findInteractive(pattern) abort

endfunction

""
" update all existing cscope databases in case that you disable cscope database
" auto update.
function! cscope#updateDB() abort
  call s:updateDBs(keys(s:dbs))
endfunction

" 0 -- loaded
" 1 -- cancelled
function! s:AutoloadDB(dir)
  let ret = 0
  let m_dir = s:GetBestPath(a:dir)
  if m_dir == ""
    echohl WarningMsg | echo "Can not find proper cscope db, please input a path to generate cscope db for." | echohl None
    let m_dir = input("", a:dir, 'dir')
    if m_dir != ''
      let m_dir = s:CheckAbsolutePath(m_dir, a:dir)
      call s:InitDB(m_dir)
      call s:LoadDB(m_dir)
    else
      let ret = 1
    endif
  else
    let id = s:dbs[m_dir]['id']
    if cscope_connection(2, s:cscope_cache_dir.id.'.db') == 0
      call s:LoadDB(m_dir)
    endif
  endif
  return ret
endfunction

function! s:updateDBs(dirs)
  for d in a:dirs
    call s:CreateDB(d, 0)
  endfor
  call s:FlushIndex()
endfunction

function! cscope#clearDBs(dir)
  cs kill -1
  if a:dir == ""
    let s:dbs = {}
    call s:RmDBfiles()
  else
    let id = s:dbs[a:dir]['id']
    call delete(s:cscope_cache_dir.id.".files")
    call delete(s:cscope_cache_dir.id.'.db')
    call delete(s:cscope_cache_dir.id."_inc.files")
    call delete(s:cscope_cache_dir.id.'_inc.db')
    unlet s:dbs[a:dir]
  endif
  call s:FlushIndex()
endfunction

" complete function for command :CscopeClear
function! cscope#listDirs(A,L,P)
  return keys(s:dbs)
endfunction

function! ToggleLocationList()
  let l:own = winnr()
  lw
  let l:cwn = winnr()
  if(l:cwn == l:own)
    if &buftype == 'quickfix'
      lclose
    elseif len(getloclist(winnr())) > 0
      lclose
    else
      echohl WarningMsg | echo "No location list." | echohl None
    endif
  endif
endfunction

function! s:GetBestPath(dir)
  let f = substitute(a:dir,'\\','/','g')
  let bestDir = ""
  for d in keys(s:dbs)
    if stridx(f, d) == 0 && len(d) > len(bestDir)
      let bestDir = d
    endif
  endfor
  return bestDir
endfunction


function! s:CheckAbsolutePath(dir, defaultPath)
  let d = a:dir
  while 1
    if !isdirectory(d)
      echohl WarningMsg | echo "Please input a valid path." | echohl None
      let d = input("", a:defaultPath, 'dir')
    elseif (len(d) < 2 || (d[0] != '/' && d[1] != ':'))
      echohl WarningMsg | echo "Please input an absolute path." | echohl None
      let d = input("", a:defaultPath, 'dir')
    else
      break
    endif
  endwhile
  let d = s:FILE.unify_path(d)
  return d
endfunction

function! s:InitDB(dir)
  let id = localtime()
  let dir = s:FILE.path_to_fname(a:dir)
  let s:dbs[dir] = {}
  let s:dbs[dir]['id'] = id
  let s:dbs[dir]['loadtimes'] = 0
  let s:dbs[dir]['dirty'] = 0
  call s:CreateDB(a:dir, 1)
  call s:FlushIndex()
endfunction

function! s:LoadDB(dir)
  let dir = s:FILE.path_to_fname(a:dir)
  cs kill -1
  exe 'cs add '.s:cscope_cache_dir . dir .'.db'
  if filereadable(s:cscope_cache_dir . dir .'_inc.db')
    exe 'cs add '.s:cscope_cache_dir . dir .'_inc.db'
  endif
  let s:dbs[dir]['loadtimes'] = s:dbs[dir]['loadtimes'] + 1
  call s:FlushIndex()
endfunction

function! cscope#listDBs()
  let dirs = keys(s:dbs)
  if len(dirs) == 0
    echo "You have no cscope dbs now."
  else
    let s = [' ID                   LOADTIMES    PATH']
    for d in dirs
      let id = s:dbs[d]['id']
      if cscope_connection(2, s:cscope_cache_dir.id.'.db') == 1
        let l = printf("*%d  %10d            %s", id, s:dbs[d]['loadtimes'], d)
      else
        let l = printf(" %d  %10d            %s", id, s:dbs[d]['loadtimes'], d)
      endif
      call add(s, l)
    endfor
    echo join(s, "\n")
  endif
endfunction

function! cscope#loadIndex()
  let s:dbs = {}
  if ! isdirectory(s:cscope_cache_dir)
    call mkdir(s:cscope_cache_dir)
  elseif filereadable(s:cscope_db_index)
    let s:dbs = s:JSON.json_decode(join(readfile(s:cscope_db_index, ''), ''))
  else
    call s:RmDBfiles()
  endif
endfunction

function! cscope#preloadDB()
  let dirs = split(g:cscope_preload_path, s:FILE.pathSeparator)
  for m_dir in dirs
    let m_dir = s:CheckAbsolutePath(m_dir, m_dir)
    if !has_key(s:dbs, m_dir)
      call s:InitDB(m_dir)
    endif
    call s:LoadDB(m_dir)
  endfor
endfunction

function! CscopeFindInteractive(pat)
  call inputsave()
  let qt = input("\nChoose a querytype for '".a:pat."'(:help cscope-find)\n  c: functions calling this function\n  d: functions called by this function\n  e: this egrep pattern\n  f: this file\n  g: this definition\n  i: files #including this file\n  s: this C symbol\n  t: this text string\n\n  or\n  <querytype><pattern> to query `pattern` instead of '".a:pat."' as `querytype`, Ex. `smain` to query a C symbol named 'main'.\n> ")
  call inputrestore()
  if len(qt) > 1
    call CscopeFind(qt[0], qt[1:])
  elseif len(qt) > 0
    call CscopeFind(qt, a:pat)
  endif
  call feedkeys("\<CR>")
endfunction

function! cscope#onChange()
  let m_dir = s:GetBestPath(expand('%:p:h'))
  if m_dir != ""
    let s:dbs[m_dir]['dirty'] = 1
    call s:FlushIndex()
    call s:CheckNewFile(m_dir, expand('%:p'))
    redraw
    call s:echo('Your cscope db will be updated automatically, you can turn off this message by setting g:cscope_silent 1.')
  endif
endfunction

function! s:CreateDB(dir, init)
  let dir = s:FILE.path_to_fname(a:dir)
  let id = s:dbs[dir]['id']
  let cscope_files = s:cscope_cache_dir . dir . "/cscope.files"
  let cscope_db = s:cscope_cache_dir . dir . '/cscope.db'
  if ! isdirectory(s:cscope_cache_dir . dir)
    call mkdir(s:cscope_cache_dir . dir)
  endif
  if !filereadable(cscope_files)
    let files = s:ListFiles(a:dir)
    call writefile(files, cscope_files)
  endif
  try
    exec 'cs kill '.cscope_db
  catch
  endtry
  redir @x
  exec 'silent !'.g:cscope_cmd.' -b -i '.cscope_files.' -f'.cscope_db
  redi END
  if @x =~ "\nCommand terminated\n"
    echohl WarningMsg | echo "Failed to create cscope database for ".a:dir.", please check if " | echohl None
  else
    let s:dbs[dir]['dirty'] = 0
    exec 'cs add '.cscope_db
  endif
endfunction

function! cscope#create_databeses() abort
  let dir = SpaceVim#plugins#projectmanager#current_root()
  call s:InitDB(dir)
endfunction


""
" toggle the location list for found results.
function! cscope#toggleLocationList() abort

endfunction

function! cscope#process_data(query)
  let data = cscope#execute_command(a:query)

  let results = []

  for i in split(data, '\n')
    call add(results, cscope#line_parse(i))
  endfor

  return results
endfunction

function! cscope#find_this_symbol(keyword)
  return "cscope -d -L0 " . shellescape(a:keyword)
endfunction

function! cscope#global_definition(keyword)
  return "cscope -d -L1 " . shellescape(a:keyword)
endfunction

function! cscope#functions_called_by(keyword)
  return "cscope -d -L2 " . shellescape(a:keyword)
endfunction

function! cscope#functions_calling(keyword)
  return "cscope -d -L3 " . shellescape(a:keyword)
endfunction

function! cscope#text_string(keyword)
  return "cscope -d -L4 " . shellescape(a:keyword)
endfunction

function! cscope#egrep_pattern(keyword)
  return "cscope -d -L6 " . shellescape(a:keyword)
endfunction

function! cscope#find_file(keyword)
  return "cscope -d -L7 " . shellescape(a:keyword)
endfunction

function! cscope#including_this_file(keyword)
  return "cscope -d -L8 " . shellescape(a:keyword)
endfunction

function! cscope#assignments_to_symbol(keyword)
  return "cscope -d -L9 " . shellescape(a:keyword)
endfunction

function! cscope#line_parse(line)
  let details = split(a:line)
  return {
        \    "line": a:line,
        \    "file_name": details[0],
        \    "function_name": details[1],
        \    "line_number": str2nr(details[2], 10),
        \    "code_line": join(details[3:])
        \  }
endfunction


""
" @section FAQ, faq
" This is a section of all the faq about this plugin.

""
" @section KEY MAPPINGS, key-mappings
" The default key mappings has been removed from the plugin itself, since
" users may prefer different choices.
"
" So to use the plugin, you must define your own key mappings first.
"
" Below is the minimum key mappings.
" >
"   nnoremap <leader>fa :call cscope#findInteractive(expand('<cword>'))<CR>
"   nnoremap <leader>l :call cscope#toggleLocationList()<CR>
" <
"
" Some optional key mappings to search directly.
" >
"   s: Find this C symbol
"   nnoremap  <leader>fs :call cscope#find('s', expand('<cword>'))<CR>
"   " g: Find this definition
"   nnoremap  <leader>fg :call cscope#find('g', expand('<cword>'))<CR>
"   " d: Find functions called by this function
"   nnoremap  <leader>fd :call cscope#find('d', expand('<cword>'))<CR>
"   " c: Find functions calling this function
"   nnoremap  <leader>fc :call cscope#find('c', expand('<cword>'))<CR>
"   " t: Find this text string
"   nnoremap  <leader>ft :call cscope#find('t', expand('<cword>'))<CR>
"   " e: Find this egrep pattern
"   nnoremap  <leader>fe :call cscope#find('e', expand('<cword>'))<CR>
"   " f: Find this file
"   nnoremap  <leader>ff :call cscope#find('f', expand('<cword>'))<CR>
"   " i: Find files #including this file
"   nnoremap  <leader>fi :call cscope#find('i', expand('<cword>'))<CR>
" <

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et sw=2 cc=80:
