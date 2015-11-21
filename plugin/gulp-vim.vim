" A simple gulp wrapper for vim
" Version     : 0.7.1
" Creation    : 2015-03-18
" Last Change : 2015-11-21
" Maintainer  : Kabbaj Amine <amine.kabb@gmail.com>
" License     : This file is placed in the public domain.

" Vim options {{{1
if exists('g:gulp_vim_loaded')
	finish
endif
let g:gulp_vim_loaded = 1

" To avoid conflict problems.
let s:saveFileFormat = &fileformat
let s:saveCpoptions = &cpoptions
set fileformat=unix
set cpoptions&vim
" }}}

" COMMANDS
" =====================================================================
" Main {{{1
command -nargs=* -complete=custom,s:CompleteTaskNames Gulp :call s:ExecCmd('s:Gulp', 'e', <f-args>)
command -nargs=* -complete=custom,s:CompleteTaskNames GulpExt :call s:ExecCmd('s:GulpExternal', 'c', <f-args>)
command GulpTasks :call s:ExecCmd('s:GetTaskNames', 'e')
command -nargs=? -complete=file GulpFile :call s:Gulpfile(<f-args>)
" CTRLP {{{1
if exists(':CtrlP') ==# 2
	command CtrlPGulp call ctrlp#init(ctrlp#gulp#id())
endif
" }}}

" VARIABLES
" =====================================================================
" Default gulpfile {{{1
if !exists('g:gv_default_gulpfile')
	let g:gv_default_gulpfile = 'gulpfile.js'
endif
" Get used OS & dir separator {{{1
if has('unix')
	let s:os = 'unix' | let s:sep = '/'
elseif has('win32')
	let s:os = 'win32' | let s:sep = '\'
endif
" Add --no-color flag if gui vim is used {{{1
let s:gulpCliFlags = has('gui_running') ? ' --no-color' : ''
" Rvm hack for unix (Source rvm script file if it exists when using an external terminal) {{{1
" http://stackoverflow.com/a/8493284
let s:rvmHack = exists('g:gv_rvm_hack') ? '[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" &&' : ''
" Use Dispatch plugin (Enabled by default) {{{1
if !exists('g:gv_use_dispatch')
	let g:gv_use_dispatch = 1
endif
" Gulp command to use with CtrlP {{{1
if !exists('g:gv_ctrlp_cmd')
	let g:gv_ctrlp_cmd = 'Gulp'
endif
" Return to prompt option {{{1
if exists('g:gv_return_2_prompt')
	let s:prompt = {
				\ 'unix': ' exec bash',
				\ 'win32': ' /k'
				\ }
else
	let s:prompt = {
				\ 'unix': '',
				\ 'win32': ' /c'
				\ }
endif
" Command line for executing external terminal {{{1
let s:termCmd = {
			\ 'unix': 'exo-open --launch TerminalEmulator bash -c "' . s:rvmHack . ' %s ; ' . s:prompt.unix . '" &',
			\ 'win32': 'start cmd ' . s:prompt.win32 . ' %s &'
		\}
" }}}

" FUNCTIONS
" =====================================================================
function s:Gulpfile(...) "{{{1
	let l:gf = exists('a:1') ? a:1 : 'gulpfile.js'
	if l:gf !~# '^gulpfile'
		echohl Error | echo l:gf . ' is not a valid gulpfile' | echohl None
		return 0
	else
		let g:gv_default_gulpfile = l:gf
		return filereadable(getcwd() . s:sep . l:gf)
	endif
endfunction
function s:Gulp(...) " {{{1
	" Return gulp execution with given param(s) as task name(s) (By default is 'default' :D)

	let l:tasks = a:0 >=# 1 ? join(a:000, ' ') : 'default'
	echohl Title | echo 'Execute task(s) -> ' . l:tasks . ':' | echohl None
	let l:flags = ' --gulpfile ' . g:gv_default_gulpfile . ' ' . s:gulpCliFlags
	return system('gulp ' . l:tasks . l:flags)
endfunction
function s:GulpExternal(...) " {{{1
	" Return gulp execution with given param(s) as task name(s) in external terminal.

	let l:tasks = a:0 >=# 1 ? join(a:000, ' ') : 'default'
	let l:flags = ' --gulpfile ' . g:gv_default_gulpfile
	if g:gv_use_dispatch && exists(':Start')
		return printf('Start! gulp %s %s', l:tasks, l:flags)
	else
		return printf('silent :!%s gulp %s %s', s:termCmd[s:os], l:tasks, l:flags)
	endif
endfunction
function s:GetTaskNames() " {{{1
	" Return task names as strings from gulpfile

	let l:tasks = []
	for l:line in readfile(g:gv_default_gulpfile)
		if l:line =~# '^gulp.task'
			" Get task name & add it to a list of tasks
			let l:task = l:line[match(l:line, "'", 0, 1) + 1 : match(l:line, "'", 0, 2) - 1]
			call add(l:tasks, l:task)
		endif
	endfor
	let l:taskMsg = len(l:tasks) ==# 1 ? '(1 task)' : '(' . len(l:tasks) . ' tasks)'
	echohl Title | echo g:gv_default_gulpfile . ' ' . l:taskMsg . ':' | echohl None
	return join(l:tasks, "\n")

endfunction
" }}}
function s:ExecCmd(funName, action, ...) " {{{1
	" Automate the vim command creation:
	"	- Check if gulpfile is readable
	"	- Echo or execute when needed

	let l:args = exists('a:000') ? a:000 : []
	if s:Gulpfile(g:gv_default_gulpfile)
		if a:action ==# 'e'
			echo call(a:funName, l:args)
		else
			execute call(a:funName, l:args)
			execute 'redraw!'
		endif
	else
		echohl Error | echo 'No valid gulpfile in the current directory' | echohl None
	endif
endfunction
function s:CompleteTaskNames(A, L, P) " {{{1
	if s:Gulpfile(g:gv_default_gulpfile)
		return s:GetTaskNames()
	endif
endfunction
" }}}

" Restore default vim options {{{1
let &cpoptions = s:saveCpoptions
unlet s:saveCpoptions
let &fileformat = s:saveFileFormat
" }}}

" vim:ft=vim:fdm=marker:fmr={{{,}}}:
