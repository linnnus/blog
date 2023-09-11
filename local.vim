augroup InjectTclSnip
	au!
	function InjectTclSnippetSyntax()
		" Most syntax plugins exit early when this is set.
		unlet b:current_syntax
		" Import TCL syntax
		syntax include @Tcl syntax/tcl.vim
		" Add
		syntax region TclSnip start="<?" end="?>" contains=@Tcl
	endfunction
	au Syntax markdown call InjectTclSnippetSyntax()
augroup END
