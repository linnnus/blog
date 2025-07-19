set spell

if exists("b:current_syntax") && b:current_syntax == "markdown"
	" Inject TCL snippets
	unlet b:current_syntax
	syntax include @Tcl syntax/tcl.vim
	syntax region TclBlock start=+<?=\?+ end=+?>+ contains=@Tcl
	let b:current_syntax = "markdown"

	" Special comment lines
	syntax match Comment /^; .*$/
endif
