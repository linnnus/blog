set spell

if exists("b:current_syntax") && b:current_syntax == "markdown"
	unlet b:current_syntax
	syntax include @Tcl syntax/tcl.vim
	syntax region TclBlock start="<?" end="?>" contains=@Tcl
	let b:current_syntax = "markdown"
endif
