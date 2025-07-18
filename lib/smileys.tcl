foreach {name chars} {
	winky		";)"
	square		":["
	winy_nose	";^)"
	smiley		":)"
	smiley_nose	":^)"
} {
	eval "
		proc $name {} {
			emit {<span style=\"font-family: sans-serif;\">}
			emit [list $chars]
			emit {</span>}
		}
	"
}
