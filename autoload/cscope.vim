let s:save_cpo = &cpo
set cpo&vim

""
" @section Introduction, intro
" @library
" @order intro key-mappings dicts functions exceptions layers api faq
" Cscove(new name for this plugin, since cscope.vim is used too widely.) is a
" smart cscope helper for vim.
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

""
" search your {pattern} with {querytype} in the database suitable for current
" file.
function! cscope#find(querytype, pattern) abort
  
endfunction

""
" provide an interactive interface for finding what you want.
function! cscope#findInteractive(pattern) abort
  
endfunction

""
" update all existing cscope databases in case that you disable cscope database
" auto update.
function! cscope#updateDB() abort
  
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
