set spell

if exists("b:current_syntax") && b:current_syntax == "markdown"
	" Inject TCL snippets
	unlet b:current_syntax
	syntax include @Tcl syntax/tcl.vim
	syntax region TclBlock start=+<?=\?+ end=+?>+ contains=@Tcl
	let b:current_syntax = "markdown"

	" Special comment lines
	syntax region specialComment start=/^;/ end=/$/ contains=specialCommenTodo
	syntax keyword specialCommenTodo TODO FIXME XXX NEXT TBD contained
	hi link specialComment Comment
	hi link specialCommenTodo Todo
endif
